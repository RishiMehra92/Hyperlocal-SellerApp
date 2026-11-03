import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:hyper_local_seller/model/language_model/language_model.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/ai_description_generation_sheet.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';
import 'package:hyper_local_seller/service/language_repo.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class ProductDescriptionStep extends StatefulWidget {
  const ProductDescriptionStep({super.key});

  @override
  State<ProductDescriptionStep> createState() => _ProductDescriptionStepState();
}

class _ProductDescriptionStepState extends State<ProductDescriptionStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Language management
  late List<LanguageData> _languages;
  late String _defaultLang;
  late String _selectedLang;

  // Per-language controllers and focus nodes for smooth transitions
  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _shortDescControllers = {};
  final Map<String, FocusNode> _titleFocusNodes = {};
  final Map<String, FocusNode> _shortDescFocusNodes = {};
  final Map<String, FocusNode> _descFocusNodes = {};
  final Map<String, QuillController> _quillControllers = {};

  // Global tags controllers
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocus = FocusNode();
  final List<String> _tags = [];

  bool _isUpdatingFromSelf = false;

  // AI Auto-Translation state
  final AddProductRepo _addProductRepo = AddProductRepo();
  final Set<String> _translatingLocales = {};
  bool _isTranslatingAll = false;

  // Language scroll & bottom dragger state
  late final ScrollController _langScrollController;
  bool _isDraggingDragger = false;

  @override
  void initState() {
    super.initState();
    _initLanguages();

    _langScrollController = ScrollController();
    _langScrollController.addListener(() {
      if (mounted) setState(() {});
    });

    _tabController = TabController(length: _languages.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    final productData = context.read<AddProductBloc>().state.productData;

    if (productData.tags.isNotEmpty) {
      _tags.addAll(productData.tags);
    }

    // Initialize controllers for each language
    for (final lang in _languages) {
      final code = lang.code!;

      // Resolve initial title
      String initialTitle = productData.titleTranslations[code] ?? '';
      if (initialTitle.isEmpty && code == _defaultLang && productData.title != null) {
        initialTitle = productData.title!;
      }

      // Resolve initial short description
      String initialShort = productData.shortDescriptionTranslations[code] ?? '';
      if (initialShort.isEmpty && code == _defaultLang && productData.shortDescription != null) {
        initialShort = productData.shortDescription!;
      }

      // Resolve initial description HTML
      String initialHtml = productData.descriptionTranslations[code] ?? '';
      if (initialHtml.isEmpty && code == _defaultLang && productData.description != null) {
        initialHtml = productData.description!;
      }

      final titleCtrl = TextEditingController(text: initialTitle);
      final shortCtrl = TextEditingController(text: initialShort);
      final quillCtrl = QuillController.basic();

      if (initialHtml.isNotEmpty) {
        try {
          final delta = HtmlToDelta().convert(initialHtml);
          quillCtrl.document = Document.fromDelta(delta);
        } catch (_) {}
      }

      titleCtrl.addListener(_onFieldChanged);
      shortCtrl.addListener(_onFieldChanged);
      quillCtrl.addListener(_onFieldChanged);

      _titleControllers[code] = titleCtrl;
      _shortDescControllers[code] = shortCtrl;
      _quillControllers[code] = quillCtrl;

      _titleFocusNodes[code] = FocusNode();
      _shortDescFocusNodes[code] = FocusNode();
      _descFocusNodes[code] = FocusNode();
    }
  }

  void _initLanguages() {
    final catalogModel = LanguageRepo.getCatalogLanguagesSync();
    final defaultCode = (catalogModel.data?.defaultLanguage?.isNotEmpty == true)
        ? catalogModel.data!.defaultLanguage!
        : (HiveStorage.catalogDefaultLanguage.isNotEmpty
            ? HiveStorage.catalogDefaultLanguage
            : (HiveStorage.languageCode.isNotEmpty ? HiveStorage.languageCode : 'en'));

    _defaultLang = defaultCode;
    _selectedLang = defaultCode;

    final List<LanguageData> list = [];
    if (catalogModel.data?.languages != null && catalogModel.data!.languages!.isNotEmpty) {
      list.addAll(catalogModel.data!.languages!);
    } else {
      list.addAll(
        LanguageRepo.defaultCatalogLanguages.map(
          (l) => LanguageData(
            code: l['code'],
            name: l['name'],
            nativeName: l['native_name'],
            direction: l['direction'],
          ),
        ),
      );
    }

    if (!list.any((l) => l.code == _defaultLang)) {
      list.insert(
        0,
        LanguageData(
          code: _defaultLang,
          name: _defaultLang.toUpperCase(),
          nativeName: _defaultLang,
        ),
      );
    }

    // Sort so default language is first
    list.sort((a, b) {
      if (a.code == _defaultLang) return -1;
      if (b.code == _defaultLang) return 1;
      return 0;
    });

    _languages = list;
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _tabController.animation?.value == _tabController.index) {
      final newCode = _languages[_tabController.index].code!;
      if (_selectedLang != newCode) {
        FocusScope.of(context).unfocus();
        setState(() {
          _selectedLang = newCode;
        });
      }
    }
  }

  void _onFieldChanged() {
    if (_isUpdatingFromSelf) return;
    _updateBloc();
  }

  void _updateBloc() {
    _isUpdatingFromSelf = true;
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;

    final Map<String, String> titles = {};
    final Map<String, String> shortDescs = {};
    final Map<String, String> descs = {};

    for (final l in _languages) {
      final code = l.code!;
      final t = _titleControllers[code]?.text.trim() ?? '';
      final s = _shortDescControllers[code]?.text.trim() ?? '';
      String h = '';

      final q = _quillControllers[code];
      if (q != null && q.document.toPlainText().trim().isNotEmpty) {
        try {
          final deltaOps = q.document.toDelta().toJson();
          final converter = QuillDeltaToHtmlConverter(deltaOps, ConverterOptions());
          h = converter.convert().trim();
        } catch (_) {}
      }

      if (t.isNotEmpty) titles[code] = t;
      if (s.isNotEmpty) shortDescs[code] = s;
      if (h.isNotEmpty) descs[code] = h;
    }

    final defaultTitle = titles[_defaultLang] ?? _titleControllers[_defaultLang]?.text.trim() ?? '';
    final defaultShort = shortDescs[_defaultLang] ?? _shortDescControllers[_defaultLang]?.text.trim() ?? '';
    final defaultDesc = descs[_defaultLang] ?? '';

    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          title: defaultTitle,
          shortDescription: defaultShort,
          description: defaultDesc,
          titleTranslations: titles,
          shortDescriptionTranslations: shortDescs,
          descriptionTranslations: descs,
          tags: _tags,
        ),
      ),
    );

    _isUpdatingFromSelf = false;
  }

  Map<String, dynamic> _normalizeMap(dynamic input) {
    if (input == null) return {};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return input.map((k, v) => MapEntry(k.toString(), v));
    }
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        if (decoded is Map) return _normalizeMap(decoded);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _extractDataPayload(dynamic response) {
    Map<String, dynamic> root = _normalizeMap(response);

    if (root.containsKey('data')) {
      final inner = _normalizeMap(root['data']);
      if (inner.isNotEmpty) {
        if (inner.containsKey('data') && inner['data'] is Map) {
          return _normalizeMap(inner['data']);
        }
        return inner;
      }
    }

    if (root.containsKey('translations') && root['translations'] is Map) {
      return _normalizeMap(root['translations']);
    }

    return root;
  }

  String? _extractLocaleField(Map<String, dynamic> data, String fieldName, String targetLocale) {
    if (data.isEmpty) return null;

    final targetLower = targetLocale.toLowerCase().trim();
    final targetShort = targetLower.split(RegExp(r'[-_]')).first;

    bool localeMatches(String key) {
      final k = key.toLowerCase().trim();
      final kShort = k.split(RegExp(r'[-_]')).first;
      return k == targetLower || kShort == targetShort || k == targetShort || kShort == targetLower;
    }

    bool fieldMatches(String key) {
      final k = key.toLowerCase().trim();
      final f = fieldName.toLowerCase().trim();
      if (k == f) return true;
      if (f == 'short_description' && (k == 'shortdescription' || k == 'short_desc' || k == 'shortdesc')) return true;
      if (f == 'description' && (k == 'desc' || k == 'long_description')) return true;
      return false;
    }

    // 1. Structure A: data[fieldName][locale]
    for (final entry in data.entries) {
      if (fieldMatches(entry.key) && entry.value is Map) {
        final fieldMap = _normalizeMap(entry.value);
        for (final locEntry in fieldMap.entries) {
          if (localeMatches(locEntry.key)) {
            final val = locEntry.value?.toString().trim();
            if (val != null && val.isNotEmpty) return val;
          }
        }
      }
    }

    // 2. Structure B: data[locale][fieldName]
    for (final entry in data.entries) {
      if (localeMatches(entry.key) && entry.value is Map) {
        final locMap = _normalizeMap(entry.value);
        for (final fEntry in locMap.entries) {
          if (fieldMatches(fEntry.key)) {
            final val = fEntry.value?.toString().trim();
            if (val != null && val.isNotEmpty) return val;
          }
        }
      }
    }

    // 3. Structure C: data['translations'] nested
    if (data.containsKey('translations') && data['translations'] is Map) {
      final transMap = _normalizeMap(data['translations']);
      final res = _extractLocaleField(transMap, fieldName, targetLocale);
      if (res != null) return res;
    }

    // 4. Structure D: flat keys like "title[es]" or "title_es"
    for (final entry in data.entries) {
      final k = entry.key.toLowerCase().trim();
      if (k == '${fieldName.toLowerCase()}[$targetLower]' ||
          k == '${fieldName.toLowerCase()}[$targetShort]' ||
          k == '${fieldName.toLowerCase()}_$targetLower' ||
          k == '${fieldName.toLowerCase()}_$targetShort') {
        final val = entry.value?.toString().trim();
        if (val != null && val.isNotEmpty) return val;
      }
    }

    return null;
  }

  Future<void> _translateWithAi({String? targetLang, bool translateAll = false}) async {
    final defTitle = _titleControllers[_defaultLang]?.text.trim() ?? '';
    final defShort = _shortDescControllers[_defaultLang]?.text.trim() ?? '';

    String defHtml = '';
    final q = _quillControllers[_defaultLang];
    if (q != null && q.document.toPlainText().trim().isNotEmpty) {
      try {
        final deltaOps = q.document.toDelta().toJson();
        final converter = QuillDeltaToHtmlConverter(deltaOps, ConverterOptions());
        defHtml = converter.convert().trim();
      } catch (_) {}
    }

    if (defTitle.isEmpty && defShort.isEmpty && defHtml.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: context.tr(
          'defaultLanguageHasNoContent',
          fallback: 'Please enter content in the default language first',
        ),
        isWarning: true,
      );
      return;
    }

    List<String> targets = [];
    if (translateAll) {
      targets = _languages
          .map((l) => l.code!)
          .where((c) => c != _defaultLang)
          .toList();
    } else if (targetLang != null && targetLang != _defaultLang) {
      targets = [targetLang];
    }

    if (targets.isEmpty) return;

    final Map<String, String> fields = {};
    if (defTitle.isNotEmpty) fields['title'] = defTitle;
    if (defShort.isNotEmpty) fields['short_description'] = defShort;
    if (defHtml.isNotEmpty) fields['description'] = defHtml;

    setState(() {
      if (translateAll) {
        _isTranslatingAll = true;
      }
      _translatingLocales.addAll(targets);
    });

    try {
      final response = await _addProductRepo.translateProductFields(
        fields: fields,
        sourceLocale: _defaultLang,
        targetLocales: targets,
      );

      debugPrint('=== AI Translation API Response ===');
      debugPrint('Runtime type: ${response.runtimeType}');
      debugPrint('Raw response: $response');

      final dataPayload = _extractDataPayload(response);
      debugPrint('Extracted Data Payload: $dataPayload');

      bool anyFieldUpdated = false;

      setState(() {
        for (final tLang in targets) {
          final transTitle = _extractLocaleField(dataPayload, 'title', tLang);
          final transShort = _extractLocaleField(dataPayload, 'short_description', tLang);
          final transDesc = _extractLocaleField(dataPayload, 'description', tLang);

          debugPrint('Setting lang [$tLang] => title: "$transTitle", short: "$transShort", desc: "$transDesc"');

          if (transTitle != null && transTitle.isNotEmpty) {
            _titleControllers[tLang]?.text = transTitle;
            anyFieldUpdated = true;
          }
          if (transShort != null && transShort.isNotEmpty) {
            _shortDescControllers[tLang]?.text = transShort;
            anyFieldUpdated = true;
          }
          if (transDesc != null && transDesc.isNotEmpty) {
            try {
              final delta = HtmlToDelta().convert(transDesc);
              _quillControllers[tLang]?.document = Document.fromDelta(delta);
              anyFieldUpdated = true;
            } catch (e) {
              debugPrint('Quill Delta convert error for $tLang: $e');
            }
          }
        }
      });

      _updateBloc();

      // If user was on default language tab and clicked Auto-Translate All,
      // animate to first target language tab so they immediately see the translated fields!
      if (translateAll && targets.isNotEmpty && _selectedLang == _defaultLang) {
        final firstTargetIndex = _languages.indexWhere((l) => l.code == targets.first);
        if (firstTargetIndex != -1) {
          _onLanguageTabTapped(targets.first, firstTargetIndex);
        }
      }

      if (mounted) {
        final successMsg = anyFieldUpdated
            ? (translateAll
                ? context.tr('allLanguagesTranslatedSuccess', fallback: 'All languages auto-translated with AI! ✨')
                : context.tr('languageTranslatedSuccess', fallback: 'Translated with AI successfully! ✨'))
            : context.tr('noTranslationsFound', fallback: 'Translation API called, but no matching translations found in response.');
        showCustomSnackbar(
          context: context,
          message: successMsg,
          isWarning: !anyFieldUpdated,
        );
      }
    } catch (e) {
      debugPrint('AI translation exception: $e');
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (translateAll) {
            _isTranslatingAll = false;
          }
          _translatingLocales.removeAll(targets);
        });
      }
    }
  }


  void _showAiGenerationBottomSheet(BuildContext context) {
    final productData = context.read<AddProductBloc>().state.productData;
    final categoryId = productData.categoryId?.toString();
    final titleText = _titleControllers[_selectedLang]?.text ?? '';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiDescriptionGenerationSheet(
        productTitle: titleText,
        categoryId: categoryId,
        onApply: (shortDesc, desc) {
          setState(() {
            _shortDescControllers[_selectedLang]?.text = shortDesc;
            try {
              final delta = HtmlToDelta().convert(desc);
              _quillControllers[_selectedLang]?.document = Document.fromDelta(delta);
            } catch (_) {}
          });
          _updateBloc();
        },
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _updateBloc();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _updateBloc();
  }

  bool _hasContentForLang(String code) {
    final t = _titleControllers[code]?.text.trim() ?? '';
    final s = _shortDescControllers[code]?.text.trim() ?? '';
    final q = _quillControllers[code];
    final hasQuill = q != null && q.document.toPlainText().trim().isNotEmpty;
    return t.isNotEmpty || s.isNotEmpty || hasQuill;
  }

  String _getLanguageDisplayName(LanguageData lang) {
    if (lang.nativeName != null && lang.nativeName!.isNotEmpty) {
      if (lang.nativeName == lang.name) {
        return lang.name ?? lang.code?.toUpperCase() ?? '';
      }
      return "${lang.name ?? lang.code?.toUpperCase()} (${lang.nativeName})";
    }
    return lang.name ?? lang.code?.toUpperCase() ?? '';
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _langScrollController.dispose();

    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _shortDescControllers.values) {
      c.dispose();
    }
    for (final f in _titleFocusNodes.values) {
      f.dispose();
    }
    for (final f in _shortDescFocusNodes.values) {
      f.dispose();
    }
    for (final f in _descFocusNodes.values) {
      f.dispose();
    }
    for (final q in _quillControllers.values) {
      q.dispose();
    }

    _tagController.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLangData = _languages.firstWhere(
      (l) => l.code == _selectedLang,
      orElse: () => LanguageData(code: _selectedLang, name: _selectedLang.toUpperCase()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfessionalTabBar(),
        const SizedBox(height: 12),

        // Smooth Animated Content Switcher
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(_selectedLang),
            child: _buildLanguageFields(selectedLangData),
          ),
        ),

        const SizedBox(height: 24),
        _buildEditorLabel(context.tr('tags')),
        const SizedBox(height: 8),
        _buildTagsInput(),
        const SizedBox(height: 12),
        _buildTagsList(),
        const SizedBox(height: 20),
      ],
    );
  }

  void _confirmAndAutoTranslateAll() {
    showAppAlertDialog(
      context: context,
      icon: Icons.auto_awesome,
      iconColor: AppColors.primaryColor,
      title: context.tr('autoTranslateAllConfirmTitle', fallback: 'Auto-Translate All Languages?'),
      message: context.tr(
        'autoTranslateAllConfirmMessage',
        fallback: 'This will automatically translate product details from the default language to all other languages using AI. Existing translations may be overwritten.',
      ),
      confirmText: context.tr('translateAll', fallback: 'Translate All ✨'),
      cancelText: context.tr('cancel', fallback: 'Cancel'),
      confirmColor: AppColors.primaryColor,
      onConfirm: () => _translateWithAi(translateAll: true),
    );
  }

  void _onLanguageTabTapped(String code, int index) {
    if (_selectedLang != code) {
      FocusScope.of(context).unfocus();
      setState(() {
        _selectedLang = code;
      });
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
      _scrollToTab(index);
    }
  }

  void _scrollToTab(int index) {
    if (!_langScrollController.hasClients) return;
    final maxScroll = _langScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final targetOffset = (index * 95.0) - (_langScrollController.position.viewportDimension / 3);
    _langScrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildProfessionalTabBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Horizontal scrollable tabs
                SizedBox(
                  height: 38,
                  child: SingleChildScrollView(
                    controller: _langScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_languages.length, (index) {
                        final lang = _languages[index];
                        final code = lang.code ?? '';
                        final isSelected = code == _selectedLang;
                        final isDefault = code == _defaultLang;
                        final hasContent = _hasContentForLang(code);

                        return Padding(
                          padding: EdgeInsets.only(right: index == _languages.length - 1 ? 0 : 4),
                          child: InkWell(
                            onTap: () => _onLanguageTabTapped(code, index),
                            borderRadius: BorderRadius.circular(9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasContent) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Colors.white : Colors.green.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    lang.name?.isNotEmpty == true ? lang.name! : code.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.22)
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        context.tr('default', fallback: 'Default'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // Interactive Bottom Dragger Bar
                _buildLanguageScrollDragger(),
              ],
            ),
          ),
        ),
        if (_languages.length > 1) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: _isTranslatingAll ? null : () => _confirmAndAutoTranslateAll(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTranslatingAll)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome, size: 15, color: AppColors.primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    "${context.tr('autoTranslate', fallback: 'Auto-Translate')} ✨",
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageScrollDragger() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth;
          if (trackWidth <= 0) return const SizedBox.shrink();

          final bool hasClients = _langScrollController.hasClients;
          final double maxScroll = hasClients ? _langScrollController.position.maxScrollExtent : 0.0;
          final double currentScroll = hasClients ? _langScrollController.position.pixels : 0.0;
          final double viewport = hasClients ? _langScrollController.position.viewportDimension : trackWidth;

          final bool isScrollable = maxScroll > 0;
          final double totalContent = viewport + maxScroll;
          final double ratio = totalContent > 0 ? (viewport / totalContent) : 1.0;
          final double thumbWidth = isScrollable
              ? (trackWidth * ratio).clamp(28.0, trackWidth * 0.5)
              : trackWidth * 0.4;

          final double availableTrack = (trackWidth - thumbWidth).clamp(0.0, trackWidth);
          final double progress = (maxScroll > 0)
              ? (currentScroll / maxScroll).clamp(0.0, 1.0)
              : 0.0;
          final double thumbLeft = progress * availableTrack;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: (_) {
              setState(() => _isDraggingDragger = true);
            },
            onHorizontalDragStart: (_) {
              setState(() => _isDraggingDragger = true);
            },
            onHorizontalDragUpdate: (details) {
              if (maxScroll <= 0 || availableTrack <= 0) return;
              final targetLeft = (details.localPosition.dx - (thumbWidth / 2)).clamp(0.0, availableTrack);
              final newProg = targetLeft / availableTrack;
              final targetOffset = newProg * maxScroll;
              _langScrollController.jumpTo(targetOffset.clamp(0.0, maxScroll));
            },
            onHorizontalDragEnd: (_) {
              setState(() => _isDraggingDragger = false);
            },
            onHorizontalDragCancel: () {
              setState(() => _isDraggingDragger = false);
            },
            onTapDown: (details) {
              if (maxScroll <= 0 || availableTrack <= 0) return;
              final targetLeft = (details.localPosition.dx - (thumbWidth / 2)).clamp(0.0, availableTrack);
              final newProg = targetLeft / availableTrack;
              final targetOffset = newProg * maxScroll;
              _langScrollController.animateTo(
                targetOffset.clamp(0.0, maxScroll),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutQuad,
              height: _isDraggingDragger ? 6.0 : 3.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: thumbLeft,
                    top: 0,
                    bottom: 0,
                    width: thumbWidth,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        color: _isDraggingDragger
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _isDraggingDragger
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryColor.withOpacity(0.4),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageFields(LanguageData langData) {
    final code = langData.code!;
    final isDefault = code == _defaultLang;
    final isRtl = langData.direction?.toLowerCase() == 'rtl';

    final titleCtrl = _titleControllers[code]!;
    final shortCtrl = _shortDescControllers[code]!;
    final quillCtrl = _quillControllers[code]!;

    final titleFocus = _titleFocusNodes[code]!;
    final shortFocus = _shortDescFocusNodes[code]!;
    final descFocus = _descFocusNodes[code]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDefault) _buildTranslationHelperBanner(langData),

        CustomTextField(
          sideTitleWidget: ValueListenableBuilder<TextEditingValue>(
            valueListenable: titleCtrl,
            builder: (context, value, _) {
              final bool isTitleEmpty = value.text.trim().isEmpty;
              return InkWell(
                onTap: isTitleEmpty
                    ? () => showCustomSnackbar(
                        context: context,
                        message: context.tr(
                          'titleIsRequiredToSeeAiGeneratedDescription',
                          fallback: 'Title is required to generate AI description',
                        ),
                        isWarning: true,
                      )
                    : () => _showAiGenerationBottomSheet(context),
                child: Text(
                  "${context.tr('generateWithAi', fallback: 'Generate with AI')} ✨",
                  style: TextStyle(
                    color: isTitleEmpty ? Colors.grey : AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          label: "${context.tr('title')}${!isDefault ? ' (${code.toUpperCase()})' : ''}",
          isRequired: isDefault,
          hint: context.tr('enterProductTitle'),
          focusNode: titleFocus,
          controller: titleCtrl,
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: "${context.tr('shortDescription')}${!isDefault ? ' (${code.toUpperCase()})' : ''}",
          isRequired: isDefault,
          hint: context.tr('enterShortDescription'),
          maxLines: 2,
          focusNode: shortFocus,
          controller: shortCtrl,
        ),
        const SizedBox(height: 20),

        _buildEditorLabel(
          "${context.tr('productDescription')}${!isDefault ? ' (${code.toUpperCase()})' : ''} ",
          isRequired: isDefault,
        ),
        const SizedBox(height: 8),
        _buildEditor(quillCtrl: quillCtrl, focusNode: descFocus, isRtl: isRtl),
      ],
    );
  }

  Widget _buildTranslationHelperBanner(LanguageData currentLang) {
    final code = currentLang.code ?? '';
    final bool isThisTranslating = _translatingLocales.contains(code);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${context.tr('translatingTo', fallback: 'Translating to')}: ${_getLanguageDisplayName(currentLang)}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: isThisTranslating ? null : () => _translateWithAi(targetLang: code),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isThisTranslating) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ] else ...[
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    "${context.tr('translateWithAi', fallback: 'Translate with AI')} ✨",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildEditor({
    required QuillController quillCtrl,
    required FocusNode focusNode,
    bool isRtl = false,
  }) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4C4C4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: quillCtrl,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showInlineCode: false,
              showSubscript: false,
              showSuperscript: false,
              toolbarSectionSpacing: 4,
              multiRowsDisplay: false,
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFC4C4C4))),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              buttonOptions: QuillSimpleToolbarButtonOptions(
                base: QuillToolbarBaseButtonOptions(
                  iconTheme: QuillIconTheme(
                    iconButtonSelectedData: IconButtonData(color: AppColors.primaryColor),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: QuillEditor.basic(
                controller: quillCtrl,
                focusNode: focusNode,
                config: const QuillEditorConfig(
                  showCursor: true,
                  expands: true,
                  padding: EdgeInsets.all(12),
                  textSelectionThemeData: TextSelectionThemeData(
                    cursorColor: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tagController,
              focusNode: _tagFocus,
              cursorColor: AppColors.primaryColor,
              decoration: InputDecoration(
                hintText: context.tr('enterTags'),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _addTag(),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _tagController,
            builder: (context, value, child) {
              final bool hasText = value.text.trim().isNotEmpty;
              return IconButton(
                onPressed: hasText ? _addTag : null,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasText ? AppColors.primaryColor : Colors.grey.shade300,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 20),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags
          .map(
            (tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12, color: Colors.black)),
              onDeleted: () => _removeTag(tag),
              deleteIconColor: Colors.red,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          )
          .toList(),
    );
  }
}
