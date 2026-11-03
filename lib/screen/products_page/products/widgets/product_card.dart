// lib/screen/more_page/view/products/widgets/product_card.dart
// (adjust path as needed)

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const ProductCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] ?? 0).toString();
    final specialPrice = (data['special_price'] ?? '').toString();
    final hasSpecialPrice = specialPrice.isNotEmpty && specialPrice != price;

    final hasImage = data['image'] != null && data['image'].toString().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[_buildImage(), SizedBox(width: UIUtils.gapMD(screenType))],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['name'] ?? '',
                      style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: UIUtils.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (data['rating'] != null && (data['rating'] as num) > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          data['rating'].toString(),
                          style: TextStyle(fontSize: UIUtils.caption(screenType), fontWeight: UIUtils.bold),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: UIUtils.gapXS(screenType)),
              if (data['category'] != null)
                Text(
                  data['category'],
                  style: TextStyle(fontSize: UIUtils.body(screenType), color: Colors.grey.shade600),
                ),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hasSpecialPrice) ...[
                        Text(
                          "${CurrencyHelper.symbol}$price",
                          style: TextStyle(
                            fontSize: UIUtils.caption(screenType),
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.primaryColor.withValues(alpha: 10),
                            decorationThickness: 0.7,
                          ),
                        ),
                        SizedBox(width: UIUtils.gapMD(screenType)),
                      ],

                      Text(
                        "${CurrencyHelper.symbol}${hasSpecialPrice ? specialPrice : price}",
                        style: TextStyle(
                          fontSize: UIUtils.body(screenType),
                          fontWeight: UIUtils.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (data['product_status'] != null && data['product_status'].toString().trim().isNotEmpty)
                          _buildProductStatusChip(context, data['product_status'].toString()),
                        if (data['status'] != null)
                          _buildStatusChip(context, data['status'], isActive: data['status'] == 'active'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CachedNetworkImage(
        imageUrl: data['image'] ?? 'https://via.placeholder.com/150',
        width: UIUtils.avatarXL(screenType),
        height: UIUtils.avatarXL(screenType),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey.shade100),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.inventory_2, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductStatusChip(BuildContext context, String rawStatus) {
    final loc = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = rawStatus.trim().toLowerCase();

    final Color bgColor;
    final Color textColor;

    if (status == 'rejected' || status.contains('reject')) {
      bgColor = isDark ? const Color(0xFF3B1212) : Colors.red.shade50;
      textColor = isDark ? const Color(0xFFEF5350) : Colors.red.shade800;
    } else if (status == 'approved' || status == 'active') {
      bgColor = isDark ? const Color(0xFF0D2818) : Colors.green.shade50;
      textColor = isDark ? const Color(0xFF4ADE80) : Colors.green.shade800;
    } else {
      // Pending, pending_verification, pending_approval, etc.
      bgColor = isDark ? const Color(0xFF2E1F06) : Colors.amber.shade50;
      textColor = isDark ? const Color(0xFFFBBF24) : Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        loc?.translateEnum(rawStatus) ?? rawStatus,
        style: TextStyle(fontSize: UIUtils.caption(screenType), fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, {bool isActive = false}) {
    final loc = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isActive
        ? (isDark ? const Color(0xFF0D2818) : Colors.green.shade50)
        : (isDark ? const Color(0xFF2E1F06) : Colors.orange.shade50);
    final textColor = isActive
        ? (isDark ? const Color(0xFF4ADE80) : Colors.green.shade800)
        : (isDark ? const Color(0xFFFBBF24) : Colors.orange.shade800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        loc?.translateEnum(label) ?? label,
        style: TextStyle(fontSize: UIUtils.caption(screenType), fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
