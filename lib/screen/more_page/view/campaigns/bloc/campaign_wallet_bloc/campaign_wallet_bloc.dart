import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/campaign_wallet_model.dart';
import '../../repo/campaign_repo.dart';

part 'campaign_wallet_event.dart';
part 'campaign_wallet_state.dart';

class CampaignWalletBloc
    extends Bloc<CampaignWalletEvent, CampaignWalletState> {
  final CampaignRepository _repo;
  bool _isPolling = false;
  String? _balanceBeforeTopup;

  CampaignWalletBloc(this._repo) : super(const CampaignWalletState()) {
    on<FetchAdWallet>(_onFetchAdWallet);
    on<TopupFromEarnings>(_onTopupFromEarnings);
    on<TopUpViaGateway>(_onTopupViaGateway);
    on<ClearTopupState>(_onClearTopupState);
    on<StartTopupPolling>(_onStartTopupPolling);
    on<StopTopupPolling>(_onStopTopupPolling);
    on<CheckTopupStatus>(_onCheckTopupStatus);
    on<ResetCampaignWallet>((event, emit) {
      _isPolling = false;
      emit(const CampaignWalletState());
    });
  }

  Future<void> _onFetchAdWallet(
    FetchAdWallet event,
    Emitter<CampaignWalletState> emit,
  ) async {
    emit(state.copyWith(walletStatus: AdWalletStatus.loading));
    try {
      final response = await _repo.fetchAdWallet();
      if (response != null) {
        emit(
          state.copyWith(
            walletStatus: AdWalletStatus.success,
            walletData: response.wallet,
            featureEnabled: response.featureEnabled,
            minTopup: response.minTopup,
            currencySymbol: response.currencySymbol,
          ),
        );
      } else {
        emit(
          state.copyWith(
            walletStatus: AdWalletStatus.failure,
            error: 'Failed to fetch ad wallet',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          walletStatus: AdWalletStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTopupFromEarnings(
    TopupFromEarnings event,
    Emitter<CampaignWalletState> emit,
  ) async {
    emit(state.copyWith(topupStatus: TopupStatus.submitting));
    try {
      final response = await _repo.topupFromEarnings(
        amount: event.amount,
        description: event.description,
      );
      if (response != null) {
        emit(
          state.copyWith(
            topupStatus: TopupStatus.success,
            walletData: response.adWallet,
            topupMessage: 'Transferred to ad wallet successfully',
          ),
        );
      } else {
        emit(
          state.copyWith(
            topupStatus: TopupStatus.failure,
            error: 'Failed to transfer funds',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(topupStatus: TopupStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onTopupViaGateway(
    TopUpViaGateway event,
    Emitter<CampaignWalletState> emit,
  ) async {
    // Store balance before topup so polling can detect change
    _balanceBeforeTopup = state.walletData?.balance ?? '0.00';
    emit(state.copyWith(topupStatus: TopupStatus.submitting));
    try {
      if (event.paymentMethod == 'wallet') {
        final response = await _repo.topupFromEarnings(
          amount: event.amount,
          description: event.description,
        );
        if (response != null) {
          emit(
            state.copyWith(
              topupStatus: TopupStatus.success,
              walletData: response.adWallet,
              topupMessage: 'Transferred to ad wallet successfully',
            ),
          );
        } else {
          emit(
            state.copyWith(
              topupStatus: TopupStatus.failure,
              error: 'Failed to transfer funds',
            ),
          );
        }
        return;
      }

      final response = await _repo.topupViaGateway(
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        description: event.description,
      );
      if (response != null && response.paymentUrl != null) {
        emit(
          state.copyWith(
            topupStatus: TopupStatus.paymentPending,
            paymentUrl: response.paymentUrl,
            topupMessage: response.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            topupStatus: TopupStatus.failure,
            error: 'Failed to initiate payment',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(topupStatus: TopupStatus.failure, error: e.toString()),
      );
    }
  }

  void _onStartTopupPolling(
    StartTopupPolling event,
    Emitter<CampaignWalletState> emit,
  ) {
    _isPolling = true;
    add(const CheckTopupStatus());
  }

  void _onStopTopupPolling(
    StopTopupPolling event,
    Emitter<CampaignWalletState> emit,
  ) {
    _isPolling = false;
  }

  Future<void> _onCheckTopupStatus(
    CheckTopupStatus event,
    Emitter<CampaignWalletState> emit,
  ) async {
    if (!_isPolling) return;

    try {
      final response = await _repo.fetchAdWallet();
      if (response != null) {
        final newBalance = response.wallet?.balance ?? '0.00';
        if (newBalance != _balanceBeforeTopup) {
          // Balance changed — payment succeeded
          _isPolling = false;
          emit(
            state.copyWith(
              topupStatus: TopupStatus.success,
              walletData: response.wallet,
              topupMessage: 'Top up successful',
            ),
          );
          return;
        }
      }

      // Balance unchanged — wait and poll again
      await Future.delayed(const Duration(seconds: 5));
      if (!isClosed && _isPolling) {
        add(const CheckTopupStatus());
      }
    } catch (e) {
      // Transient error — retry
      await Future.delayed(const Duration(seconds: 10));
      if (!isClosed && _isPolling) {
        add(const CheckTopupStatus());
      }
    }
  }

  void _onClearTopupState(
    ClearTopupState event,
    Emitter<CampaignWalletState> emit,
  ) {
    _isPolling = false;
    emit(
      state.copyWith(
        topupStatus: TopupStatus.initial,
        topupMessage: null,
        paymentUrl: null,
        error: null,
      ),
    );
  }
}
