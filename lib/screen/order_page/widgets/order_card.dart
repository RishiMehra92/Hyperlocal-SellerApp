// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';
import 'package:hyper_local_seller/screen/order_page/utils/pickup_utils.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_countdown_timer.dart';

import 'package:hyper_local_seller/utils/currency_helper.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;
  final Function(String status)? onStatusUpdate;

  const OrderCard({super.key, required this.data, required this.screenType, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context;
    final status = (data['reschedule_status'] == 'needs_reschedule')
        ? 'needs_reschedule'
        : (data['status'] ?? '').toString().toLowerCase();

    final bool isScheduledList = data['is_scheduled_list'] == true;

    // Use centralized status configuration
    final statusConfig = PickupUtils.getOrderStatusConfig(status, context);
    final statusColor = statusConfig.textColor;
    final statusBgColor = statusConfig.bgColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Info
        _buildProductInfo(context, l10n, statusConfig.label, statusColor, statusBgColor),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.tr('deliveryType') ?? 'Delivery Type: ',
              style: TextStyle(fontSize: UIUtils.caption(screenType), color: theme.textTheme.bodySmall?.color),
            ),
            Text(
              data['scheduled_date'] != null && data['scheduled_date'].toString().isNotEmpty
                  ? (l10n?.translateEnum('scheduled') ?? 'Scheduled')
                  : (data['delivery_type']?.toString().toLowerCase() == 'pickup'
                        ? (l10n?.translateEnum('pickup') ?? 'Pickup')
                        : (data['isRushOrder'] == true
                              ? (l10n?.tr('rushDelivery') ?? 'Rush Delivery')
                              : (l10n?.tr('standardDelivery') ?? 'Standard Delivery'))),
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: data['scheduled_date'] != null && data['scheduled_date'].toString().isNotEmpty
                    ? Colors.blue
                    : (data['delivery_type']?.toString().toLowerCase() == 'pickup' ? Colors.green : Colors.orange),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        if (data['scheduled_date'] != null && data['scheduled_date'].toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.translateEnum('scheduled_date') ?? 'Scheduled Date'}: ',
                style: TextStyle(fontSize: UIUtils.caption(screenType), color: theme.textTheme.bodySmall?.color),
              ),
              Text(
                '${TimeUtils.formatScheduledDate(data['scheduled_date']?.toString())}${'\n${data['scheduled_time_slot_label'] != null && data['scheduled_time_slot_label'].toString().isNotEmpty ? data['scheduled_time_slot_label'] : ""}'}',
                style: TextStyle(fontSize: UIUtils.caption(screenType), fontWeight: FontWeight.w500),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if ((status == 'pending' || status == 'awaiting_store_response') &&
                !isScheduledList &&
                (data['scheduled_date'] == null || data['scheduled_date'].toString().isEmpty) &&
                data['acceptance_timeout'] != null &&
                data['acceptance_timeout'].enabled == true)
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  OrderCountdownTimer(
                    createdAt: data['created_at']?.toString() ?? '',
                    timeoutMinutes: data['acceptance_timeout'].minutes,
                    deadlineStr: data['acceptance_timeout'].deadline,
                    onTimeout: () {
                      onStatusUpdate?.call('auto_reject');
                    },
                    textStyle: TextStyle(fontSize: UIUtils.caption(screenType)),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            Text(
              TimeUtils.formatTimeAgo(data['created_at'], context, type: TimeFormatType.order),
              style: TextStyle(fontSize: UIUtils.caption(screenType), color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),

        // Buttons / Status Badge
        if (data['reschedule_status'] == 'needs_reschedule') ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300, width: 1),
            ),
            child: Center(
              child: Text(
                l10n?.translateEnum('awaiting_customer_reschedule') ?? 'Awaiting Customer Reschedule',
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else if (status == 'pending' || status == 'awaiting_store_response') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: l10n?.tr('reject') ?? 'Reject',
                  onPressed: () => onStatusUpdate?.call('reject'),
                  foregroundColor: Colors.red,
                  borderColor: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: l10n?.tr('viewDetails') ?? 'View Details',
                  onPressed: () => onStatusUpdate?.call('view_details'),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Center(
              child: Text(
                statusConfig.label,
                style: TextStyle(fontSize: UIUtils.body(screenType), color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo(
    BuildContext context,
    BuildContext? l10n,
    String statusConfigLabel,
    Color statusColor,
    Color statusBgColor,
  ) {
    List<dynamic> itemsList = data['items'] ?? [];
    if (itemsList.isEmpty) return const SizedBox.shrink();

    if (itemsList.length == 1) {
      final singleItem = itemsList.first;
      final images = singleItem['images'] as List<dynamic>? ?? [];
      final image = images.isNotEmpty ? images.first.toString() : '';
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSingleImage(image),
          SizedBox(width: UIUtils.gapMD(screenType)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        singleItem['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: UIUtils.body(screenType), fontWeight: UIUtils.bold),
                      ),
                    ),
                    _buildStatusBadge(statusConfigLabel, statusColor, statusBgColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n?.tr('qtyWithCount', positionalArgs: [singleItem['quantity'] ?? 1]) ?? 'Qty: ${singleItem['quantity']}'} × ${singleItem['price']}',
                  style: TextStyle(fontSize: UIUtils.caption(screenType), color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.tr('nItems', positionalArgs: [itemsList.length]) ?? '${itemsList.length} Items',
                style: TextStyle(fontSize: UIUtils.body(screenType), fontWeight: UIUtils.bold),
              ),
              _buildStatusBadge(statusConfigLabel, statusColor, statusBgColor),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itemsList.map((item) {
              final images = item['images'] as List<dynamic>? ?? [];
              final image = images.isNotEmpty ? images.first.toString() : '';
              return _buildSmallImage(image);
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n?.tr('subtotal') ?? 'Subtotal'}: ${CurrencyHelper.symbol} ${(double.tryParse(data['subtotal']?.toString() ?? '0') ?? 0).round()}',
            style: TextStyle(fontSize: UIUtils.caption(screenType), color: Colors.grey.shade600),
          ),
        ],
      );
    }
  }

  Widget _buildStatusBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: TextStyle(fontSize: UIUtils.caption(screenType), color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CustomNetworkImage(
        imageUrl: url,
        errorWidget: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        width: UIUtils.avatarXL(screenType),
        height: UIUtils.avatarXL(screenType),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSmallImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusXS(screenType)),
      child: CustomNetworkImage(
        imageUrl: url,
        errorWidget: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
    );
  }
}
