import 'package:hyper_local_seller/service/json_parser.dart';
import 'watch_and_buy_profile_model.dart';

class WatchAndBuyReelProduct {
  final int? productId;
  final int? productVariantId;
  final String? name;
  final String? imageUrl;
  final int? storeId;
  final int? sortOrder;
  final bool isPrimary;

  WatchAndBuyReelProduct({
    this.productId,
    this.productVariantId,
    this.name,
    this.imageUrl,
    this.storeId,
    this.sortOrder,
    this.isPrimary = false,
  });

  factory WatchAndBuyReelProduct.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyReelProduct(
      productId: JsonParser.intValue(json['product_id']),
      productVariantId: JsonParser.intValue(json['product_variant_id']),
      name: JsonParser.string(json['name']),
      imageUrl: JsonParser.string(json['image_url']),
      storeId: JsonParser.intValue(json['store_id']),
      sortOrder: JsonParser.intValue(json['sort_order']),
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class WatchAndBuyReelModel {
  final int id;
  final String uuid;
  final String slug;
  final String source;
  final String? caption;
  final String status;
  final String videoUrl;
  final String? coverUrl;
  final int? durationMs;
  final int? videoWidth;
  final int? videoHeight;
  final int? videoSizeBytes;
  final int likeCount;
  final WatchAndBuyProfile? profile;
  final List<WatchAndBuyReelProduct> products;
  final String? createdAt;
  final String? publishedAt;
  WatchAndBuyReelModel copyWith({
    int? id,
    String? uuid,
    String? slug,
    String? source,
    String? caption,
    String? status,
    String? videoUrl,
    String? coverUrl,
    int? durationMs,
    int? videoWidth,
    int? videoHeight,
    int? videoSizeBytes,
    int? likeCount,
    WatchAndBuyProfile? profile,
    List<WatchAndBuyReelProduct>? products,
    String? createdAt,
    String? publishedAt,
  }) {
    return WatchAndBuyReelModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      slug: slug ?? this.slug,
      source: source ?? this.source,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      durationMs: durationMs ?? this.durationMs,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      videoSizeBytes: videoSizeBytes ?? this.videoSizeBytes,
      likeCount: likeCount ?? this.likeCount,
      profile: profile ?? this.profile,
      products: products ?? this.products,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  WatchAndBuyReelModel({
    required this.id,
    required this.uuid,
    required this.slug,
    required this.source,
    this.caption,
    required this.status,
    required this.videoUrl,
    this.coverUrl,
    this.durationMs,
    this.videoWidth,
    this.videoHeight,
    this.videoSizeBytes,
    this.likeCount = 0,
    this.profile,
    this.products = const [],
    this.createdAt,
    this.publishedAt,
  });

  factory WatchAndBuyReelModel.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyReelModel(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      slug: JsonParser.string(json['slug']),
      source: JsonParser.string(json['source']),
      caption: json['caption'] != null
          ? JsonParser.string(json['caption'])
          : null,
      status: JsonParser.string(json['status'], fallback: 'published'),
      videoUrl: JsonParser.string(json['video_url']),
      coverUrl: json['cover_url'] != null
          ? JsonParser.string(json['cover_url'])
          : null,
      durationMs: json['duration_ms'] != null
          ? JsonParser.intValue(json['duration_ms'])
          : null,
      videoWidth: json['video_width'] != null
          ? JsonParser.intValue(json['video_width'])
          : null,
      videoHeight: json['video_height'] != null
          ? JsonParser.intValue(json['video_height'])
          : null,
      videoSizeBytes: json['video_size_bytes'] != null
          ? JsonParser.intValue(json['video_size_bytes'])
          : null,
      likeCount: json['like_count'] != null
          ? JsonParser.intValue(json['like_count'])
          : 0,
      profile: json['profile'] != null
          ? WatchAndBuyProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      products:
          (json['products'] as List<dynamic>?)
              ?.map(
                (e) =>
                    WatchAndBuyReelProduct.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? JsonParser.string(json['created_at'])
          : null,
      publishedAt: json['published_at'] != null
          ? JsonParser.string(json['published_at'])
          : null,
    );
  }
}
