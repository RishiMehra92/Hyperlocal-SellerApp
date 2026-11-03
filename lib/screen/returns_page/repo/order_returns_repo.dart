import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../model/order_return_model.dart';
import '../model/return_filters.dart';

class OrderReturnsRepo {
  final ApiBaseHelper _helper;
  OrderReturnsRepo({ApiBaseHelper? helper})
    : _helper = helper ?? ApiBaseHelper();

  Future<ReturnListResponse> getReturns({
    int page = 1,
    int perPage = 15,
    ReturnFilters filters = const ReturnFilters(),
  }) async {
    final response = await _helper.get(
      ApiRoutes.orderReturnsApi,
      queryParameters: {
        ...filters.toQuery(),
        'page': page,
        'per_page': perPage,
      },
    );
    return ReturnListResponse.fromJson(returnJsonMap(response['data']));
  }

  Future<ReturnEnums> getEnums() async {
    final response = await _helper.get(ApiRoutes.orderReturnsEnumsApi);
    return ReturnEnums.fromJson(returnJsonMap(response['data']));
  }

  Future<OrderReturn> getDetails(int id) async {
    final response = await _helper.get('${ApiRoutes.orderReturnsApi}/$id');
    if (response['data'] is! Map) {
      throw ApiException('Return details unavailable');
    }
    return OrderReturn.fromJson(returnJsonMap(response['data']));
  }

  Future<String> decide(
    int id, {
    required String action,
    String? sellerComment,
  }) async {
    final response = await _helper
        .post('${ApiRoutes.orderReturnsApi}/$id/decision', {
          'action': action,
          if (sellerComment != null && sellerComment.trim().isNotEmpty)
            'seller_comment': sellerComment.trim(),
        });
    return response['message']?.toString() ?? '';
  }

  Future<String> confirmStore(
    int id, {
    required String action,
    String? disputeReason,
    String? remarks,
    List<String> inspectionPhotos = const [],
  }) async {
    final data = FormData.fromMap({
      'action': action,
      if (disputeReason != null && disputeReason.isNotEmpty)
        'dispute_reason': disputeReason,
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
    });
    for (final path in inspectionPhotos) {
      data.files.add(
        MapEntry(
          'inspection_photos[]',
          await MultipartFile.fromFile(path, filename: path.split('/').last),
        ),
      );
    }
    final response = await _helper.postMultipart(
      '${ApiRoutes.orderReturnsApi}/$id/store-confirm',
      data,
    );
    return response['message']?.toString() ?? '';
  }
}
