import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

import '../model/campaign_model.dart';

class CampaignCard extends StatelessWidget {
  final CampaignData campaign;
  final VoidCallback? onTap;

  const CampaignCard({super.key, required this.campaign, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(campaign.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
      child: Container(
        padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    UIUtils.radiusSM(screenType),
                  ),
                  child: Image.network(
                    campaign.productImage,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: UIUtils.gapMD(screenType)),
                // Product Title & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.productTitle,
                        style: TextStyle(
                          fontSize: UIUtils.tileTitle(screenType),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: UIUtils.gapXS(screenType)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          campaign.statusLabel,
                          style: TextStyle(
                            fontSize: UIUtils.caption(screenType),
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            // Budget Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: campaign.budget > 0
                    ? campaign.spent / campaign.budget
                    : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
                minHeight: 4,
              ),
            ),
            SizedBox(height: UIUtils.gapSM(screenType)),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${CurrencyHelper.symbol}${campaign.spent.toStringAsFixed(2)} / ${CurrencyHelper.symbol}${campaign.budget.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: UIUtils.caption(screenType),
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${campaign.totalImpressions}',
                      style: TextStyle(
                        fontSize: UIUtils.caption(screenType),
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${campaign.totalClicks}',
                      style: TextStyle(
                        fontSize: UIUtils.caption(screenType),
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'pending_approval':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
