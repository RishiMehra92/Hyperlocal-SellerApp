import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:developer';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/add_product_header.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/add_product_process_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_selection_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_info_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/policies_features_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_variation_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_images_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_description_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/pricing_taxes_step.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';

class AddProductPage extends StatefulWidget {
  final bool isEdit;
  const AddProductPage({super.key, required this.isEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  int _currentStep = 1;
  final int _totalSteps = 7;
  bool _isLoadingShowing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AttributesBloc>().add(LoadAttributesInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onStepChanged(int targetStep) {
    if (targetStep == _currentStep) return;

    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    // Allow going back anytime
    if (targetStep < _currentStep) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep = targetStep);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      return;
    }

    // Going forward → only allow if current step is valid
    final (bool currentOk, String? error) = _validateStep(_currentStep, data);

    if (!currentOk) {
      showCustomSnackbar(
        context: context,
        message: error ?? context.tr('pleaseCompleteCurrentStep'),
        isError: true,
      );
      return;
    }

    // Optional: also check all previous steps (more strict)
    for (int i = 1; i < targetStep; i++) {
      if (!_isStepCompleted(i, data)) {
        showCustomSnackbar(
          context: context,
          message: context.tr('stepMustBeCompletedBeforeJumping', positionalArgs: [i]),
          isError: true,
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _currentStep = targetStep);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  String _getStepTitle(BuildContext context, int step) {
    switch (step) {
      case 1:
        return context.tr('selectCategory');
      case 2:
        return context.tr('productsDescription');
      case 3:
        return context.tr('productInformation');
      case 4:
        return context.tr('productVariation');
      case 5:
        return context.tr('productImages');
      case 6:
        return context.tr('policiesAndFeatures');
      case 7:
        return context.tr('pricingAndTaxes');
      default:
        return "";
    }
  }

  void _onNextStep() {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    final (bool ok, String? error) = _validateStep(_currentStep, data);

    if (ok) {
      if (_currentStep < _totalSteps) {
        _onStepChanged(_currentStep + 1);
      } else {
        _onAddProductPressed();
      }
    } else {
      showCustomSnackbar(
        context: context,
        message: error ?? context.tr('pleaseCompleteallRequiredFieldsInPreviousSteps'),
        isError: true,
      );
    }
  }

  (bool, String?) _validateStep(int step, ProductData data) {
    switch (step) {
      case 1:
        if (data.categoryId == null) {
          return (false, context.tr('selectAtLeastOneCategory'));
        }
        return (true, null);
      case 2:
        final defaultLang = HiveStorage.catalogDefaultLanguage.isNotEmpty
            ? HiveStorage.catalogDefaultLanguage
            : (HiveStorage.languageCode.isNotEmpty ? HiveStorage.languageCode : 'en');
        final title = (data.titleTranslations[defaultLang]?.trim().isNotEmpty == true)
            ? data.titleTranslations[defaultLang]!
            : (data.titleTranslations.values.any((t) => t.trim().isNotEmpty)
                ? data.titleTranslations.values.firstWhere((t) => t.trim().isNotEmpty)
                : data.title);
        final shortDesc = (data.shortDescriptionTranslations[defaultLang]?.trim().isNotEmpty == true)
            ? data.shortDescriptionTranslations[defaultLang]!
            : (data.shortDescriptionTranslations.values.any((t) => t.trim().isNotEmpty)
                ? data.shortDescriptionTranslations.values.firstWhere((t) => t.trim().isNotEmpty)
                : data.shortDescription);
        final desc = (data.descriptionTranslations[defaultLang]?.trim().isNotEmpty == true)
            ? data.descriptionTranslations[defaultLang]!
            : (data.descriptionTranslations.values.any((t) => t.trim().isNotEmpty)
                ? data.descriptionTranslations.values.firstWhere((t) => t.trim().isNotEmpty)
                : data.description);

        if (title == null || title.trim().isEmpty) {
          return (false, context.tr('productTitleRequired'));
        }
        if (shortDesc == null || shortDesc.trim().isEmpty) {
          return (false, context.tr('shortDescriptionCompulsory'));
        }
        if (desc == null || _isHtmlEmpty(desc)) {
          return (false, context.tr('fullDescriptionCompulsory'));
        }
        return (true, null);

      case 3:
        if (data.prepTime < 0) {
          return (false, context.tr('basePrepTimeRequired'));
        }
        return (true, null);

      case 4:
        if (data.type == 'simple') {
          if (data.barcode == null || data.barcode!.trim().isEmpty) {
            return (false, context.tr('barcodeRequired'));
          }
          if (data.variants.isNotEmpty) {
            final v = data.variants.first;
            if (v.weight == null || v.weight!.trim().isEmpty) {
              return (false, context.tr('weightRequired'));
            }
            if (v.height == null || v.height!.trim().isEmpty) {
              return (false, context.tr('heightRequired'));
            }
            if (v.breadth == null || v.breadth!.trim().isEmpty) {
              return (false, context.tr('breadthRequired'));
            }
            if (v.length == null || v.length!.trim().isEmpty) {
              return (false, context.tr('lengthRequired'));
            }
          } else {
            // If variants is empty for a simple product, we still need dimensions.
            // However, in our current flow, simple products should have the dimension info
            // either in the first variant or we should rely on the main fields if they existed.
            // Since we sync dimensions to the first variant in ProductVariationStep,
            // an empty variants list here is an edge case that should be handled.
            return (false, context.tr('dimensionsRequired'));
          }
        } else {
          if (data.variants.isEmpty) {
            return (false, context.tr('addAtLeastOneVariant'));
          }
          bool hasDefault = false;
          for (var v in data.variants) {
            if (v.isDefault) hasDefault = true;
            final defaultLang = HiveStorage.catalogDefaultLanguage.isNotEmpty
                ? HiveStorage.catalogDefaultLanguage
                : (HiveStorage.languageCode.isNotEmpty ? HiveStorage.languageCode : 'en');
            final name = (v.titleTranslations[defaultLang]?.trim().isNotEmpty == true)
                ? v.titleTranslations[defaultLang]!
                : (v.titleTranslations.values.any((t) => t.trim().isNotEmpty)
                    ? v.titleTranslations.values.firstWhere((t) => t.trim().isNotEmpty)
                    : ((v.name != null && v.name!.trim().isNotEmpty) ? v.name! : v.title));
            if (name.trim().isEmpty) {
              return (false, context.tr('allVariantsMustHaveName'));
            }
            if (v.barcode == null || v.barcode!.trim().isEmpty) {
              return (false, context.tr('barcodeRequiredForAllVariants'));
            }
            if (v.weight == null || v.weight!.trim().isEmpty) {
              return (false, context.tr('weightRequiredForAllVariants'));
            }
            if (v.height == null || v.height!.trim().isEmpty) {
              return (false, context.tr('heightRequiredForAllVariants'));
            }
            if (v.breadth == null || v.breadth!.trim().isEmpty) {
              return (false, context.tr('breadthRequiredForAllVariants'));
            }
            if (v.length == null || v.length!.trim().isEmpty) {
              return (false, context.tr('lengthRequiredForAllVariants'));
            }
          }
          if (!hasDefault) {
            return (false, context.tr('selectAtLeastOneDefaultVariant'));
          }
        }
        return (true, null);

      case 5:
        if (data.mainImage == null) {
          return (false, context.tr('mainProductImageCompulsory'));
        }
        if (data.videoType == 'youtube') {
          final error = ValidatorUtils.validateUrl(context, data.videoLink);
          if (error != null) {
            return (false, error);
          }
        } else if (data.videoType == 'self_hosted') {
          if ((data.productVideo == null || data.productVideo!.trim().isEmpty) &&
              (data.videoLink == null || data.videoLink!.trim().isEmpty)) {
            return (false, context.tr('videoRequired'));
          }
        }
        return (true, null);

      case 6:
        final min = data.minimumOrderQuantity;
        final stepSize = data.quantityStepSize;
        final total = data.totalAllowedQuantity;

        // Mandatory fields
        if (min <= 0) {
          return (false, context.tr('minOrderQtyPositive'));
        }
        if (stepSize <= 0) {
          return (false, context.tr('qtyStepSizePositive'));
        }

        // Optional total – but when provided, must follow rules
        if (total != 0) {
          // total is explicitly set → validate it
          if (total < 0) {
            return (false, context.tr('totalAllowedQtyPositive'));
          }
          if (total < min) {
            return (false, context.tr('totalAllowedQtyMinOrderConflict'));
          }
          if (min % stepSize != 0) {
            return (false, context.tr('minOrderQtyDivisibleByStep'));
          }
        } else {
          // total is null / 0 / empty → no upper limit
          // Still need to check that min is compatible with step
          if (min % stepSize != 0) {
            return (false, context.tr('minOrderQtyDivisibleByStep'));
          }
          // No other checks needed when there's no total cap
        }

        return (true, null);

      case 7:
        if (data.storePricing.isEmpty) {
          return (false, context.tr('selectAtLeastOneStore'));
        }

        for (var sp in data.storePricing) {
          if (data.type == 'simple') {
            if (sp.price == null || sp.price!.trim().isEmpty) {
              return (false, context.tr('priceRequiredForStore', positionalArgs: [sp.storeName]));
            }
            // Price vs Special Price check
            final double? price = double.tryParse(sp.price!);
            final double? specialPrice = sp.specialPrice != null && sp.specialPrice!.isNotEmpty
                ? double.tryParse(sp.specialPrice!)
                : null;
            if (price != null && specialPrice != null && specialPrice > price) {
              return (false, context.tr('specialPriceGreaterError', positionalArgs: [sp.storeName]));
            }
            if (sp.cost == null || sp.cost!.trim().isEmpty) {
              return (false, context.tr('costRequiredForStore', positionalArgs: [sp.storeName]));
            }
            if (sp.stock == null || sp.stock!.trim().isEmpty) {
              return (false, context.tr('stockRequiredForStore', positionalArgs: [sp.storeName]));
            }
            if (sp.sku == null || sp.sku!.trim().isEmpty) {
              return (false, context.tr('skuRequiredForStore', positionalArgs: [sp.storeName]));
            }
          } else {
            // For variants, we need to check variantStorePricing for this store
            final vps = data.variantStorePricing.where((vp) => vp.storeId == sp.storeId).toList();
            if (vps.isEmpty) {
              return (false, context.tr('pricingNotSetForStore', positionalArgs: [sp.storeName]));
            }
            for (var vp in vps) {
              final variantName =
                  data.variants
                      .firstWhere(
                        (v) => v.id == vp.variantId,
                        orElse: () => VariantData(title: "Unknown", attributeValueIds: []),
                      )
                      .name ??
                  "Unknown";
              if (vp.price == null || vp.price!.trim().isEmpty) {
                return (false, context.tr('priceRequiredForStoreVariant', positionalArgs: [sp.storeName, variantName]));
              }
              if (vp.stock == null || vp.stock!.trim().isEmpty) {
                return (false, context.tr('stockRequiredForStoreVariant', positionalArgs: [sp.storeName, variantName]));
              }
              if (vp.sku == null || vp.sku!.trim().isEmpty) {
                return (false, context.tr('skuRequiredForStoreVariant', positionalArgs: [sp.storeName, variantName]));
              }
              if (vp.cost == null || vp.cost!.trim().isEmpty) {
                return (false, context.tr('costRequiredForStoreVariant', positionalArgs: [sp.storeName, variantName]));
              }

              // Price vs Special Price check
              final double? price = double.tryParse(vp.price!);
              final double? specialPrice = vp.specialPrice != null && vp.specialPrice!.isNotEmpty
                  ? double.tryParse(vp.specialPrice!)
                  : null;
              if (price != null && specialPrice != null && specialPrice > price) {
                return (
                  false,
                  context.tr('specialPriceGreaterErrorVariant', positionalArgs: [sp.storeName, variantName]),
                );
              }
            }
          }
        }
        return (true, null);

      default:
        return (true, null);
    }
  }

  bool _isHtmlEmpty(String html) {
    if (html.trim().isEmpty) return true;
    // Remove HTML tags and check if text remains
    final String plainText = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return plainText.isEmpty;
  }

  bool _isStepCompleted(int step, ProductData data) {
    return _validateStep(step, data).$1;
  }

  bool _canSubmit(ProductData data) {
    bool allGood = true;

    for (int i = 1; i <= _totalSteps; i++) {
      final ok = _isStepCompleted(i, data);
      if (!ok) {
        allGood = false;
      }
    }

    return allGood;
  }

  void _onAddProductPressed() {
    final bloc = context.read<AddProductBloc>();
    if (_canSubmit(bloc.state.productData)) {
      if (!DemoGuard.shouldProceed(context)) return;
      bloc.add(SubmitProduct());
    } else {
      showCustomSnackbar(
        context: context,
        message: context.tr('pleaseCompleteallRequiredFieldsInPreviousSteps'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return BlocListener<AddProductBloc, AddProductState>(
      listener: (context, state) {
        if (state is AddProductSubmitting || state is AddProductLoadingEdit) {
          if (!_isLoadingShowing) {
            _isLoadingShowing = true;
            UIUtilsDialogs.showLoadingDialog(context);
          }
        } else if (state is AddProductSuccess) {
          if (_isLoadingShowing) {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
            _isLoadingShowing = false;
          }
          showCustomSnackbar(context: context, message: context.tr('productAddedSuccessfully'));
          if (context.canPop()) {
            context.pop(true); // Close the AddProductPage using go_router
          } else {
            Navigator.of(context).pop(true);
          }
        } else if (state is AddProductFailure || state is AddProductUpdating || state is AddProductInitial) {
          if (_isLoadingShowing) {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
            _isLoadingShowing = false;
          }
          if (state is AddProductFailure) {
            log('AddProductFailure: ${state.error}');
            showCustomSnackbar(context: context, message: state.error, isError: true);
          }
        }
      },
      child: CustomScaffold(
        title: widget.isEdit ? context.tr('editProduct') : context.tr('addProduct'),
        showAppbar: true,
        centerTitle: true,
        onBackTap: () => Navigator.of(context).pop(),
        body: Column(
          children: [
            AddProductHeader(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepTitle: _getStepTitle(context, _currentStep),
              onStepTap: () => _showStepBottomSheet(context),
              screenType: screenType,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: UIUtils.gapMD(screenType)),
                child: _buildStepContent(_currentStep, screenType),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _onStepChanged(_currentStep - 1),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: Text(
                          context.tr('previous'),
                          style: const TextStyle(color: AppColors.primaryColor, fontSize: 16),
                        ),
                      ),
                    ),
                  if (_currentStep > 1) SizedBox(width: UIUtils.gapMD(screenType)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep == _totalSteps
                            ? context.tr('submit')
                            : context.tr('next'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step, ScreenType screenType) {
    switch (step) {
      case 1:
        return const CategorySelectionStep();
      case 2:
        return const ProductDescriptionStep();
      case 3:
        return const ProductInfoStep();
      case 4:
        return const ProductVariationStep();
      case 5:
        return const ProductImagesStep();
      case 6:
        return const PoliciesFeaturesStep();
      case 7:
        return const PricingTaxesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  void _showStepBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductProcessBottomSheet(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        onStepSelected: (step) {
          _onStepChanged(step);
          Navigator.pop(context);
        },
      ),
    );
  }
}
