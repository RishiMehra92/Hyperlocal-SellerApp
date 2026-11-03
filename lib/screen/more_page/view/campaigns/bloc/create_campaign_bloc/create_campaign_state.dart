part of 'create_campaign_bloc.dart';

enum CampaignConfigStatus { initial, loading, success, failure }

enum CampaignSubmitStatus { initial, submitting, success, failure }

enum CampaignActionStatus { initial, loading, success, failure }

class CreateCampaignState extends Equatable {
  final CampaignConfigModel? config;
  final CampaignConfigStatus configStatus;
  final CampaignSubmitStatus submitStatus;
  final CampaignActionStatus actionStatus;
  final CampaignData? createdCampaign;
  final CampaignData? updatedCampaign;
  final String? error;
  final String? actionMessage;

  const CreateCampaignState({
    this.config,
    this.configStatus = CampaignConfigStatus.initial,
    this.submitStatus = CampaignSubmitStatus.initial,
    this.actionStatus = CampaignActionStatus.initial,
    this.createdCampaign,
    this.updatedCampaign,
    this.error,
    this.actionMessage,
  });

  CreateCampaignState copyWith({
    CampaignConfigModel? config,
    CampaignConfigStatus? configStatus,
    CampaignSubmitStatus? submitStatus,
    CampaignActionStatus? actionStatus,
    CampaignData? createdCampaign,
    CampaignData? updatedCampaign,
    String? error,
    String? actionMessage,
    bool clearOperation = false,
  }) {
    return CreateCampaignState(
      config: config ?? this.config,
      configStatus: configStatus ?? this.configStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      createdCampaign: createdCampaign ?? this.createdCampaign,
      updatedCampaign: updatedCampaign ?? this.updatedCampaign,
      error: clearOperation ? null : (error ?? this.error),
      actionMessage: clearOperation
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
    config,
    configStatus,
    submitStatus,
    actionStatus,
    createdCampaign,
    updatedCampaign,
    error,
    actionMessage,
  ];
}
