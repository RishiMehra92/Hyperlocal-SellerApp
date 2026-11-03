import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/model/delivery_zone_model.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

class DeliveryZoneDetailsPage extends StatelessWidget {
  final DeliveryZone zone;

  const DeliveryZoneDetailsPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context;
    return CustomScaffold(
      title: l10n?.tr('zoneDetails') ?? "Zone Details",
      showAppbar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zone.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: zone.status == 'active'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          zone.status.toUpperCase(),
                          style: TextStyle(
                            color: zone.status == 'active'
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: l10n?.tr('deliveryFee') ?? "Delivery Fee",
                          value:
                              "${CurrencyHelper.symbol}${zone.regularDeliveryCharges ?? 0}",
                          icon: Icons.local_shipping_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InfoTile(
                          label: l10n?.tr('rushFee') ?? "Rush Fee",
                          value:
                              "${CurrencyHelper.symbol}${zone.rushDeliveryCharges ?? 0}",
                          icon: Icons.bolt_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoTileWide(
                    label: l10n?.tr('freeDeliveryAbove') ?? "Free Delivery Above",
                    value:
                        "${CurrencyHelper.symbol}${zone.freeDeliveryAmount ?? 0}",
                    icon: Icons.card_giftcard_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.tr('operationalDetails') ?? "Operational Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              children: [
                _DetailRow(
                  label: l10n?.tr('radius') ?? "Radius",
                  value: "${zone.radiusKm ?? 0} ${l10n?.tr('km') ?? 'km'}",
                ),
                _DetailRow(
                  label: l10n?.tr('deliveryTime') ?? "Delivery Time",
                  value:
                      "${zone.deliveryTimePerKm ?? 0} ${l10n?.tr('minPerKm') ?? 'min/km'}",
                ),
                _DetailRow(
                  label: l10n?.tr('rushDeliveryTime') ?? "Rush Delivery Time",
                  value:
                      "${zone.rushDeliveryTimePerKm ?? 0} ${l10n?.tr('minPerKm') ?? 'min/km'}",
                ),
                _DetailRow(
                  label: l10n?.tr('bufferTime') ?? "Buffer Time",
                  value: "${zone.bufferTime ?? 0} ${l10n?.tr('min') ?? 'min'}",
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.tr('chargesAndFees') ?? "Charges & Fees",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              children: [
                _DetailRow(
                  label: l10n?.tr('handlingCharges') ?? "Handling Charges",
                  value: "${CurrencyHelper.symbol}${zone.handlingCharges ?? 0}",
                ),
                _DetailRow(
                  label: l10n?.tr('perStoreDropOff') ?? "Per Store Drop-off",
                  value:
                      "${CurrencyHelper.symbol}${zone.perStoreDropOffFee ?? 0}",
                ),
                _DetailRow(
                  label: l10n?.tr('distanceBasedFee') ?? "Distance Based Fee",
                  value:
                      "${CurrencyHelper.symbol}${zone.distanceBasedDeliveryCharges ?? 0}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _InfoTileWide extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTileWide({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
