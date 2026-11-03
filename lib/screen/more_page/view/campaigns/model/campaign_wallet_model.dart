import 'package:hyper_local_seller/service/json_parser.dart';

const String campaignWalletModelName = 'campaign_wallet_model';

/// Response model for GET /ad-wallet
class AdWalletModel {
  final bool success;
  final String message;
  final AdWalletData? wallet;
  final bool featureEnabled;
  final double minTopup;
  final String currencySymbol;

  AdWalletModel({
    required this.success,
    required this.message,
    this.wallet,
    required this.featureEnabled,
    required this.minTopup,
    required this.currencySymbol,
  });

  factory AdWalletModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return AdWalletModel(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      wallet: dataMap?['wallet'] != null
          ? AdWalletData.fromJson(dataMap!['wallet'] as Map<String, dynamic>)
          : null,
      featureEnabled: JsonParser.boolValue(
        dataMap?['feature_enabled'] ?? false,
      ),
      minTopup: JsonParser.doubleValue(dataMap?['min_topup']),
      currencySymbol: JsonParser.string(dataMap?['currency_symbol'] ?? ''),
    );
  }
}

/// Wallet data
class AdWalletData {
  final int id;
  final int userId;
  final String type;
  final String balance;
  final String blockedBalance;
  final String currencyCode;
  final String createdAt;
  final String updatedAt;

  AdWalletData({
    required this.id,
    required this.userId,
    required this.type,
    required this.balance,
    required this.blockedBalance,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdWalletData.fromJson(Map<String, dynamic> json) {
    return AdWalletData(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      type: JsonParser.string(json['type'] ?? ''),
      balance: JsonParser.string(json['balance'] ?? '0.00'),
      blockedBalance: JsonParser.string(json['blocked_balance'] ?? '0.00'),
      currencyCode: JsonParser.string(json['currency_code'] ?? ''),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }
}

/// Response model for POST /ad-wallet/topup/gateway
class AdWalletTopupGatewayResponse {
  final bool success;
  final String message;
  final AdWalletData? wallet;
  final AdWalletTransaction? transaction;
  final Map<String, dynamic>? paymentResponse;
  final String? paymentUrl;

  AdWalletTopupGatewayResponse({
    required this.success,
    required this.message,
    this.wallet,
    this.transaction,
    this.paymentResponse,
    this.paymentUrl,
  });

  factory AdWalletTopupGatewayResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return AdWalletTopupGatewayResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      wallet: dataMap?['wallet'] != null
          ? AdWalletData.fromJson(dataMap!['wallet'] as Map<String, dynamic>)
          : null,
      transaction: dataMap?['transaction'] != null
          ? AdWalletTransaction.fromJson(
              dataMap!['transaction'] as Map<String, dynamic>,
            )
          : null,
      paymentResponse: dataMap?['payment_response'] as Map<String, dynamic>?,
      paymentUrl: dataMap?['payment_url'] as String?,
    );
  }
}

/// Response model for POST /ad-wallet/topup/earnings
class AdWalletTopupEarningsResponse {
  final bool success;
  final String message;
  final AdWalletData? earningWallet;
  final AdWalletData? adWallet;

  AdWalletTopupEarningsResponse({
    required this.success,
    required this.message,
    this.earningWallet,
    this.adWallet,
  });

  factory AdWalletTopupEarningsResponse.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return AdWalletTopupEarningsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      earningWallet: dataMap?['earning_wallet'] != null
          ? AdWalletData.fromJson(
              dataMap!['earning_wallet'] as Map<String, dynamic>,
            )
          : null,
      adWallet: dataMap?['ad_wallet'] != null
          ? AdWalletData.fromJson(dataMap!['ad_wallet'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Transaction model for wallet transactions list
class AdWalletTransactionListModel {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<AdWalletTransaction> data;

  AdWalletTransactionListModel({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory AdWalletTransactionListModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return AdWalletTransactionListModel(
      success: JsonParser.boolValue(json['success'] ?? true),
      message: JsonParser.string(json['message'] ?? ''),
      currentPage: JsonParser.intValue(dataMap?['current_page'] ?? 1),
      lastPage: JsonParser.intValue(dataMap?['last_page'] ?? 1),
      perPage: JsonParser.intValue(dataMap?['per_page'] ?? 15),
      total: JsonParser.intValue(dataMap?['total'] ?? 0),
      data: (dataMap?['data'] as List? ?? [])
          .map((e) => AdWalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Single transaction data
class AdWalletTransaction {
  final int id;
  final int walletId;
  final int userId;
  final int? orderId;
  final int? storeId;
  final String transactionType;
  final String paymentMethod;
  final String amount;
  final String currencyCode;
  final String status;
  final String? transactionReference;
  final String description;
  final String createdAt;
  final String updatedAt;

  AdWalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    this.orderId,
    this.storeId,
    required this.transactionType,
    required this.paymentMethod,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.transactionReference,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdWalletTransaction.fromJson(Map<String, dynamic> json) {
    return AdWalletTransaction(
      id: JsonParser.intValue(json['id']),
      walletId: JsonParser.intValue(json['wallet_id']),
      userId: JsonParser.intValue(json['user_id']),
      orderId: json['order_id'] != null
          ? JsonParser.intValue(json['order_id'])
          : null,
      storeId: json['store_id'] != null
          ? JsonParser.intValue(json['store_id'])
          : null,
      transactionType: JsonParser.string(json['transaction_type'] ?? ''),
      paymentMethod: JsonParser.string(json['payment_method'] ?? ''),
      amount: JsonParser.string(json['amount'] ?? '0.00'),
      currencyCode: JsonParser.string(json['currency_code'] ?? ''),
      status: JsonParser.string(json['status'] ?? ''),
      transactionReference: json['transaction_reference'] as String?,
      description: JsonParser.string(json['description'] ?? ''),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }
}
