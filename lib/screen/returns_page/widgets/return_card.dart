import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_status_chip.dart';
import '../model/order_return_model.dart';

class ReturnCard extends StatelessWidget {
  final OrderReturn item;
  final ScreenType screenType;
  const ReturnCard({super.key, required this.item, required this.screenType});
  @override
  Widget build(BuildContext context) {
    final l10n = context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomNetworkImage(
              imageUrl: item.product.image,
              width: 64,
              height: 64,
              borderRadius: UIUtils.radiusMD(screenType),
              errorWidget: const Icon(Icons.inventory_2_outlined),
            ),
            SizedBox(width: UIUtils.gapMD(screenType)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: TextStyle(
                      fontSize: UIUtils.body(screenType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.product.variantTitle.isNotEmpty)
                    Text(item.product.variantTitle),
                  if (item.product.quantity != null)
                    Text('${l10n.tr('quantity')}: ${item.product.quantity}'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        CustomStatusChip(
          label: item.statusLabel,
          baseColor: Theme.of(context).colorScheme.tertiary,
          screenType: screenType,
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.tr('returnsOrderNumber')}: ${item.orderNumber.isEmpty ? item.orderId ?? '—' : item.orderNumber}',
        ),
        if (item.customer.name.isNotEmpty)
          Text('${l10n.tr('returnsCustomer')}: ${item.customer.name}'),
        if (item.store.name.isNotEmpty)
          Text('${l10n.tr('store')}: ${item.store.name}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(
              '${l10n.tr('returnsRefundAmount')}: ${returnMoney(item.refundAmount)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (item.createdAt != null)
              Text(
                TimeUtils.formatScheduledDate(
                  item.createdAt!.toLocal().toIso8601String(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String returnMoney(double? amount) => amount == null
    ? '—'
    : '${CurrencyHelper.symbol}${amount.toStringAsFixed(2)}';
