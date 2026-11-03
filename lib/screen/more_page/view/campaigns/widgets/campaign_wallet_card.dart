import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

import '../bloc/campaign_wallet_bloc/campaign_wallet_bloc.dart';

class CampaignWalletCard extends StatelessWidget {
  const CampaignWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;

    return BlocBuilder<CampaignWalletBloc, CampaignWalletState>(
      builder: (context, state) {
        if (state.walletStatus == AdWalletStatus.loading &&
            state.walletData == null) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
            ),
          );
        }

        final balance = state.walletData?.balance ?? '0.00';

        return Container(
          padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withValues(alpha: 0.8),
                AppColors.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: UIUtils.gapMD(screenType)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.tr('adWalletBalance') ?? 'Ad Wallet',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: UIUtils.caption(screenType),
                      ),
                    ),
                    Text(
                      '${CurrencyHelper.symbol}$balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: UIUtils.tileTitle(screenType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              /*Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.8),
              ),*/
            ],
          ),
        );
      },
    );
  }
}
