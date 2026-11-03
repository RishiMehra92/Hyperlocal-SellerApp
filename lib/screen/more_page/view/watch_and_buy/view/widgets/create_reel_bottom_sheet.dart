import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import 'watch_and_buy_product_selection_field.dart';
import '../../bloc/watch_and_buy_bloc.dart';
import '../../bloc/watch_and_buy_event.dart';
import '../../bloc/watch_and_buy_state.dart';
import '../../model/watch_and_buy_reel_model.dart';

void showCreateReelBottomSheet(
  BuildContext context, {
  WatchAndBuyReelModel? existingReel,
}) {
  final bloc = context.read<WatchAndBuyBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: CreateReelBottomSheet(existingReel: existingReel),
    ),
  );
}

class CreateReelBottomSheet extends StatefulWidget {
  final WatchAndBuyReelModel? existingReel;
  const CreateReelBottomSheet({super.key, this.existingReel});

  @override
  State<CreateReelBottomSheet> createState() => _CreateReelBottomSheetState();
}

class _CreateReelBottomSheetState extends State<CreateReelBottomSheet> {
  final TextEditingController _captionController = TextEditingController();
  String? _videoPath;
  String? _coverPath;
  List<ProductLookup> _selectedProducts = [];
  ProductLookup? _primaryProduct;

