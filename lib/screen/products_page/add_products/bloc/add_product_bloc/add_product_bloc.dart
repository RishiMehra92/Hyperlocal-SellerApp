// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/ai_description_model.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attribute_values_model.dart'
    as values_model;
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart'
    as attr_model;
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';

part 'add_product_event.dart';
part 'add_product_state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final AddProductRepo _repo;
  final ProductsRepo _productsRepo;
  final CategoriesRepo _categoriesRepo;
  final AttributesRepo _attributesRepo;

  AddProductBloc(
    this._repo,
    this._productsRepo,
    this._categoriesRepo,
    this._attributesRepo,
  ) : super(AddProductInitial()) {
    on<UpdateProductData>(_onUpdateProductData);
    on<SubmitProduct>(_onSubmitProduct);
    on<AddProductReset>(_onReset);
    on<LoadProductForEdit>(_onLoadProductForEdit);
    on<SetProductForEdit>(_onSetProductForEdit);
    on<GenerateAiDescription>(_onGenerateAiDescription);
    on<FetchAttributeValues>(_onFetchAttributeValues);
  }

  Future<void> _onLoadProductForEdit(
    LoadProductForEdit event,
    Emitter<AddProductState> emit,
  ) async {
    emit(AddProductLoadingEdit());
    try {
      final response = await _productsRepo.getProductById(event.productId);
      if (response != null && response['data'] != null) {
        final product = Product.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        add(SetProductForEdit(product));
      } else {
        emit(AddProductFailure(ProductData(), 'Failed to load product data'));
      }
    } catch (e) {
      emit(AddProductFailure(ProductData(), e.toString()));
    }
  }

  Future<void> _onSetProductForEdit(
    SetProductForEdit event,
    Emitter<AddProductState> emit,
  ) async {
    final p = event.product;
    final data = ProductData();

    data.id = p.id;
    data.categoryId = p.categoryId;
    data.brandId = p.brandId;
    data.brandName = p.brandName;
    data.madeIn = p.madeIn;
    data.title = p.title;
    data.hsnCode = p.hsnCode;
    data.indicator = p.indicator;
    data.prepTime = p.prepTime ?? 20;
    data.isReturnable = p.isReturnable;
    data.returnableDays = p.returnableDays ?? 0;
    data.isCancelable = p.isCancelable ?? false;
    data.cancelableTill = p.cancelableTill;
    data.type = p.type ?? 'simple';
    data.barcode = p.variants?.isNotEmpty == true
        ? p.variants!.first.barcode
        : null;
    data.mainImage = p.mainImage.isNotEmpty ? p.mainImage : null;
    data.taxGroupIds = List<int>.from(p.taxGroups);
    data.isInclusiveTax = p.isInclusiveTax ?? false;
    data.imageFit = p.imageFit ?? "cover";
    data.videoType = p.videoType;
    data.videoLink = p.videoLink;
    data.shortDescription = p.shortDescription;
    data.description = p.description;

    final activeLocale = HiveStorage.languageCode.isNotEmpty ? HiveStorage.languageCode : 'en';
    if (p.translations != null) {
      data.titleTranslations = Map<String, String>.from(p.translations!.title);
      data.shortDescriptionTranslations = Map<String, String>.from(p.translations!.shortDescription);
      data.descriptionTranslations = Map<String, String>.from(p.translations!.description);
    }
    if (data.titleTranslations.isEmpty && p.title.isNotEmpty) {
      data.titleTranslations[activeLocale] = p.title;
    }
    if (data.shortDescriptionTranslations.isEmpty && (p.shortDescription?.isNotEmpty ?? false)) {
      data.shortDescriptionTranslations[activeLocale] = p.shortDescription!;
    }
    if (data.descriptionTranslations.isEmpty && (p.description?.isNotEmpty ?? false)) {
      data.descriptionTranslations[activeLocale] = p.description!;
    }
    data.minimumOrderQuantity = p.minimumOrderQuantity ?? 1;
    data.quantityStepSize = p.quantityStepSize ?? 1;
    data.totalAllowedQuantity = p.totalAllowedQuantity ?? 0;
    data.isAttachmentRequired = p.isAttachmentRequired ?? false;
    data.featured = p.featured == "1";
    data.requiresOtp = p.requiresOtp ?? false;
    data.warrantyPeriod = p.warrantyPeriod;
    data.guaranteePeriod = p.guaranteePeriod;
    data.tags = List<String>.from(p.tags);

    // Populate categoryLineage from CategoryHierarchyNode
    final List<int> lineage = [];
    CategoryHierarchyNode? currentNode = p.categoryHierarchyKey;
    while (currentNode != null) {
      lineage.add(currentNode.id);
      currentNode = currentNode.child;
    }
    data.categoryLineage = lineage;

    if (p.customFields != null) {
      data.customFields = p.customFields!.entries
          .map((e) => {'key': e.key, 'value': e.value.toString()})
          .toList();
    }

    if (p.mainImage.isNotEmpty) {
      data.mainImage = p.mainImage;
    }

    if (p.additionalImages.isNotEmpty) {
      data.otherImages = List<String>.from(p.additionalImages);
    }

    if (p.productVideo != null && p.productVideo!.isNotEmpty) {
      data.productVideo = p.productVideo;
    }

    if (p.variants != null && p.variants!.isNotEmpty) {
      final Map<String, VariantData> uniqueVariants = {};
      final Set<int> uniqueStoreIds = {};

      final Map<String, int> valueIdBySlugAndTitle = {};

      try {
        final attrListResponse = await _attributesRepo.getAttributes(
          page: 1,
          perPage: 100,
        );
        final parsedAttrResponse = attr_model.AttributesResponse.fromJson(
          attrListResponse,
        );
        final allAttrs = parsedAttrResponse.data?.attributes ?? [];

        final Set<String> neededSlugsOrNames = {};
        if (p.productAttributes != null) {
          for (var pa in p.productAttributes!) {
            neededSlugsOrNames.add(pa.slug);
            neededSlugsOrNames.add(pa.name);
          }
        }
        for (var v in p.variants!) {
          if (v.attributesMap != null) {
            neededSlugsOrNames.addAll(v.attributesMap!.keys);
          }
          if (v.variantAttributes != null) {
            for (var va in v.variantAttributes!) {
              neededSlugsOrNames.add(va.slug);
              neededSlugsOrNames.add(va.name);
            }
          }
        }

        final Map<int, attr_model.Attribute> matchedAttributes = {};
        for (var slugOrName in neededSlugsOrNames) {
          if (slugOrName.trim().isEmpty) continue;
          final normKey = slugOrName.trim().toLowerCase();
          attr_model.Attribute? match;
          for (final a in allAttrs) {
            if (a.slug.trim().toLowerCase() == normKey ||
                a.title.trim().toLowerCase() == normKey) {
              match = a;
              break;
            }
          }

          if (match != null) {
            matchedAttributes[match.id] = match;
          } else {
            try {
              final searchResp = await _attributesRepo.getAttributes(
                page: 1,
                perPage: 100,
                search: slugOrName,
              );
              final parsedSearch = attr_model.AttributesResponse.fromJson(
                searchResp,
              );
              final searchItems = parsedSearch.data?.attributes ?? [];
              for (final sItem in searchItems) {
                if (sItem.slug.trim().toLowerCase() == normKey ||
                    sItem.title.trim().toLowerCase() == normKey) {
                  match = sItem;
                  break;
                }
              }
              match ??= (searchItems.isNotEmpty ? searchItems.first : null);
              if (match != null) {
                matchedAttributes[match.id] = match;
              }
            } catch (_) {}
          }
        }

        final Map<int, List<values_model.AttributeValue>> fetchedValuesCache = {};
        await Future.wait(
          matchedAttributes.keys.map((attrId) async {
            try {
              final valResp = await _attributesRepo.getAttributeValues(attrId);
              final parsedVal = values_model.AttributeValuesResponse.fromJson(
                valResp,
              );
              final values = parsedVal.data?.values ?? [];
              fetchedValuesCache[attrId] = values;
              final attr = matchedAttributes[attrId];
              if (attr != null) {
                for (var val in values) {
                  final valTitleNorm = val.title.trim().toLowerCase();
                  valueIdBySlugAndTitle['${attr.slug.trim().toLowerCase()}:$valTitleNorm'] =
                      val.id;
                  valueIdBySlugAndTitle['${attr.title.trim().toLowerCase()}:$valTitleNorm'] =
                      val.id;
                  valueIdBySlugAndTitle['${attr.id}:$valTitleNorm'] = val.id;
                  valueIdBySlugAndTitle[':$valTitleNorm'] = val.id;
                }
              }
            } catch (_) {}
          }),
        );
        data.attributeValuesCache = fetchedValuesCache;
      } catch (_) {}

      for (var v in p.variants!) {
        final variantTitle = (v.title != null && v.title!.trim().isNotEmpty)
            ? v.title!
            : p.title;

        if (!uniqueVariants.containsKey(variantTitle)) {
          final Map<String, String> vTitleTrans = {};
          if (v.translations != null && v.translations!.title.isNotEmpty) {
            vTitleTrans.addAll(v.translations!.title);
          } else {
            vTitleTrans[activeLocale] = variantTitle;
          }

          final vd = VariantData(
            id: v.id?.toString(),
            title: variantTitle,
            name: variantTitle,
            titleTranslations: vTitleTrans,
            attributeValueIds: [],
            barcode: v.barcode ?? "",
            weight: v.weight != null ? v.weight.toString() : "",
            height: v.height != null ? v.height.toString() : "",
            length: v.length != null ? v.length.toString() : "",
            breadth: v.breadth != null ? v.breadth.toString() : "",
            isAvailable: v.availability ?? true,
            isDefault: v.isDefault ?? false,
            image: (v.image?.isNotEmpty == true) ? v.image : null,
          );

          final List<int> resolvedValueIds = [];
          if (v.attributesMap != null) {
            vd.attributes = v.attributesMap!.entries.map((e) {
              ProductAttribute? attr;
              if (p.productAttributes != null) {
                for (var pa in p.productAttributes!) {
                  if (pa.slug == e.key || pa.name == e.key) {
                    attr = pa;
                    break;
                  }
                }
              }
              final valTitleNorm = e.value.trim().toLowerCase();
              final foundId =
                  valueIdBySlugAndTitle['${e.key.trim().toLowerCase()}:$valTitleNorm'] ??
                  valueIdBySlugAndTitle['${(attr?.name ?? e.key).trim().toLowerCase()}:$valTitleNorm'] ??
                  valueIdBySlugAndTitle[':$valTitleNorm'];
              if (foundId != null) {
                resolvedValueIds.add(foundId);
              }
              return {
                "attribute_id": e.key,
                "value_id": foundId != null ? foundId.toString() : e.value,
                "attribute_name": attr?.name ?? e.key,
                "value_name": e.value,
              };
            }).toList();
          } else if (v.variantAttributes != null) {
            vd.attributes = v.variantAttributes!
                .map(
                  (a) {
                    final valName = a.values.isNotEmpty ? a.values.first : "";
                    final valTitleNorm = valName.trim().toLowerCase();
                    final foundId =
                        valueIdBySlugAndTitle['${a.slug.trim().toLowerCase()}:$valTitleNorm'] ??
                        valueIdBySlugAndTitle['${a.name.trim().toLowerCase()}:$valTitleNorm'] ??
                        valueIdBySlugAndTitle[':$valTitleNorm'];
                    if (foundId != null) {
                      resolvedValueIds.add(foundId);
                    }
                    return {
                      "attribute_id": a.slug,
                      "value_id": foundId != null ? foundId.toString() : valName,
                      "attribute_name": a.name,
                      "value_name": valName,
                    };
                  },
                )
                .toList();
          }
          vd.attributeValueIds = resolvedValueIds;

          uniqueVariants[variantTitle] = vd;
        }

        // Handle Store Pricing
        final storesList = v.stores ?? [];
        if (storesList.isEmpty && v.storeId != null) {
          storesList.add(
            VariantStore(
              storeId: v.storeId,
              storeName: v.storeName,
              sku: v.sku,
              price: v.price?.toDouble(),
              specialPrice: v.specialPrice?.toDouble(),
              stock: v.stock,
            ),
          );
        }

        for (var s in storesList) {
          if (s.storeId != null) {
            if (!uniqueStoreIds.contains(s.storeId)) {
              uniqueStoreIds.add(s.storeId!);
              data.storePricing.add(
                StorePricing(
                  storeId: s.storeId!,
                  storeName: s.storeName ?? "Store",
                  price: p.type == 'simple' ? s.price?.toString() : null,
                  specialPrice: p.type == 'simple'
                      ? s.specialPrice?.toString()
                      : null,
                  cost: p.type == 'simple' ? s.cost?.toString() : null,
                  stock: p.type == 'simple' ? s.stock?.toString() : null,
                  sku: p.type == 'simple' ? s.sku : null,
                ),
              );
            } else if (p.type == 'simple') {
              final idx = data.storePricing.indexWhere(
                (sp) => sp.storeId == s.storeId,
              );
              if (idx != -1) {
                data.storePricing[idx] = data.storePricing[idx].copyWith(
                  price: s.price?.toString(),
                  specialPrice: s.specialPrice?.toString(),
                  stock: s.stock?.toString(),
                  sku: s.sku,
                );
              }
            }

            if (p.type == 'variant') {
              final vd = uniqueVariants[variantTitle];
              if (vd != null) {
                data.variantStorePricing.add(
                  VariantStorePricing(
                    storeId: s.storeId!,
                    variantId: vd.id ?? "",
                    price: s.price?.toString(),
                    specialPrice: s.specialPrice?.toString(),
                    cost: s.cost?.toString(),
                    stock: s.stock?.toString(),
                    sku: s.sku,
                  ),
                );
              }
            }
          }
        }
      }

      if (uniqueVariants.isNotEmpty && !uniqueVariants.values.any((v) => v.isDefault)) {
        uniqueVariants.values.first.isDefault = true;
      }
      data.variants = uniqueVariants.values.toList();
    }

    if (p.type == 'simple') {
      final v = p.variants?.isNotEmpty == true ? p.variants!.first : null;
      data.barcode = v?.barcode ?? data.barcode ?? "";
      if (data.variants.isEmpty) {
        data.variants = [
          VariantData(
            id: v?.id?.toString() ?? "s_${DateTime.now().microsecondsSinceEpoch}",
            title: p.title,
            name: p.title,
            titleTranslations: Map<String, String>.from(data.titleTranslations),
            attributeValueIds: [],
            barcode: data.barcode,
            weight: (v != null && v.weight != null) ? v.weight!.toString() : "",
            height: (v != null && v.height != null) ? v.height!.toString() : "",
            length: (v != null && v.length != null) ? v.length!.toString() : "",
            breadth: (v != null && v.breadth != null) ? v.breadth!.toString() : "",
            isAvailable: v?.availability ?? true,
            isDefault: true,
          ),
        ];
      }
    }

    if (p.customProductSections != null) {
      data.customProductSections = p.customProductSections!.map((s) {
        return CustomProductSection(
          id: s.id,
          uuid: s.uuid,
          title: s.title,
          description: s.description,
          sortOrder: s.sortOrder,
          fields: s.fields.map((f) {
            return CustomProductField(
              id: f.id,
              uuid: f.uuid,
              title: f.title,
              description: f.description,
              image: (f.image?.isNotEmpty == true) ? f.image : null,
              sortOrder: f.sortOrder,
            );
          }).toList(),
        );
      }).toList();
    }

    emit(AddProductUpdating(data));
  }

  void _onReset(AddProductReset event, Emitter<AddProductState> emit) {
    emit(AddProductInitial());
  }

  void _onUpdateProductData(
    UpdateProductData event,
    Emitter<AddProductState> emit,
  ) {
    emit(AddProductUpdating(event.productData));
  }

  Future<void> _onSubmitProduct(
    SubmitProduct event,
    Emitter<AddProductState> emit,
  ) async {
    emit(AddProductSubmitting(state.productData));
    try {
      await _repo.addProduct(productData: state.productData);
      emit(AddProductSuccess(state.productData));
    } catch (e) {
      emit(AddProductFailure(state.productData, e.toString()));
    }
  }

  Future<void> _onFetchAttributeValues(
    FetchAttributeValues event,
    Emitter<AddProductState> emit,
  ) async {
    try {
      final valResp = await _attributesRepo.getAttributeValues(event.attributeId);
      final parsedVal = values_model.AttributeValuesResponse.fromJson(valResp);
      final values = parsedVal.data?.values ?? [];
      final newCache = Map<int, List<values_model.AttributeValue>>.from(
        state.productData.attributeValuesCache,
      );
      newCache[event.attributeId] = values;
      emit(AddProductUpdating(state.productData.copyWith(attributeValuesCache: newCache)));
    } catch (_) {}
  }

  Future<void> _onGenerateAiDescription(
    GenerateAiDescription event,
    Emitter<AddProductState> emit,
  ) async {
    emit(AiDescriptionGenerationLoading(state.productData));
    try {
      final AiDescriptionResponse response = await _repo
          .generateProductDescription(
            title: event.title,
            categoryId: event.categoryId,
            tone: event.tone,
            keywords: event.keywords,
          );

      if (response.success && response.data != null) {
        final shortDesc = response.data!.shortDescription ?? '';
        final desc = response.data!.description ?? '';
        emit(
          AiDescriptionGenerationSuccess(state.productData, shortDesc, desc),
        );
      } else {
        emit(
          AiDescriptionGenerationFailure(state.productData, response.message),
        );
      }
    } catch (e) {
      emit(AiDescriptionGenerationFailure(state.productData, e.toString()));
    }
  }
}
