import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/model/campaign_product_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/repo/campaign_repo.dart';

part 'campaign_product_select_event.dart';
part 'campaign_product_select_state.dart';

class CampaignProductSelectBloc
    extends Bloc<CampaignProductSelectEvent, CampaignProductSelectState> {
  final CampaignRepository _repo;
  late final PaginationController<CampaignProduct> _paginationController;

  String? _searchQuery;

  CampaignProductSelectBloc(this._repo)
    : super(const CampaignProductSelectState()) {
    _paginationController = PaginationController<CampaignProduct>(
      fetcher: _fetchProducts,
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

    on<LoadCampaignProductsInitial>(_onLoadInitial);
    on<LoadMoreCampaignProducts>(_onLoadMore);
    on<RefreshCampaignProducts>(_onRefresh);
    on<SearchCampaignProducts>(_onSearch);
    on<CampaignProductsReset>(_onReset);
  }

  Future<PaginationResponse<CampaignProduct>> _fetchProducts(
    int page,
    int perPage,
  ) async {
    final response = await _repo.fetchCampaignProducts(
      page: page,
      perPage: perPage,
      search: _searchQuery,
    );

    return PaginationResponse(
      items: response.data!.data!,
      total: response.data!.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadInitial(
    LoadCampaignProductsInitial event,
    Emitter<CampaignProductSelectState> emit,
  ) async {
    _searchQuery = event.search;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onLoadMore(
    LoadMoreCampaignProducts event,
    Emitter<CampaignProductSelectState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefresh(
    RefreshCampaignProducts event,
    Emitter<CampaignProductSelectState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onSearch(
    SearchCampaignProducts event,
    Emitter<CampaignProductSelectState> emit,
  ) async {
    _searchQuery = event.query.isEmpty ? null : event.query;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onReset(
    CampaignProductsReset event,
    Emitter<CampaignProductSelectState> emit,
  ) async {
    _searchQuery = null;
    emit(const CampaignProductSelectState());
    _paginationController.reset();
  }
}