  @override
  void initState() {
    super.initState();
    if (widget.existingReel != null) {
      final reel = widget.existingReel!;
      _captionController.text = reel.caption ?? '';
      _selectedProducts = reel.products.map((p) {
        final isVariant = p.productVariantId != null;
        return ProductLookup(
          id: isVariant ? p.productVariantId! : (p.productId ?? 0),
          title: p.name ?? '',
          type: isVariant ? 'variant' : 'simple',
          isVariant: isVariant,
          variantsCount: 0,
          imageUrl: p.imageUrl,
        );
      }).toList();

      try {
        final primary = reel.products.firstWhere((p) => p.isPrimary);
        final primaryId = primary.productVariantId != null
            ? primary.productVariantId!
            : primary.productId;
        _primaryProduct = _selectedProducts.firstWhere(
          (p) => p.id == primaryId,
        );
      } catch (e) {
        if (_selectedProducts.isNotEmpty) {
          _primaryProduct = _selectedProducts.first;
        }
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final maxUploadMb = HiveStorage.watchAndBuyMaxUploadMb > 0
        ? HiveStorage.watchAndBuyMaxUploadMb
        : 50;
    final maxDuration = HiveStorage.watchAndBuyMaxDurationSeconds > 0
        ? HiveStorage.watchAndBuyMaxDurationSeconds
        : 60;

    final path = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.video,
      maxSizeMb: maxUploadMb.toDouble(),
      maxVideoDuration: Duration(seconds: maxDuration),
    );

    if (path != null) {
      setState(() {
        _videoPath = path;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final path = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
      maxSizeMb: 10.0,
    );

    if (path != null) {
      setState(() {
        _coverPath = path;
      });
    }
  }

  void _ensurePrimaryProduct() {
    if (_selectedProducts.isEmpty) {
      _primaryProduct = null;
    } else if (_primaryProduct == null ||
        !_selectedProducts.contains(_primaryProduct)) {
      _primaryProduct = _selectedProducts.first;
    }
  }

  void _submit() {
    final l10n = context;
    final isEdit = widget.existingReel != null;

    if (!isEdit && _videoPath == null) {
      showCustomSnackbar(
        context: context,
        message: l10n?.tr('videoRequired') ?? 'Video is required',
        isError: true,
        showAtTop: true,
      );
      return;
    }

    if (_selectedProducts.isEmpty) {
      showCustomSnackbar(
        context: context,
        message:
            l10n?.tr('pleaseSelectAtLeastOneProduct') ??
            'Please select at least 1 product',
        isError: true,
        showAtTop: true,
      );
      return;
    }

    _primaryProduct ??= _selectedProducts.first;

    if (isEdit) {
      context.read<WatchAndBuyBloc>().add(
        UpdateWatchAndBuyReelEvent(
          id: widget.existingReel!.id,
          video: _videoPath != null ? File(_videoPath!) : null,
          cover: _coverPath != null ? File(_coverPath!) : null,
          caption: _captionController.text,
          attachmentIds: _selectedProducts.map((e) => e.id).toList(),
          primaryAttachmentId: _primaryProduct!.id,
        ),
      );
    } else {
      context.read<WatchAndBuyBloc>().add(
        CreateWatchAndBuyReelEvent(
          video: File(_videoPath!),
          cover: _coverPath != null ? File(_coverPath!) : null,
          caption: _captionController.text,
          attachmentIds: _selectedProducts.map((e) => e.id).toList(),
          primaryAttachmentId: _primaryProduct!.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context;
    final isEdit = widget.existingReel != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit
                        ? (l10n?.tr('edit') ?? 'Edit Reel')
                        : (l10n?.tr('createReel') ?? 'Create Reel'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: (l10n?.tr('videoLabel') ?? 'Video')
                                .replaceAll('*', '')
                                .trim(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickVideo,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _videoPath != null ||
                                        widget.existingReel?.videoUrl != null
                                    ? AppColors.primaryColor
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.grey.shade300),
                              ),
                            ),
                            child:
                                _videoPath != null ||
                                    widget.existingReel?.videoUrl != null
                                ? Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: AppColors.primaryColor,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n?.tr('videoSelected') ??
                                                  'Video Selected',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _videoPath = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.videocam_outlined,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n?.tr('uploadVideo') ?? 'Upload Video',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.tr('coverImageLabel') ?? 'Cover Image',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickCoverImage,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _coverPath != null ||
                                        widget.existingReel?.coverUrl != null
                                    ? AppColors.primaryColor
                                    : (isDark
                                          ? Colors.white24
                                          : Colors.grey.shade300),
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (_coverPath != null ||
                                    widget.existingReel?.coverUrl != null)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _coverPath != null
                                          ? Image.file(
                                              File(_coverPath!),
                                              fit: BoxFit.cover,
                                            )
                                          : (widget.existingReel!.coverUrl !=
                                                    null
                                                ? Image.network(
                                                    widget
                                                        .existingReel!
                                                        .coverUrl!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const SizedBox.shrink()),
                                    ),
                                  ),
                                if (_coverPath != null ||
                                    widget.existingReel?.coverUrl != null)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _coverPath = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_coverPath == null &&
                                    widget.existingReel?.coverUrl == null)
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n?.tr('uploadImage') ?? 'Upload Image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: l10n?.tr('captionLabel') ?? 'Caption',
                hint: l10n?.tr('captionHint') ?? 'Write a caption...',
                controller: _captionController,
                isRequired: false,
                maxLines: 3,
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              WatchAndBuyProductSelectionField(
                isRequired: true,
                selectedProducts: _selectedProducts,
                maxProducts: HiveStorage.watchAndBuyMaxProductsPerReel > 0
                    ? HiveStorage.watchAndBuyMaxProductsPerReel
                    : 10,
                preloadEligibleProducts: !isEdit,
                onChanged: (products) {
                  setState(() {
                    _selectedProducts = products;
                    _ensurePrimaryProduct();
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_selectedProducts.isNotEmpty) ...[
                RichText(
                  text: TextSpan(
                    text: (l10n?.tr('primaryProductLabel') ?? 'Primary Product')
                        .replaceAll('*', '')
                        .trim(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedProducts.asMap().entries.map((entry) {
                    final p = entry.value;
                    final isSelected = _primaryProduct == p;
                    return ChoiceChip(
                      label: Text(
                        p.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryColor,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryColor
                              : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _primaryProduct = p;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 8),

              BlocConsumer<WatchAndBuyBloc, WatchAndBuyState>(
                listenWhen: (previous, current) =>
                    previous.createReelStatus != current.createReelStatus ||
                    previous.updateReelStatus != current.updateReelStatus,
                listener: (context, state) {
                  if (state.createReelStatus == ApiStatus.success) {
                    Navigator.pop(context);
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.createReelMessage ??
                          'Reel created successfully',
                    );
                  } else if (state.createReelStatus == ApiStatus.failure) {
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.createReelMessage ?? 'Failed to create reel',
                      isError: true,
                      showAtTop: true,
                    );
                  }

                  if (state.updateReelStatus == ApiStatus.success) {
                    Navigator.pop(context);
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.updateReelMessage ??
                          'Reel updated successfully',
                    );
                  } else if (state.updateReelStatus == ApiStatus.failure) {
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.updateReelMessage ?? 'Failed to update reel',
                      isError: true,
                      showAtTop: true,
                    );
                  }
                },
                builder: (context, state) {
                  final l10n = context;
                  final isEdit = widget.existingReel != null;
                  final isLoading =
                      state.createReelStatus == ApiStatus.loading ||
                      state.updateReelStatus == ApiStatus.loading;
                  return PrimaryButton(
                    text: isEdit
                        ? (l10n?.tr('save') ?? 'Save Changes')
                        : (l10n?.tr('createReel') ?? 'Create Reel'),
                    isLoading: isLoading,
                    onPressed:
                        _videoPath == null &&
                                widget.existingReel?.videoUrl == null ||
                            isLoading
                        ? null
                        : _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
