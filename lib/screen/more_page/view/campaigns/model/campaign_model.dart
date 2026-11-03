import 'package:hyper_local_seller/service/json_parser.dart';

const String campaignModelName = 'campaign_model';

/// Response model for GET /ad-campaigns (paginated list)
class CampaignListModel {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<CampaignData> data;

  CampaignListModel({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory CampaignListModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return CampaignListModel(
      success: JsonParser.boolValue(json['success'] ?? true),
      message: JsonParser.string(json['message'] ?? ''),
      currentPage: JsonParser.intValue(dataMap?['current_page'] ?? 1),
      lastPage: JsonParser.intValue(dataMap?['last_page'] ?? 1),
      perPage: JsonParser.intValue(dataMap?['per_page'] ?? 15),
      total: JsonParser.intValue(dataMap?['total'] ?? 0),
      data: (dataMap?['data'] as List? ?? [])
          .map((e) => CampaignData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Single campaign data model
class CampaignData {
  final int id;
  final int productId;
  final String productTitle;
  final String productImage;
  final double budget;
  final double spent;
  final double remainingBudget;
  final double spendProgress;
  final double cpcRateSnapshot;
  final List<String> placements;
  final String status;
  final String statusLabel;
  final String? rejectionReason;
  final String? forceStopReason;
  final String? forceStoppedAt;
  final int totalClicks;
  final int totalImpressions;
  final double totalSpentStats;
  final String createdAt;
  final String updatedAt;

  CampaignData({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.budget,
    required this.spent,
    required this.remainingBudget,
    required this.spendProgress,
    required this.cpcRateSnapshot,
    required this.placements,
    required this.status,
    required this.statusLabel,
    this.rejectionReason,
    this.forceStopReason,
    this.forceStoppedAt,
    required this.totalClicks,
    required this.totalImpressions,
    required this.totalSpentStats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CampaignData.fromJson(Map<String, dynamic> json) {
    return CampaignData(
      id: JsonParser.intValue(json['id']),
      productId: JsonParser.intValue(json['product_id']),
      productTitle: JsonParser.string(json['product_title'] ?? ''),
      productImage: JsonParser.string(json['product_image'] ?? ''),
      budget: JsonParser.doubleValue(json['budget']),
      spent: JsonParser.doubleValue(json['spent']),
      remainingBudget: JsonParser.doubleValue(json['remaining_budget']),
      spendProgress: JsonParser.doubleValue(json['spend_progress']),
      cpcRateSnapshot: JsonParser.doubleValue(json['cpc_rate_snapshot']),
      placements: JsonParser.list<String>(
        json['placements'],
        (e) => e.toString(),
      ),
      status: JsonParser.string(json['status'] ?? ''),
      statusLabel: JsonParser.string(json['status_label'] ?? ''),
      rejectionReason: json['rejection_reason'] as String?,
      forceStopReason: json['force_stop_reason'] as String?,
      forceStoppedAt: json['force_stopped_at'] as String?,
      totalClicks: JsonParser.intValue(json['total_clicks']),
      totalImpressions: JsonParser.intValue(json['total_impressions']),
      totalSpentStats: JsonParser.doubleValue(json['total_spent_stats']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }
}

/// Response model for campaign config (GET /ad-campaigns/config)
class CampaignConfigModel {
  final bool featureEnabled;
  final double walletBalance;
  final double cpcRate;
  final double minBudget;
  final double maxBudget;
  final int impressionMultiplierMin;
  final int impressionMultiplierMax;

  CampaignConfigModel({
    required this.featureEnabled,
    required this.walletBalance,
    required this.cpcRate,
    required this.minBudget,
    required this.maxBudget,
    required this.impressionMultiplierMin,
    required this.impressionMultiplierMax,
  });

  factory CampaignConfigModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>? ?? json;
    return CampaignConfigModel(
      featureEnabled: JsonParser.boolValue(dataMap['feature_enabled'] ?? false),
      walletBalance: JsonParser.doubleValue(dataMap['wallet_balance']),
      cpcRate: JsonParser.doubleValue(dataMap['cpc_rate']),
      minBudget: JsonParser.doubleValue(dataMap['min_budget']),
      maxBudget: JsonParser.doubleValue(dataMap['max_budget']),
      impressionMultiplierMin: JsonParser.intValue(
        dataMap['impression_multiplier_min'],
      ),
      impressionMultiplierMax: JsonParser.intValue(
        dataMap['impression_multiplier_max'],
      ),
    );
  }
}
