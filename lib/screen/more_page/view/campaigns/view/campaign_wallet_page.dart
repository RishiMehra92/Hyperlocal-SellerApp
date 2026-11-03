// ignore_for_file: deprecated_member_use

import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/payment_selection_bottom_sheet.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../../../../../config/app_permissions.dart';
import '../../../../../utils/permission_checker.dart';
import '../bloc/campaign_wallet_bloc/campaign_wallet_bloc.dart';
import '../bloc/ad_wallet_transactions_bloc/ad_wallet_transactions_bloc.dart';

class CampaignWalletPage extends StatefulWidget {
  const CampaignWalletPage({super.key});

  @override
  State<CampaignWalletPage> createState() => _CampaignWalletPageState();
}

class _CampaignWalletPageState extends State<CampaignWalletPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CampaignWalletBloc>().add(FetchAdWallet());
    context.read<AdWalletTransactionsBloc>().add(const LoadTransactionsInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll * 0.9)) {
      context.read<AdWalletTransactionsBloc>().add(LoadMoreTransactions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return BlocListener<CampaignWalletBloc, CampaignWalletState>(
      listener: (context, state) {
        if (state.topupStatus == TopupStatus.success) {
          showCustomSnackbar(context: context, message: state.topupMessage ?? 'Top up successful', showAtTop: true);
          context.read<CampaignWalletBloc>().add(ClearTopupState());
          context.read<AdWalletTransactionsBloc>().add(const LoadTransactionsInitial());
        } else if (state.topupStatus == TopupStatus.paymentPending && state.paymentUrl != null) {
          // Navigate to payment WebView
          context.pushNamed(AppRoutes.campaignPaymentWebView, extra: state.paymentUrl).then((_) {
            // Refresh wallet after returning from WebView
            // ignore: use_build_context_synchronously
            context.read<CampaignWalletBloc>().add(FetchAdWallet());
            // ignore: use_build_context_synchronously
            context.read<CampaignWalletBloc>().add(ClearTopupState());
            // ignore: use_build_context_synchronously
            context.read<AdWalletTransactionsBloc>().add(const LoadTransactionsInitial());
          });
        } else if (state.topupStatus == TopupStatus.failure) {
          showCustomSnackbar(context: context, message: state.error ?? 'Top up failed', isError: true, showAtTop: true);
          context.read<CampaignWalletBloc>().add(ClearTopupState());
        }
      },
      child: CustomScaffold(
        title: l10n?.tr('campaignWallet') ?? 'Campaign Wallet',
        showAppbar: true,
        centerTitle: true,
        body: RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            context.read<CampaignWalletBloc>().add(FetchAdWallet());
            context.read<AdWalletTransactionsBloc>().add(const LoadTransactionsInitial());
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Wallet Balance Card
              SliverToBoxAdapter(
                child: Padding(padding: UIUtils.pagePadding(screenType), child: _buildBalanceCard(l10n, screenType)),
              ),

              // Add Funds Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: UIUtils.pagePadding(screenType).left),
                  child: _buildAddFundsButtons(l10n, screenType),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: UIUtils.gapXL(screenType))),

              // Transaction History Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: UIUtils.pagePadding(screenType).left),
                  child: Text(
                    l10n?.tr('transactionHistory') ?? 'Transaction History',
                    style: TextStyle(fontSize: UIUtils.sectionTitle(screenType), fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: UIUtils.gapMD(screenType))),

              // Transaction List
              BlocBuilder<AdWalletTransactionsBloc, AdWalletTransactionsState>(
                builder: (context, state) {
                  if (state.isInitialLoading) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (state.items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n?.tr('noTransactionsYet') ?? 'No transactions yet',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: UIUtils.pagePadding(screenType).left),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= state.items.length) {
                          return state.isPaginating
                              ? const Center(
                                  child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                                )
                              : const SizedBox.shrink();
                        }
                        final txn = state.items[index];
                        return _buildTransactionItem(txn, l10n, screenType, theme);
                      }, childCount: state.items.length + (state.isPaginating ? 1 : 0)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext? l10n, ScreenType screenType) {
    return BlocBuilder<CampaignWalletBloc, CampaignWalletState>(
      builder: (context, state) {
        final balance = state.walletData?.balance ?? '0.00';
        final blockedBalance = state.walletData?.blockedBalance ?? '0.00';

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(UIUtils.gapLG(screenType)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor.withValues(alpha: 0.8), AppColors.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.tr('adWalletBalance') ?? 'Ad Wallet Balance',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: UIUtils.body(screenType)),
              ),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Text(
                '${CurrencyHelper.symbol}$balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: UIUtils.pageTitle(screenType) * 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Text(
                '${l10n?.tr('blocked') ?? "Blocked"}: ${CurrencyHelper.symbol}$blockedBalance',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: UIUtils.caption(screenType)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddFundsButtons(BuildContext? l10n, ScreenType screenType) {
    if (HiveStorage.advertisementEnable) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showTopupFromEarningsDialog(l10n, screenType),
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                l10n?.tr('fromEarnings') ?? 'From Earnings',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: UIUtils.gapMD(screenType)),
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType))),
              ),
            ),
          ),
          SizedBox(width: UIUtils.gapMD(screenType)),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showTopupViaGatewayDialog(l10n, screenType),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(l10n?.tr('addFunds') ?? 'Add Funds', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: UIUtils.gapMD(screenType)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType))),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orangeAccent),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(context.tr('featureUnavailable')),
      );
    }
  }

  Widget _buildTransactionItem(dynamic txn, BuildContext? l10n, ScreenType screenType, ThemeData theme) {
    final isDeposit = txn.transactionType == 'deposit';
    final statusColor = txn.status == 'completed'
        ? Colors.green
        : txn.status == 'pending'
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: UIUtils.gapMD(screenType)),
      padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDeposit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isDeposit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: UIUtils.gapMD(screenType)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: TextStyle(fontSize: UIUtils.body(screenType), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  TimeUtils.formatTimeAgo(txn.createdAt, context, type: TimeFormatType.wallet),
                  style: TextStyle(fontSize: UIUtils.caption(screenType), color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? "+" : "-"}${CurrencyHelper.symbol}${txn.amount}',
                style: TextStyle(
                  fontSize: UIUtils.tileTitle(screenType),
                  fontWeight: FontWeight.bold,
                  color: isDeposit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  txn.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopupFromEarningsDialog(BuildContext? l10n, ScreenType screenType) {
    final amountController = TextEditingController();
    // Minimum top-up amount comes from system settings (advertisement.walletMinTopup)
    // and is cached in HiveStorage by the SettingsCubit.
    final num minTopup = HiveStorage.advertisementWalletMinTopUp;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.tr('transferFromEarnings') ?? 'Transfer from Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n?.tr('amount') ?? 'Amount',
                prefixText: '${CurrencyHelper.symbol} ',
                hintText: minTopup > 0
                    ? '${l10n?.tr('minimum') ?? "Min"}: ${CurrencyHelper.symbol}${minTopup.toStringAsFixed(0)}'
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n?.tr('cancel') ?? 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('enterValidAmount') ?? 'Enter a valid amount',
                  isWarning: true,
                );
                return;
              }
              if (minTopup > 0 && amount < minTopup) {
                showCustomSnackbar(
                  context: context,
                  message:
                      '${l10n?.tr('minimumTopupIs') ?? "Minimum top-up is"} ${CurrencyHelper.symbol}${minTopup.toStringAsFixed(0)}',
                  isWarning: true,
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<CampaignWalletBloc>().add(TopupFromEarnings(amount: amount));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
            child: Text(l10n?.tr('transfer') ?? 'Transfer'),
          ),
        ],
      ),
    );
  }

  void _showTopupViaGatewayDialog(BuildContext? l10n, ScreenType screenType) {
    if (!PermissionChecker.hasPermission(AppPermissions.adWalletTopup)) {
      showCustomSnackbar(
        context: context,
        message: l10n?.tr('noPermissionError') ?? 'You do not have permission to view wallet.',
        isWarning: true,
      );
      return;
    }

    final amountController = TextEditingController();
    // Minimum top-up amount comes from system settings (advertisement.walletMinTopup)
    // and is cached in HiveStorage by the SettingsCubit.
    final num minTopup = HiveStorage.advertisementWalletMinTopUp;

    // Step 1: Show amount input dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.tr('addFunds') ?? 'Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n?.tr('amount') ?? 'Amount',
                prefixText: '${CurrencyHelper.symbol} ',
                hintText: minTopup > 0
                    ? '${l10n?.tr('minimum') ?? "Min"}: ${CurrencyHelper.symbol}${minTopup.toStringAsFixed(0)}'
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n?.tr('cancel') ?? 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('enterValidAmount') ?? 'Enter a valid amount',
                  isWarning: true,
                );
                return;
              }
              if (minTopup > 0 && amount < minTopup) {
                showCustomSnackbar(
                  context: context,
                  message:
                      '${l10n?.tr('minimumTopupIs') ?? "Minimum top-up is"} ${CurrencyHelper.symbol}${minTopup.toStringAsFixed(0)}',
                  isWarning: true,
                );
                return;
              }
              Navigator.pop(dialogContext);
              // Step 2: Show payment method bottom sheet
              _showPaymentMethodBottomSheet(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
            child: Text(l10n?.tr('next') ?? 'Next'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodBottomSheet(double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsLoaded && state.paymentSettings != null) {
              return PaymentSelectionBottomSheet(
                paymentSettings: state.paymentSettings!,
                onPaymentMethodSelected: (method) {
                  context.read<CampaignWalletBloc>().add(TopUpViaGateway(amount: amount, paymentMethod: method));
                },
              );
            }
            if (state is SettingsError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
