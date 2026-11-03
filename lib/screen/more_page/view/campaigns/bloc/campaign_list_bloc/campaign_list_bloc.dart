import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../../model/campaign_model.dart';
import '../../repo/campaign_repo.dart';

part 'campaign_list_event.dart';
part 'campaign_list_state.dart';

class CampaignListBloc extends Bloc<CampaignListEvent, CampaignListState> {
  final CampaignRepository _repo;
  late final PaginationController<CampaignData> _paginationController;
  String? _currentSearch;
  String? _currentStatus;

  CampaignListBloc(this._repo) : super(const PaginatedState<CampaignData>()) {
    _paginationController = PaginationController<CampaignData>(
      fetcher: _fetchCampaigns,
      emit: (state) => add(_UpdateCampaignListState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadCampaignsInitial>((event, emit) async {
      _currentSearch = event.search;
      _currentStatus = event.status;
      await _paginationController.loadInitial();
    });

    on<SearchCampaigns>((event, emit) async {
      _currentSearch = event.search;
      await _paginationController.loadInitial();
    });

    on<FilterCampaignsByStatus>((event, emit) async {
      _currentStatus = event.status;
      await _paginationController.loadInitial();
    });

    on<LoadMoreCampaigns>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshCampaigns>((event, emit) async {
      await _paginationController.refresh(state);
    });

    on<CampaignListReset>((event, emit) async {
      _currentSearch = null;
      _currentStatus = null;
      emit(const PaginatedState<CampaignData>());
      _paginationController.reset();
    });

    on<_UpdateCampaignListState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<CampaignData>> _fetchCampaigns(
    int page,
    int perPage,
  ) async {
    try {
      final response = await _repo.fetchCampaigns(
        page: page,
        perPage: perPage,
        search: _currentSearch,
        status: _currentStatus,
      );
      final items = response?.data ?? [];
      return PaginationResponse(
        items: items,
        total: response?.total,
        currentPage: page,
      );
    } catch (e) {
      rethrow;
    }
  }
}
