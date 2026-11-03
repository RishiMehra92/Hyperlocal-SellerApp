import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/api_routes.dart';
import '../config/hive_storage.dart';
import '../l10n/default_en_labels.dart';
import '../model/language_model/language_list_model.dart';
import '../model/language_model/language_model.dart';
import 'api_base_helper.dart';

class LanguageRepo {
  static const String _boxName = 'LanguageCacheBox';
  static const String _languagesCacheKey = 'languages_list';
  static const String _labelsCachePrefix = 'labels_';

  static const List<Map<String, String>> defaultSupportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'direction': 'ltr'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी', 'direction': 'ltr'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'direction': 'rtl'},
  ];

  static List<Locale> get supportedLocales {
    final cached = getCachedLanguagesSync();
    if (cached != null && cached.data?.languages != null && cached.data!.languages!.isNotEmpty) {
      return cached.data!.languages!
          .where((l) => l.code != null && l.code!.isNotEmpty)
          .map((l) => Locale(l.code!))
          .toList();
    }
    return defaultSupportedLanguages.map((l) => Locale(l['code']!)).toList();
  }

  /// Languages available for product catalog translations (from Settings API catalogLanguages)
  static const List<Map<String, String>> defaultCatalogLanguages = [
    {'code': 'en', 'name': 'English', 'native_name': 'English', 'direction': 'ltr'},
    {'code': 'es', 'name': 'Spanish', 'native_name': 'Español', 'direction': 'ltr'},
    {'code': 'fr', 'name': 'French', 'native_name': 'Français', 'direction': 'ltr'},
    {'code': 'de', 'name': 'German', 'native_name': 'Deutsch', 'direction': 'ltr'},
    {'code': 'zh', 'name': 'Chinese', 'native_name': '中文', 'direction': 'ltr'},
    {'code': 'hi', 'name': 'Hindi', 'native_name': 'हिन्दी', 'direction': 'ltr'},
    {'code': 'ar', 'name': 'Arabic', 'native_name': 'العربية', 'direction': 'rtl'},
    {'code': 'gu', 'name': 'Gujarati', 'native_name': 'ગુજરાતી', 'direction': 'ltr'},
    {'code': 'te', 'name': 'Telugu', 'native_name': 'తెలుగు', 'direction': 'ltr'},
  ];

  /// Get catalog languages synchronously from Settings API cache (Hive) with fallback to defaultCatalogLanguages
  static LanguageModel getCatalogLanguagesSync() {
    final raw = HiveStorage.catalogLanguages;
    if (raw != null) {
      return LanguageModel(
        success: true,
        message: 'Catalog Languages',
        data: Languages.fromJson(raw),
      );
    }
    return LanguageModel(
      success: true,
      message: 'Default Catalog Languages',
      data: Languages(
        defaultLanguage: 'en',
        languages: defaultCatalogLanguages
            .map((e) => LanguageData(
                  code: e['code'],
                  name: e['name'],
                  nativeName: e['native_name'],
                  direction: e['direction'],
                ))
            .toList(),
      ),
    );
  }

  Future<LanguageModel> getCatalogLanguages() async {
    return getCatalogLanguagesSync();
  }

  /// Synchronous in-memory active labels for immediate access (0ms fallback)
  static Map<String, dynamic> activeLabels = {};
  static String activeLocale = 'en';

  static bool get isBoxOpen => Hive.isBoxOpen(_boxName);
  static Box get _box => Hive.box(_boxName);

  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  Future<Box> _getBox() async {
    if (isBoxOpen) {
      return _box;
    }
    return await Hive.openBox(_boxName);
  }

  /// Initialize cache box and pre-load active labels into memory synchronously
  static Future<void> initCache() async {
    try {
      if (!isBoxOpen) {
        await Hive.openBox(_boxName);
      }
      loadActiveLabelsSync(HiveStorage.languageCode);
    } catch (e) {
      debugPrint('Failed to initialize LanguageRepo cache: $e');
    }
  }

  /// Load active labels into in-memory storage synchronously from open Hive box
  static void loadActiveLabelsSync(String locale) {
    activeLocale = locale;
    final cached = getCachedLanguageLabelsSync(locale);
    if (cached != null &&
        cached.data != null &&
        cached.data!.labels != null &&
        cached.data!.labels!.isNotEmpty) {
      activeLabels = Map<String, dynamic>.from(cached.data!.labels!);
    } else {
      activeLabels = Map<String, dynamic>.from(defaultEnglishLabels);
    }
  }

  static LanguageModel? getCachedLanguagesSync() {
    try {
      if (isBoxOpen) {
        final raw = _box.get(_languagesCacheKey);
        if (raw != null) {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              return LanguageModel.fromJson(decoded);
            }
          } else if (raw is Map) {
            return LanguageModel.fromJson(raw);
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading cached languages sync: $e');
    }
    return null;
  }

  Future<LanguageModel?> getCachedLanguages() async {
    final syncModel = getCachedLanguagesSync();
    if (syncModel != null) return syncModel;
    try {
      final box = await _getBox();
      final raw = box.get(_languagesCacheKey);
      if (raw != null) {
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return LanguageModel.fromJson(decoded);
          }
        } else if (raw is Map) {
          return LanguageModel.fromJson(raw);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedLanguages(Map<String, dynamic> data) async {
    try {
      final box = await _getBox();
      await box.put(_languagesCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  static LanguageLabelsModel? getCachedLanguageLabelsSync(String locale) {
    try {
      if (isBoxOpen) {
        final raw = _box.get('$_labelsCachePrefix$locale');
        if (raw != null) {
          if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              return LanguageLabelsModel.fromJson(decoded);
            }
          } else if (raw is Map) {
            return LanguageLabelsModel.fromJson(raw);
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading cached language labels sync: $e');
    }
    return null;
  }

  Future<LanguageLabelsModel?> getCachedLanguageLabels(String locale) async {
    final syncModel = getCachedLanguageLabelsSync(locale);
    if (syncModel != null) return syncModel;
    try {
      final box = await _getBox();
      final raw = box.get('$_labelsCachePrefix$locale');
      if (raw != null) {
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return LanguageLabelsModel.fromJson(decoded);
          }
        } else if (raw is Map) {
          return LanguageLabelsModel.fromJson(raw);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedLanguageLabels(
      String locale, Map<String, dynamic> data) async {
    try {
      final box = await _getBox();
      await box.put('$_labelsCachePrefix$locale', jsonEncode(data));
      if (locale == activeLocale || locale == HiveStorage.languageCode) {
        if (data['data'] != null && data['data']['labels'] is Map) {
          final labelsMap = data['data']['labels'] as Map;
          activeLabels =
              labelsMap.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {}
  }

  Future<LanguageModel> fetchLanguages() async {
    try {
      final response = await _apiHelper.get(
        ApiRoutes.languagesApi,
        queryParameters: {'surface': 'seller_app'},
      );

      if (response is Map && response['data'] != null) {
        unawaited(saveCachedLanguages(Map<String, dynamic>.from(response)));
        return LanguageModel.fromJson(response);
      } else {
        return LanguageModel();
      }
    } catch (e) {
      debugPrint('fetchLanguages error: $e');
      return LanguageModel();
    }
  }

  Future<LanguageLabelsModel> fetchLanguageLabels(String locale) async {
    try {
      final response = await _apiHelper.get(
        ApiRoutes.languageLabelsApi,
        queryParameters: {
          'surface': 'seller_app',
          'locale': locale,
        },
      );

      if (response is Map && response['data'] != null) {
        unawaited(saveCachedLanguageLabels(locale, Map<String, dynamic>.from(response)));
        return LanguageLabelsModel.fromJson(response);
      } else {
        return LanguageLabelsModel(success: false);
      }
    } catch (e) {
      debugPrint('fetchLanguageLabels error: $e');
      return LanguageLabelsModel(success: false);
    }
  }
}
