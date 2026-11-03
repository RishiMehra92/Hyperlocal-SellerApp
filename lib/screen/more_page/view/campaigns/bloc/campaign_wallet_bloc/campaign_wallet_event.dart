part of 'campaign_wallet_bloc.dart';

abstract class CampaignWalletEvent extends Equatable {
  const CampaignWalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdWallet extends CampaignWalletEvent {}

class TopupFromEarnings extends CampaignWalletEvent {
  final double amount;
  final String? description;

  const TopupFromEarnings({required this.amount, this.description});

  @override
  List<Object?> get props => [amount, description];
}

class TopUpViaGateway extends CampaignWalletEvent {
  final double amount;
  final String paymentMethod;
  final String? description;

  const TopUpViaGateway({
    required this.amount,
    required this.paymentMethod,
    this.description,
  });

  @override
  List<Object?> get props => [amount, paymentMethod, description];
}

class ClearTopupState extends CampaignWalletEvent {}

class StartTopupPolling extends CampaignWalletEvent {}

class StopTopupPolling extends CampaignWalletEvent {}

class CheckTopupStatus extends CampaignWalletEvent {
  const CheckTopupStatus();
}

class ResetCampaignWallet extends CampaignWalletEvent {}
