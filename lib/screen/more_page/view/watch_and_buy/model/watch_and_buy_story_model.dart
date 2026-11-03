import 'package:hyper_local_seller/service/json_parser.dart';
import 'watch_and_buy_profile_model.dart';

class WatchAndBuyStoryProduct {
  final int? productId;
  final int? productVariantId;
  final int? storeId;
  final int? sortOrder;
  final String? title;
  final String? imageUrl;
  final num? price;

  WatchAndBuyStoryProduct({
    this.productId,
    this.productVariantId,
    this.storeId,
    this.sortOrder,
    this.title,
    this.imageUrl,
    this.price,
  });

  factory WatchAndBuyStoryProduct.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'] as Map<String, dynamic>?;
    final variantMap = json['variant'] as Map<String, dynamic>?;

    return WatchAndBuyStoryProduct(
      productId: JsonParser.intValue(json['product_id'] ?? productMap?['id']),
      productVariantId: JsonParser.intValue(
        json['product_variant_id'] ?? variantMap?['id'],
      ),
      storeId: JsonParser.intValue(json['store_id']),
      sortOrder: JsonParser.intValue(json['sort_order']),
      title: JsonParser.string(
        json['name'] ??
            json['title'] ??
            productMap?['title'] ??
            productMap?['name'],
      ),
      imageUrl: JsonParser.string(
        json['image_url'] ?? productMap?['image_url'],
      ),
      price: variantMap != null
          ? safeConvert<num>(variantMap['price'], fallback: 0)
          : (json['price'] != null
                ? safeConvert<num>(json['price'], fallback: 0)
                : null),
    );
  }
}

class WatchAndBuyStoryModel {
  final int id;
  final String uuid;
  final String source;
  final String contentType;
  final String? text;
  final String mediaUrl;
  final String? mediaMime;
  final int? mediaSizeBytes;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? durationMs;
  final String? expiresAt;
  final WatchAndBuyProfile? profile;
  final List<WatchAndBuyStoryProduct> products;
  final String? createdAt;

  WatchAndBuyStoryModel({
    required this.id,
    required this.uuid,
    required this.source,
    required this.contentType,
    this.text,
    required this.mediaUrl,
    this.mediaMime,
    this.mediaSizeBytes,
    this.mediaWidth,
    this.mediaHeight,
    this.durationMs,
    this.expiresAt,
    this.profile,
    this.products = const [],
    this.createdAt,
  });

  bool get isVideo => contentType.toLowerCase() == 'video';

  factory WatchAndBuyStoryModel.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyStoryModel(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      source: JsonParser.string(json['source']),
      contentType: JsonParser.string(json['content_type'], fallback: 'image'),
      text: json['text'] != null ? JsonParser.string(json['text']) : null,
      mediaUrl: JsonParser.string(json['media_url']),
      mediaMime: json['media_mime'] != null
          ? JsonParser.string(json['media_mime'])
          : null,
      mediaSizeBytes: json['media_size_bytes'] != null
          ? JsonParser.intValue(json['media_size_bytes'])
          : null,
      mediaWidth: json['media_width'] != null
          ? JsonParser.intValue(json['media_width'])
          : null,
      mediaHeight: json['media_height'] != null
          ? JsonParser.intValue(json['media_height'])
          : null,
      durationMs: json['duration_ms'] != null
          ? JsonParser.intValue(json['duration_ms'])
          : null,
      expiresAt: json['expires_at'] != null
          ? JsonParser.string(json['expires_at'])
          : null,
      profile: json['profile'] != null
          ? WatchAndBuyProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      products:
          (json['products'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WatchAndBuyStoryProduct.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? JsonParser.string(json['created_at'])
          : null,
    );
  }
}
