import 'dart:convert';
import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'product_model';

class ProductsResponse {
  bool? success;
  String? message;
  ProductsData? data;

  ProductsResponse({this.success, this.message, this.data});

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? ProductsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ProductsData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<Product>? products;

  ProductsData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.products,
  });

  factory ProductsData.fromJson(Map<String, dynamic> json) {
    return ProductsData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      products: JsonParser.list<Product>(
        json['data'],
        (v) => Product.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (products != null) {
      data['data'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductTranslations {
  final Map<String, String> title;
  final Map<String, String> shortDescription;
  final Map<String, String> description;

  ProductTranslations({
    this.title = const {},
    this.shortDescription = const {},
    this.description = const {},
  });

  factory ProductTranslations.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseMap(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {};
    }

    return ProductTranslations(
      title: parseMap(json['title']),
      shortDescription: parseMap(json['short_description']),
      description: parseMap(json['description']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'short_description': shortDescription,
      'description': description,
    };
  }
}

class VariantTranslations {
  final Map<String, String> title;

  VariantTranslations({
    this.title = const {},
  });

  factory VariantTranslations.fromJson(Map<String, dynamic> json) {
    if (json['title'] is Map) {
      return VariantTranslations(
        title: (json['title'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
    }
    return VariantTranslations();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}

class Product {
  int id;
  String? uuid;
  String? productStatus;
  String? rejectedReason;
  int? categoryId;
  CategoryHierarchyNode? categoryHierarchyKey;
  int? brandId;
  int? sellerId;
  String title;
  String slug;
  String? type;
  String? shortDescription;
  String? categorySlug;
  String? brandSlug;
  String? categoryName;
  String? brandName;
  String? sellerName;
  String? indicator;
  bool? isFavorite;
  String? estimatedDeliveryTime;
  int ratings;
  int ratingCount;
  String mainImage;
  String? imageFit;
  String? itemCountInCart;
  List<String> additionalImages;
  int? minimumOrderQuantity;
  int? quantityStepSize;
  int? totalAllowedQuantity;
  bool isReturnable;
  List<String> tags;
  String? warrantyPeriod;
  String? guaranteePeriod;
  String? madeIn;
  bool? isInclusiveTax;
  String? videoType;
  String? videoLink;
  String status;
  String? featured;
  String? description;
  String? hsnCode;
  int? prepTime;
  int? returnableDays;
  bool? isCancelable;
  String? cancelableTill;
  bool? isAttachmentRequired;
  bool? requiresOtp;
  String? productVideo;
  List<int> taxGroups;
  dynamic metadata;
  bool? isSaveForLater;
  String? attachmentMode;
  Badge? badge;
  bool? isSponsored;
  int? campaignId;
  String? visitorKey;
  bool? notificationSet;
  String? createdAt;
  String? updatedAt;
  StoreStatus? storeStatus;
  List<Variant>? variants;
  List<ProductAttribute>? productAttributes;
  Map<String, dynamic>? customFields;
  List<CustomProductSection>? customProductSections;
  ProductTranslations? translations;

  Product({
    required this.id,
    this.uuid,
    this.productStatus,
    this.rejectedReason,
    this.categoryId,
    this.categoryHierarchyKey,
    this.brandId,
    this.sellerId,
    required this.title,
    required this.slug,
    this.type,
    this.shortDescription,
    this.categorySlug,
    this.brandSlug,
    this.categoryName,
    this.brandName,
    this.sellerName,
    this.indicator,
    this.isFavorite,
    this.estimatedDeliveryTime,
    this.ratings = 0,
    this.ratingCount = 0,
    required this.mainImage,
    this.imageFit,
    this.itemCountInCart,
    this.additionalImages = const [],
    this.minimumOrderQuantity,
    this.quantityStepSize,
    this.totalAllowedQuantity,
    this.isReturnable = false,
    this.tags = const [],
    this.warrantyPeriod,
    this.guaranteePeriod,
    this.madeIn,
    this.isInclusiveTax,
    this.videoType,
    this.videoLink,
    this.status = 'active',
    this.featured,
    this.description,
    this.hsnCode,
    this.prepTime,
    this.returnableDays,
    this.isCancelable,
    this.cancelableTill,
    this.isAttachmentRequired,
    this.requiresOtp,
    this.productVideo,
    this.taxGroups = const [],
    this.metadata,
    this.isSaveForLater,
    this.attachmentMode,
    this.badge,
    this.isSponsored,
    this.campaignId,
    this.visitorKey,
    this.notificationSet,
    this.createdAt,
    this.updatedAt,
    this.storeStatus,
    this.variants,
    this.productAttributes,
    this.customFields,
    this.customProductSections,
    this.translations,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      uuid: JsonParser.string(json['uuid']),
      productStatus: JsonParser.string(json['product_status']),
      rejectedReason: JsonParser.string(json['rejected_reason']),
      categoryId: JsonParser.intValue(json['category_id']),
      brandId: JsonParser.intValue(json['brand_id']),
      sellerId: JsonParser.intValue(json['seller_id']),
      categoryHierarchyKey:
          json['category_hierarchy_key'] is Map<String, dynamic>
          ? CategoryHierarchyNode.fromJson(
              json['category_hierarchy_key'] as Map<String, dynamic>,
            )
          : null,

      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'title',
      ),
      slug: JsonParser.requireString(
        json['slug'],
        model: modelName,
        field: 'slug',
      ),

      type: JsonParser.string(json['type'] ?? 'simple'),
      shortDescription: JsonParser.string(json['short_description'] ?? ''),

      categorySlug: JsonParser.string(json['category']),
      brandSlug: JsonParser.string(json['brand']),
      categoryName: JsonParser.string(json['category_name']),
      brandName: JsonParser.string(json['brand_name']),
      sellerName: JsonParser.string(json['seller']),

      indicator: JsonParser.string(json['indicator']),
      isFavorite: JsonParser.boolValue(json['favorite']),

      estimatedDeliveryTime: JsonParser.string(json['estimated_delivery_time']),

      ratings: JsonParser.intValue(json['ratings'] ?? 0),
      ratingCount: JsonParser.intValue(json['rating_count'] ?? 0),

      mainImage: JsonParser.string(json['main_image']),
      imageFit: JsonParser.string(json['image_fit'] ?? 'cover'),

      itemCountInCart: JsonParser.string(json['item_count_in_cart'] ?? '0'),

      additionalImages: JsonParser.list<String>(
        json['additional_images'],
        (v) => JsonParser.string(v),
      ),

      minimumOrderQuantity: JsonParser.intValue(json['minimum_order_quantity']),
      quantityStepSize: JsonParser.intValue(json['quantity_step_size']),
      totalAllowedQuantity: JsonParser.intValue(json['total_allowed_quantity']),

      isReturnable: JsonParser.boolValue(json['is_returnable'] ?? false),

      tags: JsonParser.list<String>(json['tags'], (v) => JsonParser.string(v)),

      warrantyPeriod: JsonParser.string(json['warranty_period']),
      guaranteePeriod: JsonParser.string(json['guarantee_period']),
      madeIn: JsonParser.string(json['made_in']),

      isInclusiveTax: JsonParser.boolValue(json['is_inclusive_tax'] ?? false),

      videoType: JsonParser.string(json['video_type']),
      videoLink: JsonParser.string(json['video_link']),

      status: JsonParser.string(json['status'] ?? 'active'),
      featured: JsonParser.string(json['featured'] ?? '0'),
      description: JsonParser.string(json['description']),
      hsnCode: JsonParser.string(json['hsn_code']),
      prepTime: JsonParser.intValue(json['base_prep_time']),
      returnableDays: JsonParser.intValue(json['returnable_days']),
      isCancelable: JsonParser.boolValue(json['is_cancelable']),
      cancelableTill: JsonParser.string(json['cancelable_till']),
      isAttachmentRequired: JsonParser.boolValue(
        json['is_attachment_required'],
      ),
      requiresOtp: JsonParser.boolValue(json['requires_otp']),
      productVideo: JsonParser.string(json['product_video']),
      taxGroups: JsonParser.list<int>(
        json['tax_groups'] ?? json['tax_classes'],
        (v) => v is Map ? JsonParser.intValue(v['id']) : JsonParser.intValue(v),
      ),
      metadata: json['metadata'],
      isSaveForLater: JsonParser.boolValue(json['is_save_for_later']),
      attachmentMode: JsonParser.string(json['attachment_mode']),
      badge: json['badge'] != null ? Badge.fromJson(json['badge'] as Map<String, dynamic>) : null,
      isSponsored: JsonParser.boolValue(json['is_sponsored']),
      campaignId: JsonParser.intValue(json['campaign_id']),
      visitorKey: JsonParser.string(json['visitor_key']),
      notificationSet: JsonParser.boolValue(json['notification_set']),

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      storeStatus: json['store_status'] is Map<String, dynamic>
          ? StoreStatus.fromJson(json['store_status'] as Map<String, dynamic>)
          : null,

      variants: JsonParser.list<Variant>(
        json['variants'],
        (v) => Variant.fromJson(v as Map<String, dynamic>),
      ),

      productAttributes: JsonParser.list<ProductAttribute>(
        json['attributes'],
        (v) => ProductAttribute.fromJson(v as Map<String, dynamic>),
      ),
      customFields: () {
        if (json['custom_fields'] is Map<String, dynamic>) {
          return json['custom_fields'] as Map<String, dynamic>;
        } else if (json['custom_fields'] is List) {
          final Map<String, dynamic> result = {};
          for (var item in json['custom_fields']) {
            if (item is String) {
              try {
                final decoded = jsonDecode(item);
                if (decoded is Map &&
                    decoded.containsKey('key') &&
                    decoded.containsKey('value')) {
                  result[decoded['key']] = decoded['value'];
                }
              } catch (_) {}
            }
          }
          return result.isNotEmpty ? result : null;
        }
        return null;
      }(),
      customProductSections: JsonParser.list<CustomProductSection>(
        json['custom_product_sections'],
        (v) => CustomProductSection.fromJson(v as Map<String, dynamic>),
      ),
      translations: json['translations'] is Map<String, dynamic>
          ? ProductTranslations.fromJson(
              json['translations'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['product_status'] = productStatus;
    data['rejected_reason'] = rejectedReason;
    data['category_id'] = categoryId;
    data['brand_id'] = brandId;
    data['seller_id'] = sellerId;
    data['title'] = title;
    data['slug'] = slug;
    data['type'] = type;
    data['short_description'] = shortDescription;
    data['category'] = categorySlug;
    data['brand'] = brandSlug;
    data['category_name'] = categoryName;
    data['brand_name'] = brandName;
    data['seller'] = sellerName;
    data['indicator'] = indicator;
    data['favorite'] = isFavorite;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['ratings'] = ratings;
    data['rating_count'] = ratingCount;
    data['main_image'] = mainImage;
    data['image_fit'] = imageFit;
    data['item_count_in_cart'] = itemCountInCart;
    data['additional_images'] = additionalImages;
    data['minimum_order_quantity'] = minimumOrderQuantity;
    data['quantity_step_size'] = quantityStepSize;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['is_returnable'] = isReturnable;
    data['tags'] = tags;
    data['warranty_period'] = warrantyPeriod;
    data['guarantee_period'] = guaranteePeriod;
    data['made_in'] = madeIn;
    data['is_inclusive_tax'] = isInclusiveTax;
    data['video_type'] = videoType;
    data['video_link'] = videoLink;
    data['status'] = status;
    data['featured'] = featured;
    data['description'] = description;
    data['hsn_code'] = hsnCode;
    data['base_prep_time'] = prepTime;
    data['returnable_days'] = returnableDays;
    data['is_cancelable'] = isCancelable;
    data['cancelable_till'] = cancelableTill;
    data['is_attachment_required'] = isAttachmentRequired;
    data['requires_otp'] = requiresOtp;
    data['product_video'] = productVideo;
    data['tax_groups'] = taxGroups;
    data['metadata'] = metadata;
    data['is_save_for_later'] = isSaveForLater;
    data['attachment_mode'] = attachmentMode;
    if (badge != null) data['badge'] = badge!.toJson();
    data['is_sponsored'] = isSponsored;
    data['campaign_id'] = campaignId;
    data['visitor_key'] = visitorKey;
    data['notification_set'] = notificationSet;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (storeStatus != null) data['store_status'] = storeStatus!.toJson();
    if (variants != null) {
      data['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    if (productAttributes != null) {
      data['attributes'] = productAttributes!.map((a) => a.toJson()).toList();
    }
    if (customProductSections != null) {
      data['custom_product_sections'] = customProductSections!
          .map((s) => s.toJson())
          .toList();
    }
    if (translations != null) {
      data['translations'] = translations!.toJson();
    }
    return data;
  }
}

class CategoryHierarchyNode {
  int id;
  CategoryHierarchyNode? child;

  CategoryHierarchyNode({required this.id, this.child});

  factory CategoryHierarchyNode.fromJson(Map<String, dynamic> json) {
    return CategoryHierarchyNode(
      id: JsonParser.requireInt(
        json['id'],
        model: 'category_hierarchy_node',
        field: 'id',
      ),
      child: json['child'] != null
          ? CategoryHierarchyNode.fromJson(
              json['child'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (child != null) {
      data['child'] = child!.toJson();
    }
    return data;
  }
}

class CustomProductSection {
  int? id;
  String? uuid;
  String title;
  String? description;
  int sortOrder;
  List<CustomProductField> fields;

  CustomProductSection({
    this.id,
    this.uuid,
    required this.title,
    this.description,
    this.sortOrder = 0,
    this.fields = const [],
  });

  factory CustomProductSection.fromJson(Map<String, dynamic> json) {
    return CustomProductSection(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      title: JsonParser.string(json['title'] ?? ''),
      description: JsonParser.string(json['description']),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
      fields: JsonParser.list<CustomProductField>(
        json['fields'],
        (v) => CustomProductField.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'description': description,
      'sort_order': sortOrder,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}

class CustomProductField {
  int? id;
  String? uuid;
  String title;
  String? description;
  String? image;
  int sortOrder;

  CustomProductField({
    this.id,
    this.uuid,
    required this.title,
    this.description,
    this.image,
    this.sortOrder = 0,
  });

  factory CustomProductField.fromJson(Map<String, dynamic> json) {
    return CustomProductField(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      title: JsonParser.string(json['title'] ?? ''),
      description: JsonParser.string(json['description']),
      image: JsonParser.string(json['image']),
      sortOrder: JsonParser.intValue(json['sort_order'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'title': title,
      'description': description,
      'image': image,
      'sort_order': sortOrder,
    };
  }
}

class StoreStatus {
  bool isOpen;
  String status;

  StoreStatus({required this.isOpen, required this.status});

  factory StoreStatus.fromJson(Map<String, dynamic> json) {
    return StoreStatus(
      isOpen: JsonParser.boolValue(json['is_open'] ?? false),
      status: JsonParser.string(json['status'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class Variant {
  int? id;
  String? title;
  String? slug;
  String? image;
  double? weight;
  double? height;
  double? breadth;
  double? length;
  bool? availability;
  CartItem? cartItem;
  String? barcode;
  bool? isDefault;
  num? price;
  num? specialPrice;
  num? displayPrice;
  num? displaySpecialPrice;
  bool? isNotify;
  List<dynamic>? addonGroups;
  int? storeId;
  String? storeSlug;
  String? storeName;
  int? stock;
  String? sku;
  List<ProductAttribute>? variantAttributes;
  Map<String, String>? attributesMap;
  List<VariantStore>? stores; // Added this
  VariantTranslations? translations;

  Variant({
    this.id,
    this.title,
    this.slug,
    this.image,
    this.weight,
    this.height,
    this.breadth,
    this.length,
    this.availability,
    this.cartItem,
    this.barcode,
    this.isDefault,
    this.price,
    this.specialPrice,
    this.displayPrice,
    this.displaySpecialPrice,
    this.isNotify,
    this.addonGroups,
    this.storeId,
    this.storeSlug,
    this.storeName,
    this.stock,
    this.sku,
    this.variantAttributes,
    this.attributesMap,
    this.stores,
    this.translations,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
      slug: JsonParser.string(json['slug']),
      image: JsonParser.string(json['image'] ?? ''),
      weight: JsonParser.doubleValue(json['weight']),
      height: JsonParser.doubleValue(json['height']),
      breadth: JsonParser.doubleValue(json['breadth']),
      length: JsonParser.doubleValue(json['length']),
      availability: JsonParser.boolValue(json['availability'] ?? true),
      cartItem: json['cart_item'] is Map<String, dynamic>
          ? CartItem.fromJson(json['cart_item'] as Map<String, dynamic>)
          : null,
      barcode: JsonParser.string(json['barcode']),
      isDefault: JsonParser.boolValue(json['is_default'] ?? false),
      price: JsonParser.doubleValue(json['price']),
      specialPrice: JsonParser.doubleValue(json['special_price']),
      displayPrice: JsonParser.doubleValue(json['display_price']),
      displaySpecialPrice: JsonParser.doubleValue(json['display_special_price']),
      isNotify: JsonParser.boolValue(json['is_notify']),
      addonGroups: json['addon_groups'] != null ? List<dynamic>.from(json['addon_groups']) : [],
      storeId: JsonParser.intValue(json['store_id']),
      storeSlug: JsonParser.string(json['store_slug']),
      storeName: JsonParser.string(json['store_name']),
      stock: JsonParser.intValue(json['stock']),
      sku: JsonParser.string(json['sku']),

      variantAttributes: JsonParser.list<ProductAttribute>(
        json['attributes'],
        (v) => ProductAttribute.fromJson(v as Map<String, dynamic>),
      ),
      attributesMap: json['attributes'] is Map<String, dynamic>
          ? (json['attributes'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, value.toString()),
            )
          : null,
      stores: JsonParser.list<VariantStore>(
        json['stores'],
        (v) => VariantStore.fromJson(v as Map<String, dynamic>),
      ),
      translations: json['translations'] is Map<String, dynamic>
          ? VariantTranslations.fromJson(
              json['translations'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['weight'] = weight;
    data['height'] = height;
    data['breadth'] = breadth;
    data['length'] = length;
    data['availability'] = availability;
    if (cartItem != null) data['cart_item'] = cartItem!.toJson();
    data['barcode'] = barcode;
    data['is_default'] = isDefault;
    data['price'] = price;
    data['special_price'] = specialPrice;
    data['display_price'] = displayPrice;
    data['display_special_price'] = displaySpecialPrice;
    data['is_notify'] = isNotify;
    data['addon_groups'] = addonGroups;
    data['store_id'] = storeId;
    data['store_slug'] = storeSlug;
    data['store_name'] = storeName;
    data['stock'] = stock;
    data['sku'] = sku;
    if (variantAttributes != null) {
      data['attributes'] = variantAttributes!.map((a) => a.toJson()).toList();
    }
    if (stores != null) {
      data['stores'] = stores!.map((s) => s.toJson()).toList();
    }
    if (translations != null) {
      data['translations'] = translations!.toJson();
    }
    return data;
  }
}

class VariantStore {
  int? id;
  int? storeId;
  String? storeSlug;
  String? storeName;
  String? sku;
  double? price;
  double? specialPrice;
  double? displayPrice;
  double? displaySpecialPrice;
  double? cost;
  int? stock;

  VariantStore({
    this.id,
    this.storeId,
    this.storeSlug,
    this.storeName,
    this.sku,
    this.price,
    this.specialPrice,
    this.displayPrice,
    this.displaySpecialPrice,
    this.cost,
    this.stock,
  });

  factory VariantStore.fromJson(Map<String, dynamic> json) {
    return VariantStore(
      id: JsonParser.intValue(json['id']),
      storeId: JsonParser.intValue(json['store_id']),
      storeSlug: JsonParser.string(json['store_slug']),
      storeName: JsonParser.string(json['store_name']),
      sku: JsonParser.string(json['sku']),
      price: JsonParser.doubleValue(json['price']),
      specialPrice: JsonParser.doubleValue(json['special_price']),
      displayPrice: JsonParser.doubleValue(json['display_price']),
      displaySpecialPrice: JsonParser.doubleValue(json['display_special_price']),
      cost: JsonParser.doubleValue(json['cost']),
      stock: JsonParser.intValue(json['stock']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'store_slug': storeSlug,
      'store_name': storeName,
      'sku': sku,
      'price': price,
      'special_price': specialPrice,
      'display_price': displayPrice,
      'display_special_price': displaySpecialPrice,
      'cost': cost,
      'stock': stock,
    };
  }
}

class CartItem {
  bool exists;
  int? cartItemId;

  CartItem({this.exists = false, this.cartItemId});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      exists: JsonParser.boolValue(json['exists'] ?? false),
      cartItemId: JsonParser.intValue(json['cart_item_id']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['exists'] = exists;
    data['cart_item_id'] = cartItemId;
    return data;
  }
}

class ProductAttribute {
  String name;
  String slug;
  String? swatcheType;
  List<String> values;
  List<SwatchValue>? swatchValues;

  ProductAttribute({
    required this.name,
    required this.slug,
    this.swatcheType,
    this.values = const [],
    this.swatchValues,
  });

  factory ProductAttribute.fromJson(Map<String, dynamic> json) {
    return ProductAttribute(
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'attributes[].name',
      ),
      slug: JsonParser.requireString(
        json['slug'],
        model: modelName,
        field: 'attributes[].slug',
      ),
      swatcheType: JsonParser.string(json['swatche_type']),
      values: JsonParser.list<String>(
        json['values'],
        (v) => JsonParser.string(v),
      ),
      swatchValues: JsonParser.list<SwatchValue>(
        json['swatch_values'],
        (v) => SwatchValue.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['slug'] = slug;
    data['swatche_type'] = swatcheType;
    data['values'] = values;
    if (swatchValues != null) {
      data['swatch_values'] = swatchValues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SwatchValue {
  String? value;
  String? swatch;

  SwatchValue({this.value, this.swatch});

  factory SwatchValue.fromJson(Map<String, dynamic> json) {
    return SwatchValue(
      value: JsonParser.string(json['value']),
      swatch: JsonParser.string(json['swatch']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['swatch'] = swatch;
    return data;
  }
}

class Badge {
  int? id;
  String? label;
  String? bgColor;
  String? textColor;
  String? borderColor;

  Badge({this.id, this.label, this.bgColor, this.textColor, this.borderColor});

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: JsonParser.intValue(json['id']),
      label: JsonParser.string(json['label']),
      bgColor: JsonParser.string(json['bg_color']),
      textColor: JsonParser.string(json['text_color']),
      borderColor: JsonParser.string(json['border_color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'bg_color': bgColor,
      'text_color': textColor,
      'border_color': borderColor,
    };
  }
}
