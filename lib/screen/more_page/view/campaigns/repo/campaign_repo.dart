import 'dart:developer';

import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import '../model/campaign_model.dart';
import '../model/campaign_product_model.dart';
import '../model/campaign_wallet_model.dart';

class CampaignRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  // ─── Ad Wallet ───────────────────────────────────────────────

  /// Fetch ad wallet balance and info
  Future<AdWalletModel?> fetchAdWallet() async {
    try {
      final response = await _helper.get(ApiRoutes.adWalletApi);
      if (response['success'] == true) {
        return AdWalletModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fetch ad wallet transactions (paginated)
  Future<AdWalletTransactionListModel?> fetchAdWalletTransactions({
    int page = 1,
    int perPage = 15,
    String? transactionType,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (transactionType != null && transactionType.isNotEmpty) {
        queryParameters['transaction_type'] = transactionType;
      }
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _helper.get(
        ApiRoutes.adWalletTransactionsApi,
        queryParameters: queryParameters,
      );
      if (response['success'] == true || response.containsKey('data')) {
        return AdWalletTransactionListModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Top up ad wallet via payment gateway
  Future<AdWalletTopupGatewayResponse?> topupViaGateway({
    required double amount,
    required String paymentMethod,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'amount': amount,
        'payment_method': paymentMethod,
      };
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await _helper.post(
        ApiRoutes.adWalletTopupGatewayApi,
        body,
      );
      if (response['success'] == true) {
        return AdWalletTopupGatewayResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Top up ad wallet from earnings wallet
  Future<AdWalletTopupEarningsResponse?> topupFromEarnings({
    required double amount,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = {'amount': amount};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await _helper.post(
        ApiRoutes.adWalletTopupEarningsApi,
        body,
      );
      if (response['success'] == true) {
        return AdWalletTopupEarningsResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ─── Campaign Products ───────────────────────────────────────

  /// Fetch products for campaign selection (paginated)
  Future<CampaignProductsResponse> fetchCampaignProducts({
    int page = 1,
    int perPage = 30,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _helper.get(
        ApiRoutes.productsApi,
        queryParameters: queryParameters,
      );
      log('Query parameter ${queryParameters.toString()}');
      return CampaignProductsResponse.fromJson(response);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ─── Ad Campaigns ────────────────────────────────────────────

  /// Fetch campaign config (validation rules)
  Future<CampaignConfigModel?> fetchCampaignConfig() async {
    try {
      final response = await _helper.get(ApiRoutes.adCampaignConfigApi);
      if (response['success'] == true) {
        return CampaignConfigModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fetch campaigns list (paginated)
  Future<CampaignListModel?> fetchCampaigns({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _helper.get(
        ApiRoutes.adCampaignsApi,
        queryParameters: queryParameters,
      );
      if (response['success'] == true || response.containsKey('data')) {
        return CampaignListModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Fetch single campaign detail
  Future<CampaignData?> fetchCampaignDetail(int id) async {
    try {
      final response = await _helper.get(ApiRoutes.adCampaignDetailApi(id));
      if (response['success'] == true && response['data'] != null) {
        return CampaignData.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Create a new campaign
  Future<Map<String, dynamic>> createCampaign({
    required int productId,
    required double budget,
  }) async {
    try {
      final response = await _helper.post(ApiRoutes.adCampaignsApi, {
        'product_id': productId,
        'budget': budget,
      });
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Pause a campaign
  Future<Map<String, dynamic>> pauseCampaign(int id) async {
    try {
      final response = await _helper.post(ApiRoutes.adCampaignPauseApi(id), {});
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Resume a campaign
  Future<Map<String, dynamic>> resumeCampaign(int id) async {
    try {
      final response = await _helper.post(
        ApiRoutes.adCampaignResumeApi(id),
        {},
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
