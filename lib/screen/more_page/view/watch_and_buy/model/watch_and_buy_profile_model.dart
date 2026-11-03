import 'package:hyper_local_seller/service/json_parser.dart';

class WatchAndBuyProfile {
  final int id;
  final String type;
  final String username;
  final String? bio;
  final String? photoUrl;
  final String status;
  final String? suspensionReason;

  WatchAndBuyProfile({
    required this.id,
    required this.type,
    required this.username,
    this.bio,
    this.photoUrl,
    required this.status,
    this.suspensionReason,
  });

  factory WatchAndBuyProfile.fromJson(Map<String, dynamic> json) {
    return WatchAndBuyProfile(
      id: JsonParser.intValue(json['id']),
      type: JsonParser.string(json['type']),
      username: JsonParser.string(json['username']),
      bio: json['bio'] != null ? JsonParser.string(json['bio']) : null,
      photoUrl: json['photo_url'] != null
          ? JsonParser.string(json['photo_url'])
          : null,
      status: JsonParser.string(json['status']),
      suspensionReason: json['suspension_reason'] != null
          ? JsonParser.string(json['suspension_reason'])
          : null,
    );
  }
}
