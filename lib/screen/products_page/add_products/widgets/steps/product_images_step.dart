// ignore_for_file: use_build_context_synchronously

import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';

class ProductImagesStep extends StatefulWidget {
  const ProductImagesStep({super.key});

  @override
  State<ProductImagesStep> createState() => _ProductImagesStepState();
}

class _ProductImagesStepState extends State<ProductImagesStep> {
  final TextEditingController _videoLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final productData = context.read<AddProductBloc>().state.productData;
    _videoLinkController.text = productData.videoLink ?? "";
  }

  @override
  void dispose() {
    _videoLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final imagePath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
    );
    if (imagePath != null) {
      final bloc = context.read<AddProductBloc>();
      bloc.add(
        UpdateProductData(bloc.state.productData.copyWith(mainImage: imagePath)),
      );
    }
  }

  Future<void> _pickAdditionalImage() async {
    final imagePath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
    );
    if (imagePath != null) {
      final bloc = context.read<AddProductBloc>();
      final newImages = List<String>.from(bloc.state.productData.otherImages)..add(imagePath);
      bloc.add(
        UpdateProductData(bloc.state.productData.copyWith(otherImages: newImages)),
      );
    }
  }

  void _removeMainImage() {
    final bloc = context.read<AddProductBloc>();
    bloc.add(
      UpdateProductData(bloc.state.productData.copyWith(clearMainImage: true)),
    );
  }

  void _removeAdditionalImage(int index) {
    final bloc = context.read<AddProductBloc>();
    final newImages = List<String>.from(bloc.state.productData.otherImages)..removeAt(index);
    bloc.add(
      UpdateProductData(bloc.state.productData.copyWith(otherImages: newImages)),
    );
  }

  Future<void> _pickVideo() async {
    final videoPath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.video,
    );
    if (videoPath != null) {
      final bloc = context.read<AddProductBloc>();
      bloc.add(
        UpdateProductData(
          bloc.state.productData.copyWith(productVideo: videoPath),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final productData = context.watch<AddProductBloc>().state.productData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.tr('mainImage'), isRequired: true),
        CustomUploadArea(
          hint: context.tr('uploadImage'),
          fileName: productData.mainImage,
          onTap: _pickMainImage,
          onRemove: _removeMainImage,
        ),
        const SizedBox(height: 20),

        _buildLabel(context.tr('additionalImages')),
        ...productData.otherImages.asMap().entries.map((entry) {
          int index = entry.key;
          String path = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CustomUploadArea(
              hint:
                  "${context.tr('additionalImage')} ${index + 1}",
              fileName: path,
              onRemove: () => _removeAdditionalImage(index),
              height: 100,
            ),
          );
        }),
        CustomUploadArea(
          hint: context.tr('addAdditionalImages'),
          onTap: _pickAdditionalImage,
          height: 100,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('youCanSelectMultipleImagesByClickingAddButton'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: context.tr('imageFit'),
          hint: context.tr('selectImageFit'),
          value: productData.imageFit,
          items: [
            CustomDropdownItem(
              label: context.tr('cover'),
              value: "cover",
            ),
            CustomDropdownItem(
              label: context.tr('contain'),
              value: "contain",
            ),
          ],
          onChanged: (val) {
            final bloc = context.read<AddProductBloc>();
            bloc.add(
              UpdateProductData(bloc.state.productData.copyWith(imageFit: val)),
            );
          },
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: context.tr('videoType'),
          hint: context.tr('selectVideoType'),
          value: productData.videoType,
          sideTitleWidget: productData.videoType != null && productData.videoType!.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    final bloc = context.read<AddProductBloc>();
                    bloc.add(
                      UpdateProductData(bloc.state.productData.copyWith(clearVideoType: true, clearVideoLink: true, clearProductVideo: true)),
                    );
                    _videoLinkController.clear();
                  },
                  child: Text(
                    context.tr('remove'),
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          items: [
            CustomDropdownItem(
              label: context.tr('youtube'),
              value: "youtube",
            ),
            CustomDropdownItem(
              label: context.tr('selfHosted'),
              value: "self_hosted",
            ),
          ],
          onChanged: (val) {
            final bloc = context.read<AddProductBloc>();
            bloc.add(
              UpdateProductData(bloc.state.productData.copyWith(videoType: val)),
            );
          },
        ),
        const SizedBox(height: 10),

        // if (_videoType == "youtube")
        //   CustomTextField(
        //     label: context.tr('videoLink'),
        //     hint: context.tr('enterYoutubeUrl'),
        //     controller: _videoLinkController,
        //     onChanged: (v) {
        //       final bloc = context.read<AddProductBloc>();
        //       bloc.add(
        //         UpdateProductData(
        //           bloc.state.productData.copyWith(videoLink: v),
        //         ),
        //       );
        //     },
        //   )
        // else if (_videoType == "self_hosted" &&
        //     productData.productVideo != null &&
        //     productData.productVideo!.startsWith('https')) ...[
        //   Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 12),
        //     child: Text(
        //       "Current video: ${productData.productVideo!.split('/').last}",
        //       style: TextStyle(color: Theme.of(context).colorScheme.primary),
        //     ),
        //   ),
        //
        //   CustomUploadArea(
        //     hint: context.tr('uploadVideo'),
        //     fileName: productData.productVideo,
        //     onTap: _pickVideo,
        //     onRemove: () {
        //       final bloc = context.read<AddProductBloc>();
        //       bloc.add(
        //         UpdateProductData(
        //           bloc.state.productData.copyWith(productVideo: null),
        //         ),
        //       );
        //       setState(() {});
        //     },
        //   ),
        //   const SizedBox(height: 20),
        // ],
        if (productData.videoType == "youtube")
          CustomTextField(
            label: context.tr('videoLink'),
            hint: context.tr('enterYoutubeUrl'),
            isRequired: true,
            controller: _videoLinkController,
            onChanged: (v) {
              final bloc = context.read<AddProductBloc>();
              bloc.add(
                UpdateProductData(
                  bloc.state.productData.copyWith(videoLink: v),
                ),
              );
            },
          )
        else if (productData.videoType == "self_hosted") ...[
          // ── Case 1: Existing remote video (edit mode) ──
          if (productData.videoLink != null &&
              productData.videoLink!.startsWith('https') &&
              (productData.productVideo == null ||
                  !File(productData.productVideo!).existsSync())) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('currentVideo'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      ExternalLink.showVideo(
                        productData.videoLink!,
                        context: context,
                      );
                    },
                    child: Text(
                      productData.videoLink!.split('/').last,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  Text(
                    context.tr('remoteFileWillBeKeptUnlessReplaced'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            CustomUploadArea(
              hint: context.tr('replaceVideoOptional'),
              fileName: null, // don't show local filename here
              onTap: _pickVideo,
              onRemove: () {
                final bloc = context.read<AddProductBloc>();
                bloc.add(
                  UpdateProductData(
                    bloc.state.productData.copyWith(
                      clearProductVideo: true,
                      clearVideoLink: true,
                    ),
                  ),
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ]
          // ── Case 2: New picked local video or no video yet ──
          else
            CustomUploadArea(
              hint: context.tr('uploadVideo'),
              fileName: productData.productVideo,
              onTap: _pickVideo,
              onRemove: () {
                final bloc = context.read<AddProductBloc>();
                bloc.add(
                  UpdateProductData(
                    bloc.state.productData.copyWith(clearProductVideo: true),
                  ),
                );
                setState(() {});
              },
            ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
