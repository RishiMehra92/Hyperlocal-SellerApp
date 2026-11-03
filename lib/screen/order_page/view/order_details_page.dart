// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_details_bloc/order_details_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_details_model.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';
import 'package:hyper_local_seller/screen/order_page/utils/pickup_utils.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/otp_input_dialog.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_countdown_timer.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final Set<int> _selectedItemIds = {};
  bool _isMarkingReady = false;
  final bool _isVerifyingOtp = false;
  bool _isUpdatingDialogVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
  }

  /// Returns 'pending' if selected items are pending/awaiting,
  /// 'accepted' if selected items are accepted, or null if nothing selected.
  String? _getSelectionMode(List<OrderItemDetail> items) {
    if (_selectedItemIds.isEmpty) return null;
    for (final item in items) {
      final itemId = item.orderItem?.id ?? item.id;
      if (_selectedItemIds.contains(itemId)) {
        final status = (item.orderItem?.status ?? '').toLowerCase();
        if (status == 'pending' || status == 'awaiting_store_response') {
          return 'pending';
        } else if (status == 'accepted') {
          return 'accepted';
        } else if (status == 'preparing' || status == 'ready_for_pickup') {
          return 'cancellable';
        }
      }
    }
    return null;
  }

  /// Checks if an item can be selected based on its status and current selection mode.
  bool _isItemSelectable(OrderItemDetail item, String? selectionMode) {
    final status = (item.orderItem?.status ?? '').toLowerCase();
    // Never selectable statuses
    if ({'rejected', 'rejected_by_seller', 'cancelled', 'completed', 'delivered', 'failed'}.contains(status)) {
      return false;
    }
    // No mode yet — any actionable item can start selection
    if (selectionMode == null) {
      return status == 'pending' ||
          status == 'awaiting_store_response' ||
          status == 'accepted' ||
          status == 'preparing' ||
          status == 'ready_for_pickup';
    }
    if (selectionMode == 'pending') {
      return status == 'pending' || status == 'awaiting_store_response';
    }
    if (selectionMode == 'accepted') {
      return status == 'accepted';
    }
    if (selectionMode == 'cancellable') {
      return status == 'preparing' || status == 'ready_for_pickup';
    }
    return false;
  }

  /// Whether item has an actionable status (should show checkbox).
  bool _isItemActionable(OrderItemDetail item) {
    final status = (item.orderItem?.status ?? '').toLowerCase();
    return status == 'pending' ||
        status == 'awaiting_store_response' ||
        status == 'accepted' ||
        status == 'preparing' ||
        status == 'ready_for_pickup';
  }

  bool _canActionScheduledDelivery(OrderDetailsData data, String itemStatus) {
    if (itemStatus == 'pending' || itemStatus == 'awaiting_store_response') {
      return true;
    }
    if (!data.isScheduledDelivery) return true;
    if (data.scheduledDate == null || data.scheduledDate!.isEmpty) return false;
    final DateTime? scheduledDateTime = DateTime.tryParse(data.scheduledDate!);
    if (scheduledDateTime == null) return false;
    final DateTime today = DateTime.now();
    final DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
    final DateTime scheduledDateOnly = DateTime(scheduledDateTime.year, scheduledDateTime.month, scheduledDateTime.day);
    return !scheduledDateOnly.isAfter(todayDateOnly);
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme
    final theme = Theme.of(context);
    final currencySymbol = CurrencyHelper.symbol;
    final l10n = context;

    return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
      listener: (context, state) {
        if (state is OrderDetailsLoaded) {
          if (state.isUpdating && !_isUpdatingDialogVisible) {
            _isUpdatingDialogVisible = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            ).then((_) {
              _isUpdatingDialogVisible = false;
            });
          } else if (!state.isUpdating && _isUpdatingDialogVisible) {
            Navigator.of(context, rootNavigator: true).pop();
            _isUpdatingDialogVisible = false;
          }

          if (!state.isUpdating) {
            setState(() {
              _selectedItemIds.clear();
              final isPickup = state.orderData.deliveryType?.toLowerCase() == 'pickup';
              final status = state.orderData.status.toLowerCase();
              if (isPickup && (status == 'ready_for_pickup' || status == 'completed' || status == 'delivered')) {
                for (final item in state.orderData.items ?? []) {
                  final itemId = item.orderItem?.id ?? item.id;
                  _selectedItemIds.add(itemId);
                }
              }
            });
          }
        }
      },
      builder: (context, state) {
        Widget? bottomBar;
        if (state is OrderDetailsLoaded) {
          bottomBar = _buildBottomBar(context, state.orderData, state.isUpdating, l10n);
        }

        return CustomScaffold(
          title: l10n?.tr('orderDetails') ?? 'Order Details',
          centerTitle: true,
          showAppbar: true,
          bottomNavigationBar: bottomBar,
          body: Builder(
            builder: (context) {
              if (state is OrderDetailsLoading) {
                return _buildShimmerLoading(context);
              }
              if (state is OrderDetailsError) {
                return Center(child: Text(state.message));
              }
              if (state is OrderDetailsLoaded) {
                final data = state.orderData;
                return RefreshIndicator(
                  color: AppColors.primaryColor,
                  onRefresh: () async {
                    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Order Summary
                        _buildSection(
                          context,
                          title: l10n?.tr('orderSummary') ?? 'Order Summary',
                          child: Column(
                            children: [
                              _buildKvRow(context, l10n?.tr('orderNumber') ?? 'Order Number :', data.orderId.toString()),
                              _buildKvRow(context, l10n?.tr('orderDate') ?? 'Order Date :', data.createdAt),
                              if (data.isScheduledDelivery && data.scheduledDate != null)
                                _buildKvRow(
                                  context,
                                  '${l10n?.translateEnum('scheduled_for') ?? 'Scheduled for'} :',
                                  '${TimeUtils.formatScheduledDate(data.scheduledDate)}${data.deliveryTimeSlotId != null && data.scheduledTimeSlotLabel != null && data.scheduledTimeSlotLabel!.isNotEmpty ? ' • ${data.scheduledTimeSlotLabel}' : ''}',
                                ),
                              _buildKvRow(
                                context,
                                l10n?.tr('statusLabel') ?? 'Status :',
                                data.rescheduleStatus == 'needs_reschedule' ? 'needs_reschedule' : data.status,
                                isStatus: true,
                              ),
                              if ((data.status.toLowerCase() == 'pending' ||
                                      data.status.toLowerCase() == 'awaiting_store_response') &&
                                  !data.isScheduledDelivery &&
                                  data.acceptanceTimeout != null &&
                                  data.acceptanceTimeout!.enabled)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          l10n?.tr('autoRejectIn') ?? 'Auto Reject in: ',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                                              const SizedBox(width: 4),
                                              OrderCountdownTimer(
                                                createdAt: data.createdAt,
                                                timeoutMinutes: data.acceptanceTimeout!.minutes,
                                                deadlineStr: data.acceptanceTimeout!.deadline,
                                                onTimeout: () {
                                                  context.read<OrderDetailsBloc>().add(
                                                    const LocalUpdateOrderDetailsStatusEvent(
                                                      status: 'rejected_by_seller',
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _buildKvRow(
                                context,
                                l10n?.tr('totalPrice') ?? 'Total Price :',
                                '$currencySymbol ${data.totalPrice}',
                              ),
                              _buildKvRow(
                                context,
                                l10n?.tr('paymentMethod') ?? 'Payment Method :',
                                data.paymentMethod.toUpperCase().replaceAll('_', ' '),
                              ),
                              _buildKvRow(
                                context,
                                l10n?.tr('paymentStatus') ?? 'Payment Status :',
                                data.paymentStatus,
                                isStatus: false,
                                isPaymentStatus: true,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.tr('deliveryTypeLabel') ?? 'Delivery Type :',
                                data.deliveryType?.toLowerCase() == 'pickup'
                                    ? (l10n?.translateEnum('pickup') ?? 'Pickup')
                                    : (data.isRushedOrder == 1
                                          ? (l10n?.tr('rushDelivery') ?? 'Rush Delivery')
                                          : (l10n?.tr('standardDelivery') ?? 'Standard Delivery')),
                                isStatus: true,
                              ),
                              if (data.orderNote != null && data.orderNote!.isNotEmpty)
                                _buildKvRow(context, l10n?.tr('orderNote') ?? 'Order Note :', data.orderNote!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSection(
                          context,
                          title: '${l10n?.tr('orderItems') ?? "Order Items"} (${data.items?.length ?? 0})',
                          trailing:
                              _selectedItemIds.isNotEmpty &&
                                  !(data.deliveryType?.toLowerCase() == 'pickup' &&
                                      {
                                        'ready_for_pickup',
                                        'completed',
                                        'delivered',
                                        'cancelled',
                                        'rejected',
                                      }.contains(data.status.toLowerCase()))
                              ? TextButton.icon(
                                  onPressed: () => setState(() => _selectedItemIds.clear()),
                                  icon: const Icon(TablerIcons.circle_x, size: 16),
                                  label: Text(l10n?.tr('clear') ?? 'Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                )
                              : null,
                          child: Column(
                            children: () {
                              final items = data.items ?? [];
                              final isPickup = data.deliveryType?.toLowerCase() == 'pickup';
                              final orderStatus = data.status.toLowerCase();
                              final selectionMode = isPickup ? null : _getSelectionMode(items);
                              return items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final bool isSame = item.product?.title == item.variant?.title;
                                final itemId = item.orderItem?.id ?? item.id;
                                final bool showCheckbox =
                                    _canActionScheduledDelivery(data, (item.orderItem?.status ?? '').toLowerCase()) &&
                                    (isPickup
                                        ? ((item.orderItem?.status.toLowerCase() != 'rejected' &&
                                                  item.orderItem?.status.toLowerCase() != 'cancelled' &&
                                                  item.orderItem?.status.toLowerCase() != 'failed') &&
                                              !{
                                                'ready_for_pickup',
                                                'completed',
                                                'delivered',
                                                'cancelled',
                                                'rejected',
                                                'failed',
                                                'rejected_by_seller',
                                              }.contains(orderStatus))
                                        : _isItemActionable(item));

                                final bool isSelectable =
                                    _canActionScheduledDelivery(data, (item.orderItem?.status ?? '').toLowerCase()) &&
                                    (isPickup
                                        ? ((item.orderItem?.status.toLowerCase() != 'rejected' &&
                                                  item.orderItem?.status.toLowerCase() != 'cancelled' &&
                                                  item.orderItem?.status.toLowerCase() != 'failed') &&
                                              !{
                                                'ready_for_pickup',
                                                'completed',
                                                'delivered',
                                                'cancelled',
                                                'rejected',
                                                'failed',
                                                'rejected_by_seller',
                                              }.contains(orderStatus))
                                        : _isItemSelectable(item, selectionMode));

                                return _ExpandableOrderItem(
                                  index: index,
                                  item: item,
                                  isSame: isSame,
                                  currencySymbol: currencySymbol,
                                  isLast: index == items.length - 1,
                                  isSelected: _selectedItemIds.contains(itemId),
                                  isSelectable: isSelectable,
                                  showCheckbox: showCheckbox,
                                  onSelectionChanged: (_) => _toggleItemSelection(itemId),
                                  rescheduleStatus: data.rescheduleStatus,
                                );
                              }).toList();
                            }(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Customer Information
                        _buildSection(
                          context,
                          title: l10n?.tr('customerInformation') ?? 'Customer Information',
                          child: Column(
                            children: [
                              _buildKvRow(context, l10n?.tr('customerName') ?? 'Customer Name :', data.billingName),
                              _buildKvRow(context, l10n?.tr('phoneLabel') ?? 'Phone :', data.billingPhone, isPhone: true),
                              _buildKvRow(context, l10n?.tr('emailLabel') ?? 'Email :', data.email),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Rider Information
                        if (data.deliveryBoy != null) ...[
                          _buildSection(
                            context,
                            title: l10n?.translateEnum('rider_details') ?? 'Rider Details',
                            child: Column(
                              children: [
                                _buildKvRow(
                                  context,
                                  '${l10n?.translateEnum('rider_name') ?? 'Rider Name'} :',
                                  data.deliveryBoy!.fullName,
                                ),
                                _buildKvRow(
                                  context,
                                  l10n?.tr('phoneLabel') ?? 'Phone :',
                                  data.deliveryBoy!.mobile,
                                  isPhone: true,
                                ),
                                _buildKvRow(context, l10n?.tr('emailLabel') ?? 'Email :', data.deliveryBoy!.email),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Shipping Address
                        _buildSection(
                          context,
                          title: l10n?.tr('shippingAddress') ?? 'Shipping Address',
                          child: Text(
                            '${data.shippingName}\n'
                            '${data.shippingAddress1}\n'
                            '${data.shippingCity}, ${data.shippingState} ${data.shippingZip}, ${data.shippingCountry}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child, Widget? trailing}) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildKvRow(
    BuildContext context,
    String key,
    String value, {
    bool isStatus = false,
    bool isPaymentStatus = false,
    bool isPhone = false,
  }) {
    final theme = Theme.of(context);

    Widget valueWidget = Text(
      value.isEmpty ? '—' : value, // fallback for empty values
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );

    if (isPhone && value.isNotEmpty) {
      valueWidget = InkWell(
        onTap: () async {
          final Uri phoneUri = Uri(scheme: 'tel', path: value);
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            const Icon(Icons.phone_in_talk_rounded, size: 16),
          ],
        ),
      );
    } else if (isStatus || isPaymentStatus) {
      Color color = Colors.green;
      Color bgColor = Colors.green.withValues(alpha: 0.12);
      String textValue;

      if (isStatus) {
        final statusConfig = PickupUtils.getOrderStatusConfig(value, context);
        color = statusConfig.textColor;
        bgColor = statusConfig.bgColor;
        textValue = statusConfig.label.toUpperCase();
      } else {
        final v = value.toLowerCase().replaceAll('_', ' ');
        if (v.contains('pending') || v.contains('awaiting') || v.contains('partially')) {
          color = Colors.orange;
          bgColor = Colors.orange.withValues(alpha: 0.12);
        } else if (v.contains('accepted')) {
          color = Colors.green;
          bgColor = Colors.green.withValues(alpha: 0.12);
        } else if (v.contains('completed') || v.contains('delivered') || v.contains('paid')) {
          color = Colors.green;
          bgColor = Colors.green.withValues(alpha: 0.12);
        } else if (v.contains('rejected') || v.contains('cancelled') || v.contains('failed')) {
          color = Colors.red;
          bgColor = Colors.red.withValues(alpha: 0.12);
        }
        textValue = v.toUpperCase();
      }

      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Text(
          textValue,
          style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16), // consistent gap
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft, // values pushed to right
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionShimmer(context, 190),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 150),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 150),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 175),
        ],
      ),
    );
  }

  Widget _buildSectionShimmer(BuildContext context, double height) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(width: 150, height: 20),
          SizedBox(height: 16),
          Divider(height: 1),
          SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [CustomShimmer(width: 100, height: 16), CustomShimmer(width: 150, height: 16)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [CustomShimmer(width: 100, height: 16), CustomShimmer(width: 150, height: 16)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [CustomShimmer(width: 100, height: 16), CustomShimmer(width: 80, height: 16)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context, OrderDetailsData data, bool isUpdating, BuildContext? l10n) {
    if (data.items == null || data.items!.isEmpty) return null;

    final theme = Theme.of(context);
    final topLevelStatus = data.status.toLowerCase();

    if (topLevelStatus == 'rejected_by_seller' || topLevelStatus == 'rejected' || topLevelStatus == 'cancelled') {
      return null;
    }

    if (data.rescheduleStatus == 'needs_reschedule') {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.translateEnum('awaiting_customer_reschedule') ?? 'Awaiting Customer Reschedule',
                  style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPickup = data.deliveryType?.toLowerCase() == 'pickup';

    if (isPickup) {
      // Step B: Check Active Items
      if (!PickupUtils.hasActiveItems(data.items)) {
        return null;
      }

      final orderStatus = data.status.toLowerCase();

      // If the order has not been accepted yet (awaiting response or pending), show Accept/Reject.
      if (orderStatus == 'awaiting_store_response' || orderStatus == 'pending') {
        if (_selectedItemIds.isEmpty) return null;

        final selectionMode = _getSelectionMode(data.items!);
        if (selectionMode == 'pending') {
          return _buildAcceptRejectButtons(context, isUpdating, l10n);
        }
        return null;
      }

      // Step C: Determine Which Action Button to Show
      final action = PickupUtils.getPickupAction(data);
      if (action == 'NONE') {
        return null;
      }

      if (action == 'VERIFY_OTP') {
        return _buildVerifyOtpButton(context, l10n);
      }

      if (action == 'MARK_READY') {
        // Must be accepted or preparing first
        if (orderStatus == 'accepted' || orderStatus == 'accepted_by_seller' || orderStatus == 'preparing') {
          return _buildMarkReadyButton(context, data, isUpdating, l10n);
        }
      }

      return null;
    }

    // Normal delivery flow
    if (_selectedItemIds.isEmpty) return null;

    final selectionMode = _getSelectionMode(data.items!);
    if (selectionMode == 'pending') {
      return _buildAcceptRejectButtons(context, isUpdating, l10n);
    } else if (selectionMode == 'accepted') {
      return _buildPrepareButton(context, isUpdating, l10n);
    } else if (selectionMode == 'cancellable') {
      return _buildCancelOnlyButton(context, isUpdating, l10n);
    }

    return null;
  }

  Widget _buildAcceptRejectButtons(BuildContext context, bool isUpdating, BuildContext? l10n) {
    final theme = Theme.of(context);
    final selectedCount = _selectedItemIds.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TablerIcons.info_circle, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n?.tr('itemsSelected', positionalArgs: [selectedCount]) ?? '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isUpdating ? null : () => _handleReject(context, l10n),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.circle_x, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n?.tr('reject') ?? 'Reject'),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isUpdating ? null : () => _handleAccept(context, l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.circle_check, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n?.tr('accept') ?? 'Accept'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelOnlyButton(BuildContext context, bool isUpdating, BuildContext? l10n) {
    final theme = Theme.of(context);
    final selectedCount = _selectedItemIds.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(TablerIcons.info_circle, size: 14, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n?.tr('itemsSelected', positionalArgs: [selectedCount]) ?? '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: double.infinity, child: _buildCancelItemButton(context, isUpdating, l10n)),
        ],
      ),
    );
  }

  Widget _buildPrepareButton(BuildContext context, bool isUpdating, BuildContext? l10n) {
    final theme = Theme.of(context);
    final selectedCount = _selectedItemIds.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(TablerIcons.info_circle, size: 14, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n?.tr('itemsSelected', positionalArgs: [selectedCount]) ?? '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildCancelItemButton(context, isUpdating, l10n)),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isUpdating ? null : () => _handlePrepare(context, l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(TablerIcons.package, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n?.tr('markAsPreparing') ?? 'Mark as Preparing'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelItemButton(BuildContext context, bool isUpdating, BuildContext? l10n) {
    return OutlinedButton(
      onPressed: isUpdating ? null : () => _handleCancelItem(context, l10n),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isUpdating
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(TablerIcons.circle_x, size: 20),
                const SizedBox(width: 8),
                Text(l10n?.translateEnum('Cancel Item') ?? 'Cancel Item'),
              ],
            ),
    );
  }

  Widget _buildVerifyOtpButton(BuildContext context, BuildContext? l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isVerifyingOtp ? null : () => _showOtpDialog(context, widget.orderId, l10n),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isVerifyingOtp
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n?.translateEnum('Verifying...') ?? 'Verifying...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(TablerIcons.lock, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n?.translateEnum('Verify OTP') ?? 'Verify OTP'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMarkReadyButton(BuildContext context, OrderDetailsData data, bool isUpdating, BuildContext? l10n) {
    final theme = Theme.of(context);
    final allProductsReady = data.items!.every((item) {
      final itemId = item.orderItem?.id ?? item.id;
      return _selectedItemIds.contains(itemId);
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allProductsReady)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                l10n?.translateEnum('Please mark all products as prepared before proceeding.') ??
                    'Please mark all products as prepared before proceeding.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red[600], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!allProductsReady || isUpdating || _isMarkingReady)
                  ? null
                  : () => _handleMarkReadyForPickup(context, widget.orderId, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: (isUpdating || _isMarkingReady)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n?.translateEnum('Preparing...') ?? 'Preparing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(TablerIcons.circle_check, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n?.translateEnum('Mark Ready for Pickup') ?? 'Mark Ready for Pickup'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAccept(BuildContext context, BuildContext? l10n) {
    final state = context.read<OrderDetailsBloc>().state;
    final isPickup = state is OrderDetailsLoaded && state.orderData.deliveryType?.toLowerCase() == 'pickup';
    final hasPermission = isPickup
        ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
        : PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus);

    if (!hasPermission) {
      showCustomSnackbar(
        context: context,
        message: context.tr('youDontHavePermissionToUpdateOrderStatus'),
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showAcceptDialog(context, () async {
      await context.read<OrdersRepo>().bulkUpdateStatus('accept', selectedIds);
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }

  void _handleReject(BuildContext context, BuildContext? l10n) {
    final state = context.read<OrderDetailsBloc>().state;
    final isPickup = state is OrderDetailsLoaded && state.orderData.deliveryType?.toLowerCase() == 'pickup';
    final hasPermission = isPickup
        ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
        : PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus);

    if (!hasPermission) {
      showCustomSnackbar(
        context: context,
        message: context.tr('youDontHavePermissionToUpdateOrderStatus'),
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showRejectDialog(context, () async {
      await context.read<OrdersRepo>().bulkUpdateStatus('reject', selectedIds);
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }

  void _handlePrepare(BuildContext context, BuildContext? l10n) {
    final state = context.read<OrderDetailsBloc>().state;
    final isPickup = state is OrderDetailsLoaded && state.orderData.deliveryType?.toLowerCase() == 'pickup';
    final hasPermission = isPickup
        ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
        : PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus);

    if (!hasPermission) {
      showCustomSnackbar(
        context: context,
        message: context.tr('youDontHavePermissionToUpdateOrderStatus'),
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showPreparedDialog(context, () async {
      await context.read<OrdersRepo>().bulkUpdateStatus('preparing', selectedIds);
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }

  void _handleCancelItem(BuildContext context, BuildContext? l10n) {
    final state = context.read<OrderDetailsBloc>().state;
    final isPickup = state is OrderDetailsLoaded && state.orderData.deliveryType?.toLowerCase() == 'pickup';
    final hasPermission = isPickup
        ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
        : PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus);

    if (!hasPermission) {
      showCustomSnackbar(
        context: context,
        message: context.tr('youDontHavePermissionToUpdateOrderStatus'),
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    final _formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();

    // Capture the blocs from the page's context before showing the dialog
    final orderDetailsBloc = context.read<OrderDetailsBloc>();
    final ordersBloc = context.read<OrdersBloc>();
    final pageContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(builderContext).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(l10n?.translateEnum('Cancel Item') ?? 'Cancel Item'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.translateEnum('Please enter a reason for cancellation:') ??
                          'Please enter a reason for cancellation:',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: reasonController,
                      label: l10n?.translateEnum('Reason') ?? 'Reason',
                      hint: l10n?.translateEnum('Reason') ?? 'Reason',
                      isRequired: true,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n?.translateEnum('Reason is required') ?? 'Reason is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: l10n?.tr('cancel') ?? 'Cancel',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: l10n?.tr('submit') ?? 'Submit',
                        backgroundColor: Colors.red,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(dialogContext);

                            orderDetailsBloc.add(
                              CancelOrderItemsEvent(
                                itemIds: selectedIds,
                                reason: reasonController.text.trim(),
                                orderId: widget.orderId,
                              ),
                            );

                            if (pageContext.mounted) {
                              ordersBloc.add(RefreshOrders());
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleMarkReadyForPickup(BuildContext context, int parentOrderId, BuildContext? l10n) async {
    if (!PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus)) {
      showCustomSnackbar(
        context: context,
        message: context.tr('youDontHavePermissionToUpdateOrderStatus'),
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    setState(() {
      _isMarkingReady = true;
    });

    try {
      final response = await context.read<OrdersRepo>().markReadyForPickup(parentOrderId);

      final bool isSuccess = response != null && response['success'] == true;

      if (isSuccess) {
        if (context.mounted) {
          showCustomSnackbar(context: context, message: response['message'] ?? 'Order is ready for pickup.');
          context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
          context.read<OrdersBloc>().add(RefreshOrders());
        }
      } else {
        if (context.mounted) {
          showCustomSnackbar(
            context: context,
            message: response != null && response['message'] != null
                ? response['message'].toString()
                : 'Failed to update order status',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCustomSnackbar(context: context, message: e.toString().replaceAll("Exception: ", ""), isError: true);
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isMarkingReady = false;
        });
      }
    }
  }

  void _showOtpDialog(BuildContext context, int parentOrderId, BuildContext? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return OtpInputDialog(
          onVerify: (otp) async {
            final response = await context.read<OrdersRepo>().verifyPickupOtp(parentOrderId, otp);

            final bool isSuccess = response != null && response['success'] == true;

            if (isSuccess) {
              if (context.mounted) {
                showCustomSnackbar(context: context, message: response['message'] ?? 'Order completed successfully.');
                context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
                context.read<OrdersBloc>().add(RefreshOrders());
              }
            } else {
              final String errMsg = response != null && response['message'] != null
                  ? response['message'].toString()
                  : 'Invalid OTP or verification failed.';
              throw Exception(errMsg);
            }
          },
        );
      },
    );
  }
}

class _ExpandableOrderItem extends StatefulWidget {
  final int index;
  final OrderItemDetail item;
  final bool isSame;
  final String currencySymbol;
  final bool isLast;
  final bool isSelected;
  final bool isSelectable;
  final bool showCheckbox;
  final ValueChanged<bool>? onSelectionChanged;
  final String? rescheduleStatus;

  const _ExpandableOrderItem({
    required this.index,
    required this.item,
    required this.isSame,
    required this.currencySymbol,
    required this.isLast,
    this.isSelected = false,
    this.isSelectable = false,
    this.showCheckbox = false,
    this.onSelectionChanged,
    this.rescheduleStatus,
  });

  @override
  State<_ExpandableOrderItem> createState() => _ExpandableOrderItemState();
}

class _ExpandableOrderItemState extends State<_ExpandableOrderItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context;

    return Column(
      children: [
        Container(
          color: widget.isSelected ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Header - Always visible
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Styled Selection Indicator
                      if (widget.showCheckbox)
                        GestureDetector(
                          onTap: widget.isSelectable ? () => widget.onSelectionChanged?.call(!widget.isSelected) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(top: 2, right: 12),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected ? AppColors.primaryColor : Colors.transparent,
                              border: Border.all(
                                color: widget.isSelected ? AppColors.primaryColor : Colors.grey.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: widget.isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        ),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.product?.title ?? (l10n?.tr('notAvailable') ?? 'N/A'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: widget.isSelectable || widget.isSelected
                                    ? null
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  l10n?.tr('qtyWithCount', positionalArgs: [widget.item.quantity]) ?? 'Qty: ${widget.item.quantity}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${widget.currencySymbol} ${widget.item.subtotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            if ((widget.item.addons)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 6),
                              Text(
                                "${l10n?.tr('addOns') ?? "Add-Ons"} :",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              ...List.generate((widget.item.addons?.length) ?? 0, (addonsIndex) {
                                final addon = widget.item.addons![addonsIndex];
                                final groupTitle = addon.group?.title ?? (l10n?.tr('addOns') ?? "Add-On");
                                final itemTitle = addon.item?.title ?? "";

                                return Text(
                                  '$groupTitle: $itemTitle - ${widget.currencySymbol}${addon.price}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                );
                              }),
                            ],

                            // Move Status Badge below info
                            if ((widget.item.orderItem?.status ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildStatusChip(
                                context,
                                widget.rescheduleStatus == 'needs_reschedule'
                                    ? 'needs_reschedule'
                                    : widget.item.orderItem!.status,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Expand/Collapse Icon
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),

                  // Expanded Details
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (!widget.isSame)
                            _buildDetailRow(
                              context,
                              l10n?.tr('variant') ?? 'Variant',
                              widget.item.variant?.title ?? (l10n?.tr('notAvailable') ?? 'N/A'),
                            ),
                          _buildDetailRow(context, l10n?.tr('quantity') ?? 'Quantity', widget.item.quantity.toString()),
                          _buildDetailRow(
                            context,
                            l10n?.tr('price') ?? 'Price',
                            '${widget.currencySymbol} ${widget.item.price}',
                          ),
                          if ((widget.item.addons)?.isNotEmpty ?? false)
                            _buildDetailRow(
                              context,
                              l10n?.tr('addOns') ?? "Add-Ons",
                              '${widget.currencySymbol} ${widget.item.addonsTotal.toStringAsFixed(2)}',
                            ),

                          _buildDetailRow(
                            context,
                            l10n?.tr('subtotal') ?? 'Subtotal',
                            '${widget.currencySymbol} ${widget.item.subTotal}',
                            isLast: true,
                          ),
                          if (widget.item.attachments != null && widget.item.attachments!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n?.tr('attachments') ?? 'Attachments',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.item.attachments!.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final attachment = widget.item.attachments![index];
                                  final String url = attachment.toString();
                                  final isImage =
                                      url.toLowerCase().endsWith('.jpg') ||
                                      url.toLowerCase().endsWith('.jpeg') ||
                                      url.toLowerCase().endsWith('.png') ||
                                      url.toLowerCase().endsWith('.gif') ||
                                      url.toLowerCase().endsWith('.webp');

                                  return GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.colorScheme.outlineVariant),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: isImage
                                          ? CachedNetworkImage(
                                              imageUrl: url,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(child: CustomShimmer(width: 80, height: 80)),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(TablerIcons.file),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    url.split('/').last,
                                                    style: theme.textTheme.labelSmall,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Divider between items
        if (!widget.isLast)
          Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isLast = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final statusConfig = PickupUtils.getOrderStatusConfig(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: statusConfig.bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        statusConfig.label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusConfig.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
