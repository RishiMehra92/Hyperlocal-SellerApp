part of 'campaign_wallet_bloc.dart';

enum AdWalletStatus { initial, loading, success, failure }

enum TopupStatus { initial, submitting, success, paymentPending, failure }

class CampaignWalletState extends Equatable {
  final AdWalletData? walletData;
  final bool featureEnabled;
  final double minTopup;
  final String currencySymbol;
  final AdWalletStatus walletStatus;
  final TopupStatus topupStatus;
  final String? paymentUrl;
  final String? error;
  final String? topupMessage;

  const CampaignWalletState({
    this.walletData,
    this.featureEnabled = false,
    this.minTopup = 0,
    this.currencySymbol = '',
    this.walletStatus = AdWalletStatus.initial,
    this.topupStatus = TopupStatus.initial,
    this.paymentUrl,
    this.error,
    this.topupMessage,
  });

  CampaignWalletState copyWith({
    AdWalletData? walletData,
    bool? featureEnabled,
    double? minTopup,
    String? currencySymbol,
    AdWalletStatus? walletStatus,
    TopupStatus? topupStatus,
    String? paymentUrl,
    String? error,
    String? topupMessage,
  }) {
    return CampaignWalletState(
      walletData: walletData ?? this.walletData,
      featureEnabled: featureEnabled ?? this.featureEnabled,
      minTopup: minTopup ?? this.minTopup,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      walletStatus: walletStatus ?? this.walletStatus,
      topupStatus: topupStatus ?? this.topupStatus,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      error: error ?? this.error,
      topupMessage: topupMessage ?? this.topupMessage,
    );
  }

  @override
  List<Object?> get props => [
    walletData,
    featureEnabled,
    minTopup,
    currencySymbol,
    walletStatus,
    topupStatus,
    paymentUrl,
    error,
    topupMessage,
  ];
}
