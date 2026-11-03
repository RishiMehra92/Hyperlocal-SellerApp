import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../../model/campaign_wallet_model.dart';
import '../../repo/campaign_repo.dart';

part 'ad_wallet_transactions_event.dart';
part 'ad_wallet_transactions_state.dart';

class AdWalletTransactionsBloc
    extends Bloc<AdWalletTransactionsEvent, AdWalletTransactionsState> {
  final CampaignRepository _repo;
  late final PaginationController<AdWalletTransaction> _paginationController;
  String? _currentTransactionType;
  String? _currentStatus;

  AdWalletTransactionsBloc(this._repo)
    : super(const PaginatedState<AdWalletTransaction>()) {
    _paginationController = PaginationController<AdWalletTransaction>(
      fetcher: _fetchTransactions,
      emit: (state) => add(_UpdateTransactionsState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadTransactionsInitial>((event, emit) async {
      _currentTransactionType = event.transactionType;
      _currentStatus = event.status;
      await _paginationController.loadInitial();
    });

    on<FilterTransactions>((event, emit) async {
      _currentTransactionType = event.transactionType;
      _currentStatus = event.status;
      await _paginationController.loadInitial();
    });

    on<LoadMoreTransactions>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshTransactions>((event, emit) async {
      await _paginationController.refresh(state);
    });

    on<TransactionsReset>((event, emit) async {
      _currentTransactionType = null;
      _currentStatus = null;
      emit(const PaginatedState<AdWalletTransaction>());
      _paginationController.reset();
    });

    on<_UpdateTransactionsState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<AdWalletTransaction>> _fetchTransactions(
    int page,
    int perPage,
  ) async {
    try {
      final response = await _repo.fetchAdWalletTransactions(
        page: page,
        perPage: perPage,
        transactionType: _currentTransactionType,
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
