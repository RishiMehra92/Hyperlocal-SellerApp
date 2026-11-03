import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class OrdersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getOrders({
    int? page,
    int? perPage,
    String? search,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    int? storeId,
    String? orderType,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (paymentType != null && paymentType.isNotEmpty)
          'payment_type': paymentType,
        if (range != null && range.isNotEmpty) 'range': range,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (sortDir != null && sortDir.isNotEmpty) 'sort_dir': sortDir,
        if (status != null && status.isNotEmpty) 'status': status,
        if (orderType != null && orderType.isNotEmpty) 'order_type': orderType,
        'store_id': storeId ?? HiveStorage.selectedStoreId,
      };

      final response = await _helper.get(
        ApiRoutes.ordersApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getScheduledOrders({
    int? page,
    int? perPage,
    String? search,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    int? storeId,
    String? orderType,
  }) async {
    try {
      final queryParameters = {
        'is_scheduled': 'true',
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (paymentType != null && paymentType.isNotEmpty)
          'payment_type': paymentType,
        if (range != null && range.isNotEmpty) 'range': range,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (sortDir != null && sortDir.isNotEmpty) 'sort_dir': sortDir,
        if (status != null && status.isNotEmpty) 'status': status,
        if (orderType != null && orderType.isNotEmpty) 'order_type': orderType,
        'store_id': storeId ?? HiveStorage.selectedStoreId,
      };

      final response = await _helper.get(
        ApiRoutes.ordersApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getOrderDetails(int sellerOrderId) async {
    try {
      final response = await _helper.get(
        '${ApiRoutes.ordersApi}/$sellerOrderId',
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateOrderStatus(int sellerOrderId, String status) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.ordersApi}/$sellerOrderId/$status',
        {},
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> bulkUpdateStatus(String status, List<int> orderItemIds) async {
    try {
      final response = await _helper.post(
        ApiRoutes.bulkUpdateStatusApi,
        {
          "status": status,
          "order_item_ids": orderItemIds,
        },
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getOrderFilters() async {
    try {
      final response = await _helper.get(ApiRoutes.ordersEnumsApi);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> verifyPickupOtp(int sellerOrderId, String otp) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.ordersApi}/$sellerOrderId/verify-pickup-otp',
        {'otp': otp},
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markReadyForPickup(int sellerOrderId) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.ordersApi}/$sellerOrderId/mark-ready-for-pickup',
        {},
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> cancelItem(int sellerOrderId, String reason) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.ordersApi}/$sellerOrderId/cancel-item',
        {'reason': reason},
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
