import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../model/return_reason_model.dart';

class ReturnReasonsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<Map<String, dynamic>> getReturnReasons({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      final response = await _helper.get(
        ApiRoutes.returnReasonsApi,
        queryParameters: queryParameters,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> addReturnReason(ReturnReason reason) async {
    try {
      final body = reason.toJson();
      final response = await _helper.post(ApiRoutes.returnReasonsApi, body);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateReturnReason(ReturnReason reason) async {
    try {
      final body = reason.toJson();
      final response = await _helper.put(
        '${ApiRoutes.returnReasonsApi}/${reason.id}',
        body,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteReturnReason(int id) async {
    try {
      final response = await _helper.delete(
        '${ApiRoutes.returnReasonsApi}/$id',
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
