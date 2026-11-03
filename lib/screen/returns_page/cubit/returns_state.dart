import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import '../model/order_return_model.dart';
import '../model/return_filters.dart';

class ReturnsState extends PaginatedState<OrderReturn> {
  final ReturnFilters filters;
  final Map<String, int> insights;
  final ReturnEnums enums;
  final bool enumsLoading;
  final String? enumsError;
  const ReturnsState({
    super.items,
    super.isInitialLoading,
    super.isRefreshing,
    super.isPaginating,
    super.hasMore,
    super.error,
    super.currentPage,
    super.total,
    this.filters = const ReturnFilters(),
    this.insights = const {},
    this.enums = const ReturnEnums(),
    this.enumsLoading = false,
    this.enumsError,
  });

  @override
  ReturnsState copyWith({
    List<OrderReturn>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isPaginating,
    bool? hasMore,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
    bool clearError = false,
    ReturnFilters? filters,
    Map<String, int>? insights,
    ReturnEnums? enums,
    bool? enumsLoading,
    String? enumsError,
    bool clearEnumsError = false,
  }) => ReturnsState(
    items: items ?? this.items,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isPaginating: isPaginating ?? this.isPaginating,
    hasMore: hasMore ?? this.hasMore,
    error: clearError || clearOperation ? null : (error ?? this.error),
    currentPage: currentPage ?? this.currentPage,
    total: total ?? this.total,
    filters: filters ?? this.filters,
    insights: insights ?? this.insights,
    enums: enums ?? this.enums,
    enumsLoading: enumsLoading ?? this.enumsLoading,
    enumsError: clearEnumsError ? null : (enumsError ?? this.enumsError),
  );

  @override
  List<Object?> get props => [
    ...super.props,
    filters,
    insights,
    enums,
    enumsLoading,
    enumsError,
  ];
}
