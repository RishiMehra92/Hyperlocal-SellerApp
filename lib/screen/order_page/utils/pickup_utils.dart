import 'package:flutter/material.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_details_model.dart';

class OrderStatusConfig {
  final String label;
  final Color textColor;
  final Color bgColor;

  const OrderStatusConfig({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });
}

class PickupUtils {
  /// Centralized mapping for order and sub-order statuses.
  static OrderStatusConfig getOrderStatusConfig(
    String status,
    BuildContext context,
  ) {
    final l10n = context;
    final s = status.toLowerCase();

    String label;
    Color textColor;
    Color bgColor;

    switch (s) {
      case 'awaiting_store_response':
        label =
            l10n?.translateEnum('awaiting_store_response') ??
            'Awaiting Store Response';
        textColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.12);
        break;
      case 'needs_reschedule':
        label =
            l10n?.translateEnum('needs_reschedule') ??
            'Awaiting Customer Reschedule';
        textColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.12);
        break;
      case 'accepted_by_seller':
        label =
            l10n?.translateEnum('accepted_by_seller') ?? 'Accepted by Seller';
        textColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
        break;
      case 'accepted':
        label = l10n?.translateEnum('accepted') ?? 'Accepted';
        textColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
        break;
      case 'preparing':
        label = l10n?.translateEnum('preparing') ?? 'Preparing';
        textColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.12);
        break;
      case 'ready_for_pickup':
        label = l10n?.translateEnum('ready_for_pickup') ?? 'Ready for Pickup';
        textColor = Colors.purple;
        bgColor = Colors.purple.withValues(alpha: 0.12);
        break;
      case 'delivered':
      case 'completed':
        label = l10n?.translateEnum('delivered') ?? 'Delivered';
        textColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
        break;
      case 'rejected_by_seller':
        label =
            l10n?.translateEnum('rejected_by_seller') ?? 'Rejected by Seller';
        textColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
        break;
      case 'rejected':
        label = l10n?.translateEnum('rejected') ?? 'Rejected';
        textColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
        break;
      case 'cancelled':
        label = l10n?.translateEnum('cancelled') ?? 'Cancelled';
        textColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
        break;
      case 'failed':
        label = l10n?.translateEnum('failed') ?? 'Failed';
        textColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
        break;
      default:
        label =
            l10n?.translateEnum(status) ??
            status.toUpperCase().replaceAll('_', ' ');
        textColor = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.12);
    }

    return OrderStatusConfig(
      label: label,
      textColor: textColor,
      bgColor: bgColor,
    );
  }

  /// Checks if there is at least one active item in the order.
  /// An item is inactive if its status is rejected, cancelled, or failed.
  static bool hasActiveItems(List<OrderItemDetail>? items) {
    if (items == null || items.isEmpty) return false;
    return items.any((item) {
      final status = (item.orderItem?.status ?? '').toLowerCase();
      return status != 'rejected' &&
          status != 'cancelled' &&
          status != 'failed';
    });
  }

  /// Determines which self-pickup action button to show.
  /// Returns "MARK_READY", "VERIFY_OTP", or "NONE".
  static String getPickupAction(OrderDetailsData order) {
    final readyForPickupAt = order.readyForPickupAt;
    final pickedUpAt = order.pickedUpAt;

    final isReadyForPickupNull =
        readyForPickupAt == null || readyForPickupAt.trim().isEmpty;
    final isPickedUpNull = pickedUpAt == null || pickedUpAt.trim().isEmpty;

    if (isReadyForPickupNull && isPickedUpNull) {
      return 'MARK_READY';
    } else if (!isReadyForPickupNull && isPickedUpNull) {
      return 'VERIFY_OTP';
    } else {
      return 'NONE';
    }
  }
}
