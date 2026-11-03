import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import '../model/order_return_model.dart';
import '../model/return_filters.dart';
import '../repo/order_returns_repo.dart';
import 'returns_state.dart';

class ReturnsCubit extends Cubit<ReturnsState> {
  final OrderReturnsRepo _repo;
  PaginationController<OrderReturn>? _pagination;
  PaginationController<OrderReturn>? _loadingMoreController;
  int _generation = 0;
  ReturnsCubit(this._repo) : super(const ReturnsState());

  Future<void> initialize() => Future.wait([load(), loadEnums()]);

  Future<void> loadEnums() async {
    if (state.enumsLoading) return;
    emit(state.copyWith(enumsLoading: true, clearEnumsError: true));
    try {
      final enums = await _repo.getEnums();
      if (!isClosed) {
        emit(
          state.copyWith(
            enums: enums,
            enumsLoading: false,
            clearEnumsError: true,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(enumsLoading: false, enumsError: e.toString()));
      }
    }
  }

  Future<void> load({ReturnFilters? filters, bool silent = false}) async {
    final generation = ++_generation;
    final query = filters ?? state.filters;
    emit(
      state.copyWith(
        filters: query,
        clearError: true,
        isInitialLoading: !silent,
        isRefreshing: silent,
        isPaginating: false,
        items: silent ? state.items : [],
        insights: silent ? state.insights : {},
      ),
    );
    final controller = PaginationController<OrderReturn>(
      perPage: 15,
      getState: () => state,
      fetcher: (page, perPage) async {
        final result = await _repo.getReturns(
          page: page,
          perPage: perPage,
          filters: query,
        );
        if (!isClosed && generation == _generation) {
          emit(state.copyWith(insights: result.insights));
        }
        return PaginationResponse(
          items: result.items,
          total: result.total,
          currentPage: result.currentPage,
          hasMore: result.currentPage < result.lastPage,
        );
      },
      emit: (data) {
        if (isClosed || generation != _generation) return;
        emit(
          state.copyWith(
            items: data.items,
            isInitialLoading: data.isInitialLoading,
            isRefreshing: data.isRefreshing,
            isPaginating: data.isPaginating,
            hasMore: data.hasMore,
            error: data.error,
            clearError: data.error == null,
            currentPage: data.currentPage,
            total: data.total,
          ),
        );
      },
    );
    _pagination = controller;
    await controller.loadInitial(silent: silent, currentState: state);
  }

  Future<void> search(String query) =>
      load(filters: state.filters.withSearch(query));
  Future<void> selectGroup(String? group) =>
      load(filters: state.filters.withGroup(group));
  Future<void> refresh() => load(silent: true);
  Future<void> loadMore() async {
    final controller = _pagination;
    if (controller == null ||
        state.error != null ||
        _loadingMoreController == controller) {
      return;
    }
    // The shared controller checks connectivity asynchronously before setting
    // its loading flag. Guard that gap against repeated scroll events.
    _loadingMoreController = controller;
    try {
      await controller.loadNextPage(state);
    } finally {
      if (_loadingMoreController == controller) {
        _loadingMoreController = null;
      }
    }
  }
}
