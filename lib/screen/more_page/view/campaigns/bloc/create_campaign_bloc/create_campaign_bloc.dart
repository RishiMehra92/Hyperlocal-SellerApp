import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/campaign_model.dart';
import '../../repo/campaign_repo.dart';

part 'create_campaign_event.dart';
part 'create_campaign_state.dart';

class CreateCampaignBloc
    extends Bloc<CreateCampaignEvent, CreateCampaignState> {
  final CampaignRepository _repo;

  CreateCampaignBloc(this._repo) : super(const CreateCampaignState()) {
    on<FetchCampaignConfig>(_onFetchConfig);
    on<SubmitCampaign>(_onSubmitCampaign);
    on<PauseCampaign>(_onPauseCampaign);
    on<ResumeCampaign>(_onResumeCampaign);
    on<ClearCampaignAction>(_onClearAction);
    on<ResetCreateCampaign>((event, emit) => emit(const CreateCampaignState()));
  }

  Future<void> _onFetchConfig(
    FetchCampaignConfig event,
    Emitter<CreateCampaignState> emit,
  ) async {
    emit(state.copyWith(configStatus: CampaignConfigStatus.loading));
    try {
      final config = await _repo.fetchCampaignConfig();
      if (config != null) {
        emit(
          state.copyWith(
            configStatus: CampaignConfigStatus.success,
            config: config,
          ),
        );
      } else {
        emit(
          state.copyWith(
            configStatus: CampaignConfigStatus.failure,
            error: 'Failed to fetch campaign config',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          configStatus: CampaignConfigStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitCampaign(
    SubmitCampaign event,
    Emitter<CreateCampaignState> emit,
  ) async {
    emit(state.copyWith(submitStatus: CampaignSubmitStatus.submitting));
    try {
      final response = await _repo.createCampaign(
        productId: event.productId,
        budget: event.budget,
      );
      if (response['success'] == true) {
        final campaignData = response['data'] != null
            ? CampaignData.fromJson(response['data'] as Map<String, dynamic>)
            : null;
        emit(
          state.copyWith(
            submitStatus: CampaignSubmitStatus.success,
            createdCampaign: campaignData,
            actionMessage:
                response['message'] ?? 'Campaign submitted for approval',
          ),
        );
      } else {
        emit(
          state.copyWith(
            submitStatus: CampaignSubmitStatus.failure,
            error: response['message'] ?? 'Failed to create campaign',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CampaignSubmitStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPauseCampaign(
    PauseCampaign event,
    Emitter<CreateCampaignState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CampaignActionStatus.loading));
    try {
      final response = await _repo.pauseCampaign(event.campaignId);
      if (response['success'] == true) {
        final updatedCampaign = response['data'] != null
            ? CampaignData.fromJson(response['data'] as Map<String, dynamic>)
            : null;
        emit(
          state.copyWith(
            actionStatus: CampaignActionStatus.success,
            updatedCampaign: updatedCampaign,
            actionMessage: response['message'] ?? 'Campaign paused',
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionStatus: CampaignActionStatus.failure,
            error: response['message'] ?? 'Failed to pause campaign',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: CampaignActionStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onResumeCampaign(
    ResumeCampaign event,
    Emitter<CreateCampaignState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CampaignActionStatus.loading));
    try {
      final response = await _repo.resumeCampaign(event.campaignId);
      if (response['success'] == true) {
        final updatedCampaign = response['data'] != null
            ? CampaignData.fromJson(response['data'] as Map<String, dynamic>)
            : null;
        emit(
          state.copyWith(
            actionStatus: CampaignActionStatus.success,
            updatedCampaign: updatedCampaign,
            actionMessage: response['message'] ?? 'Campaign resumed',
          ),
        );
      } else {
        emit(
          state.copyWith(
            actionStatus: CampaignActionStatus.failure,
            error: response['message'] ?? 'Failed to resume campaign',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          actionStatus: CampaignActionStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void _onClearAction(
    ClearCampaignAction event,
    Emitter<CreateCampaignState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: CampaignSubmitStatus.initial,
        actionStatus: CampaignActionStatus.initial,
        clearOperation: true,
      ),
    );
  }
}
