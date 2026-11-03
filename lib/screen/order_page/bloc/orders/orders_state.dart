part of 'orders_bloc.dart';

class OrdersState extends PaginatedState<SellerOrderItem> {
  final String? paymentType;
  final String? range;
  final String? sortBy;
  final String? sortDir;
  final String? status;
  final int? storeId;
  final String? deliveryType;

  // Scheduled orders state
  final List<SellerOrderItem> scheduledItems;
  final bool hasMoreScheduled;
  final bool isInitialLoadingScheduled;
  final bool isPaginatingScheduled;
  final bool isRefreshingScheduled;
  final String? errorScheduled;
  final int currentPageScheduled;
  final int totalScheduled;

  const OrdersState({
    super.items,
    super.hasMore,
    super.isInitialLoading,
    super.isPaginating, // Replaced isLoadingMore with isPaginating
    super.isRefreshing,
    super.error,
    super.currentPage,
    super.total,
    this.paymentType,
    this.range,
    this.sortBy,
    this.sortDir,
    this.status,
    this.storeId,
    this.deliveryType,
    this.scheduledItems = const [],
    this.hasMoreScheduled = false,
    this.isInitialLoadingScheduled = false,
    this.isPaginatingScheduled = false,
    this.isRefreshingScheduled = false,
    this.errorScheduled,
    this.currentPageScheduled = 1,
    this.totalScheduled = 0,
  });

  @override
  OrdersState copyWith({
    List<SellerOrderItem>? items,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isPaginating, // Replaced isLoadingMore
    bool? isRefreshing,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    bool overrideFilters = false,
    int? storeId,
    String? deliveryType,
    // Scheduled parameters
    List<SellerOrderItem>? scheduledItems,
    bool? hasMoreScheduled,
    bool? isInitialLoadingScheduled,
    bool? isPaginatingScheduled,
    bool? isRefreshingScheduled,
    String? errorScheduled,
    int? currentPageScheduled,
    int? totalScheduled,
  }) {
    return OrdersState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      paymentType: overrideFilters
          ? paymentType
          : (paymentType ?? this.paymentType),
      range: overrideFilters ? range : (range ?? this.range),
      sortBy: overrideFilters ? sortBy : (sortBy ?? this.sortBy),
      sortDir: overrideFilters ? sortDir : (sortDir ?? this.sortDir),
      status: overrideFilters ? status : (status ?? this.status),
      storeId: overrideFilters ? storeId : (storeId ?? this.storeId),
      deliveryType: overrideFilters
          ? deliveryType
          : (deliveryType ?? this.deliveryType),
      scheduledItems: scheduledItems ?? this.scheduledItems,
      hasMoreScheduled: hasMoreScheduled ?? this.hasMoreScheduled,
      isInitialLoadingScheduled:
          isInitialLoadingScheduled ?? this.isInitialLoadingScheduled,
      isPaginatingScheduled:
          isPaginatingScheduled ?? this.isPaginatingScheduled,
      isRefreshingScheduled:
          isRefreshingScheduled ?? this.isRefreshingScheduled,
      errorScheduled: clearOperation
          ? null
          : (errorScheduled ?? this.errorScheduled),
      currentPageScheduled: currentPageScheduled ?? this.currentPageScheduled,
      totalScheduled: totalScheduled ?? this.totalScheduled,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    paymentType,
    range,
    sortBy,
    sortDir,
    status,
    storeId,
    deliveryType,
    scheduledItems,
    hasMoreScheduled,
    isInitialLoadingScheduled,
    isPaginatingScheduled,
    isRefreshingScheduled,
    errorScheduled,
    currentPageScheduled,
    totalScheduled,
  ];
}
