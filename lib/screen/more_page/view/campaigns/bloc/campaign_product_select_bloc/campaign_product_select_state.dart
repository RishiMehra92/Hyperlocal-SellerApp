part of 'campaign_product_select_bloc.dart';

class CampaignProductSelectState extends PaginatedState<CampaignProduct> {
  const CampaignProductSelectState({
    super.items,
    super.hasMore,
    super.isInitialLoading,
    super.isPaginating,
    super.isRefreshing,
    super.error,
    super.currentPage,
    super.total,
  });

  @override
  CampaignProductSelectState copyWith({
    List<CampaignProduct>? items,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isPaginating,
    bool? isRefreshing,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
  }) {
    return CampaignProductSelectState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}
