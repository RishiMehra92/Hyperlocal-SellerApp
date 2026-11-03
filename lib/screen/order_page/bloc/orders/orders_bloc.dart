import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepo _repo;
  late final PaginationController<SellerOrderItem> _paginationController;
  late final PaginationController<SellerOrderItem>
  _scheduledPaginationController;

  String? _searchQuery;

  OrdersBloc(this._repo) : super(const OrdersState()) {
    _paginationController = PaginationController<SellerOrderItem>(
      fetcher: _fetchOrders,
      // ignore: invalid_use_of_visible_for_testing_member
      emit: (paginatedState) => emit(
        state.copyWith(
          items: paginatedState.items,
          hasMore: paginatedState.hasMore,
          isInitialLoading: paginatedState.isInitialLoading,
          isRefreshing: paginatedState.isRefreshing,
          isPaginating: paginatedState.isPaginating,
          error: paginatedState.error,
          currentPage: paginatedState.currentPage,
          total: paginatedState.total,
        ),
      ),
      perPage: GlobalKeys.perPage,
    );

    _scheduledPaginationController = PaginationController<SellerOrderItem>(
      fetcher: _fetchScheduledOrders,
      // ignore: invalid_use_of_visible_for_testing_member
      emit: (paginatedState) => emit(
        state.copyWith(
          scheduledItems: paginatedState.items,
          hasMoreScheduled: paginatedState.hasMore,
          isInitialLoadingScheduled: paginatedState.isInitialLoading,
          isRefreshingScheduled: paginatedState.isRefreshing,
          isPaginatingScheduled: paginatedState.isPaginating,
          errorScheduled: paginatedState.error,
          currentPageScheduled: paginatedState.currentPage,
          totalScheduled: paginatedState.total,
        ),
      ),
      perPage: GlobalKeys.perPage,
    );

    on<LoadOrdersInitial>(_onLoadOrdersInitial);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<SearchOrders>(_onSearchOrders);
    on<ApplyFilter>(_onApplyFilter);
    on<ClearFilters>(_onClearFilters);
    on<OrdersReset>(_onOrdersReset);
    on<UpdateOrderListItemStatus>(_onUpdateOrderListItemStatus);
    on<LocalUpdateOrderStatus>(_onLocalUpdateOrderStatus);
    on<LoadScheduledOrdersInitial>(_onLoadScheduledOrdersInitial);
    on<LoadMoreScheduledOrders>(_onLoadMoreScheduledOrders);
    on<RefreshScheduledOrders>(_onRefreshScheduledOrders);
    on<BulkUpdateOrderStatus>(_onBulkUpdateOrderStatus);
  }

  Future<PaginationResponse<SellerOrderItem>> _fetchOrders(
    int page,
    int perPage,
  ) async {
    final response = await _repo.getOrders(
      page: page,
      perPage: perPage,
      search: _searchQuery,
      paymentType: state.paymentType,
      range: state.range,
      sortBy: state.sortBy,
      sortDir: state.sortDir,
      status: state.status,
      storeId: state.storeId,
      orderType: state.deliveryType,
    );
    final ordersResponse = OrdersResponse.fromJson(response);

    return PaginationResponse(
      items: ordersResponse.data?.items ?? [],
      total: ordersResponse.data?.total,
      currentPage: page,
    );
  }

  Future<PaginationResponse<SellerOrderItem>> _fetchScheduledOrders(
    int page,
    int perPage,
  ) async {
    final response = await _repo.getScheduledOrders(
      page: page,
      perPage: perPage,
      search: _searchQuery,
      paymentType: state.paymentType,
      range: state.range,
      sortBy: state.sortBy,
      sortDir: state.sortDir,
      status: state.status,
      storeId: state.storeId,
      orderType: state.deliveryType,
    );
    final ordersResponse = OrdersResponse.fromJson(response);

    return PaginationResponse(
      items: ordersResponse.data?.items ?? [],
      total: ordersResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadOrdersInitial(
    LoadOrdersInitial event,
    Emitter<OrdersState> emit,
  ) async {
    _searchQuery = event.search;
    final storeId = event.storeId ?? HiveStorage.selectedStoreId;
    emit(state.copyWith(storeId: storeId, overrideFilters: true));
    await Future.wait([
      _paginationController.loadInitial(currentState: state),
      _scheduledPaginationController.loadInitial(currentState: state),
    ]);
  }

  Future<void> _onLoadScheduledOrdersInitial(
    LoadScheduledOrdersInitial event,
    Emitter<OrdersState> emit,
  ) async {
    _searchQuery = event.search;
    final storeId = event.storeId ?? HiveStorage.selectedStoreId;
    emit(state.copyWith(storeId: storeId, overrideFilters: true));
    await _scheduledPaginationController.loadInitial(currentState: state);
  }

  Future<void> _onSearchOrders(
    SearchOrders event,
    Emitter<OrdersState> emit,
  ) async {
    _searchQuery = event.query;
    await Future.wait([
      _paginationController.loadInitial(),
      _scheduledPaginationController.loadInitial(),
    ]);
  }

  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        paymentType: event.paymentType,
        range: event.range,
        sortBy: event.sortBy,
        sortDir: event.sortDir,
        status: event.status,
        deliveryType: event.deliveryType,
        overrideFilters: true,
      ),
    );

    await Future.wait([
      _paginationController.loadInitial(),
      _scheduledPaginationController.loadInitial(),
    ]);
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      state.copyWith(
        paymentType: null,
        range: null,
        sortBy: null,
        sortDir: null,
        status: null,
        deliveryType: null,
        overrideFilters: true,
      ),
    );
    await Future.wait([
      _paginationController.loadInitial(),
      _scheduledPaginationController.loadInitial(),
    ]);
  }

  Future<void> _onOrdersReset(
    OrdersReset event,
    Emitter<OrdersState> emit,
  ) async {
    _searchQuery = null;
    emit(const OrdersState());
    _paginationController.reset();
    _scheduledPaginationController.reset();
  }

  Future<void> _onUpdateOrderListItemStatus(
    UpdateOrderListItemStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _repo.updateOrderStatus(event.orderId, event.status);
      add(RefreshOrders());
    } catch (e) {
      // Handle error
    }
  }

  void _onLocalUpdateOrderStatus(
    LocalUpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) {
    final newItems = state.items.map((item) {
      if (item.orderItemId == event.orderId) {
        return item.copyWith(status: event.status);
      }
      return item;
    }).toList();

    final newScheduledItems = state.scheduledItems.map((item) {
      if (item.orderItemId == event.orderId) {
        return item.copyWith(status: event.status);
      }
      return item;
    }).toList();

    emit(state.copyWith(
      items: newItems,
      scheduledItems: newScheduledItems,
    ));
  }

  Future<void> _onLoadMoreOrders(
    LoadMoreOrders event,
    Emitter<OrdersState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onLoadMoreScheduledOrders(
    LoadMoreScheduledOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final tempState = PaginatedState<SellerOrderItem>(
      items: state.scheduledItems,
      hasMore: state.hasMoreScheduled,
      isInitialLoading: state.isInitialLoadingScheduled,
      isRefreshing: state.isRefreshingScheduled,
      isPaginating: state.isPaginatingScheduled,
      error: state.errorScheduled,
      currentPage: state.currentPageScheduled,
      total: state.totalScheduled,
    );
    await _scheduledPaginationController.loadNextPage(tempState);
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final storeId =
        event.storeId ?? state.storeId ?? HiveStorage.selectedStoreId;
    final bool shouldOverrideFilters =
        event.storeId != null && event.storeId != state.storeId;
    emit(
      state.copyWith(storeId: storeId, overrideFilters: shouldOverrideFilters),
    );
    await Future.wait([
      _paginationController.refresh(state),
      _scheduledPaginationController.refresh(
        PaginatedState<SellerOrderItem>(
          items: state.scheduledItems,
          hasMore: state.hasMoreScheduled,
          isInitialLoading: state.isInitialLoadingScheduled,
          isRefreshing: state.isRefreshingScheduled,
          isPaginating: state.isPaginatingScheduled,
          error: state.errorScheduled,
          currentPage: state.currentPageScheduled,
          total: state.totalScheduled,
        ),
      ),
    ]);
  }

  Future<void> _onRefreshScheduledOrders(
    RefreshScheduledOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final storeId =
        event.storeId ?? state.storeId ?? HiveStorage.selectedStoreId;
    final bool shouldOverrideFilters =
        event.storeId != null && event.storeId != state.storeId;
    emit(
      state.copyWith(storeId: storeId, overrideFilters: shouldOverrideFilters),
    );
    await _scheduledPaginationController.refresh(
      PaginatedState<SellerOrderItem>(
        items: state.scheduledItems,
        hasMore: state.hasMoreScheduled,
        isInitialLoading: state.isInitialLoadingScheduled,
        isRefreshing: state.isRefreshingScheduled,
        isPaginating: state.isPaginatingScheduled,
        error: state.errorScheduled,
        currentPage: state.currentPageScheduled,
        total: state.totalScheduled,
      ),
    );
  }
  Future<void> _onBulkUpdateOrderStatus(
    BulkUpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _repo.bulkUpdateStatus(event.status, event.orderItemIds);
      add(RefreshOrders());
      add(RefreshScheduledOrders());
    } catch (e) {
      // Handle error
    }
  }
}
