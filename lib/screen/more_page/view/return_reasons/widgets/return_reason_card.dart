import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class ReturnReasonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const ReturnReasonCard({
    super.key,
    required this.data,
    required this.screenType,
  });

  Widget _buildStatusChip(BuildContext context, String status) {
    final l10n = context;
    final isActive = status.toLowerCase() == 'active';
    final bgColor = isActive ? Colors.green.shade50 : Colors.grey.shade100;
    final textColor = isActive ? Colors.green.shade800 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? (l10n?.tr('active') ?? 'Active') : (l10n?.tr('inactive') ?? 'Inactive'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final titleColor = isDark
        ? AppColors.darkFontColor
        : AppColors.lightFontColor;

    final String titleReason = data['titleReason'] ?? '';
    final String status = data['status'] ?? 'inactive';
    final bool riderOtpRequired = data['riderOtpRequired'] ?? false;
    final bool riderCustomerImageProof = data['riderCustomerImageProof'] ?? false;
    final int selectedProductsLength = data['selectedProductsLength'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    titleReason,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  _buildStatusChip(context, status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            Chip(
              label: Text(
                riderOtpRequired
                    ? (l10n?.tr('riderOtpRequired') ?? "Rider OTP: Required")
                    : (l10n?.tr('riderOtpOptional') ?? "Rider OTP: Optional"),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: riderOtpRequired
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
            Chip(
              label: Text(
                riderCustomerImageProof
                    ? (l10n?.tr('proofRequired') ?? "Proof Required")
                    : (l10n?.tr('noProofRequired') ?? "No Proof Required"),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: riderCustomerImageProof
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
            if (selectedProductsLength > 0)
              Chip(
                label: Text(
                  l10n?.tr('productsSelected', positionalArgs: [selectedProductsLength]) ??
                      "$selectedProductsLength Products Selected",
                  style: const TextStyle(fontSize: 12),
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}
