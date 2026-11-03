part of 'create_campaign_bloc.dart';

abstract class CreateCampaignEvent extends Equatable {
  const CreateCampaignEvent();

  @override
  List<Object?> get props => [];
}

class FetchCampaignConfig extends CreateCampaignEvent {}

class SubmitCampaign extends CreateCampaignEvent {
  final int productId;
  final double budget;

  const SubmitCampaign({required this.productId, required this.budget});

  @override
  List<Object?> get props => [productId, budget];
}

class PauseCampaign extends CreateCampaignEvent {
  final int campaignId;

  const PauseCampaign({required this.campaignId});

  @override
  List<Object?> get props => [campaignId];
}

class ResumeCampaign extends CreateCampaignEvent {
  final int campaignId;

  const ResumeCampaign({required this.campaignId});

  @override
  List<Object?> get props => [campaignId];
}

class ClearCampaignAction extends CreateCampaignEvent {}

class ResetCreateCampaign extends CreateCampaignEvent {}
