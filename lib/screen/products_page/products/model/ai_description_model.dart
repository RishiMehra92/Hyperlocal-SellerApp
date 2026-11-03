import 'package:hyper_local_seller/service/json_parser.dart';

class AiDescriptionResponse {
  final bool success;
  final String message;
  final AiDescriptionData? data;

  AiDescriptionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AiDescriptionResponse.fromJson(Map<String, dynamic> json) {
    return AiDescriptionResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? AiDescriptionData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class AiDescriptionData {
  final String? shortDescription;
  final String? description;

  AiDescriptionData({this.shortDescription, this.description});

  factory AiDescriptionData.fromJson(Map<String, dynamic> json) {
    return AiDescriptionData(
      shortDescription: JsonParser.string(
        json['short_description'] ?? json['shortDescription'] ?? '',
      ),
      description: JsonParser.string(json['description'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'short_description': shortDescription, 'description': description};
  }
}
