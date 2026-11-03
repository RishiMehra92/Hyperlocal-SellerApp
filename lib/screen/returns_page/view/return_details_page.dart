import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_status_chip.dart';
import '../cubit/return_details_cubit.dart';
import '../cubit/returns_cubit.dart';
import '../model/order_return_model.dart';
import '../widgets/return_action_sheet.dart';
import '../widgets/return_card.dart';

class ReturnDetailsPage extends StatefulWidget {
  const ReturnDetailsPage({super.key});
  @override
  State<ReturnDetailsPage> createState() => _ReturnDetailsPageState();
}

class _ReturnDetailsPageState extends State<ReturnDetailsPage> {
  bool get _canView =>
      PermissionChecker.hasPermission(AppPermissions.returnView);
  @override
  void initState() {
    super.initState();
    if (_canView) context.read<ReturnDetailsCubit>().load();
  }

  Future<void> _action(String action, String title, bool store) async {
    final cubit = context.read<ReturnDetailsCubit>();
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ReturnActionSheet(
          action: action,
          title: title,
          storeConfirmation: store,
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<ReturnsCubit>().refresh();
      final message = cubit.state.operationMessage;
      if (message != null && message.isNotEmpty) {
        showCustomSnackbar(context: context, message: message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    return BlocBuilder<ReturnDetailsCubit, ReturnDetailsState>(
      builder: (context, state) {
        final details = state.details;
        return CustomScaffold(
          title: l10n.tr('returnsDetails'),
          showAppbar: true,
          body: !_canView
              ? Center(child: Text(l10n.tr('noPermissionViewReturns')))
              : details == null
              ? Center(
                  child: state.isLoading
                      ? const CustomLoadingIndicator()
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.error ?? l10n.tr('returnsNoReturns'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              PrimaryButton(
                                text: l10n.tr('retry'),
                                onPressed: context
                                    .read<ReturnDetailsCubit>()
                                    .load,
                              ),
                            ],
                          ),
                        ),
                )
              : RefreshIndicator(
                  onRefresh: context.read<ReturnDetailsCubit>().load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: UIUtils.pagePadding(context.screenType),
                    children: [
                      if (state.isLoading) const LinearProgressIndicator(),
                      if (state.enumsError != null)
                        Row(
                          children: [
                            Expanded(child: Text(state.enumsError!)),
                            TextButton(
                              onPressed: context
                                  .read<ReturnDetailsCubit>()
                                  .load,
                              child: Text(l10n.tr('retry')),
                            ),
                          ],
                        ),
                      ..._sections(details),
                    ],
                  ),
                ),
          bottomNavigationBar:
              _canView &&
                  details != null &&
                  !state.isLoading &&
                  state.enumsError == null
              ? _actions(state)
              : null,
        );
      },
    );
  }

  Widget? _actions(ReturnDetailsState state) {
    final item = state.details!;
    final l10n = context;
    if (!PermissionChecker.hasPermission(AppPermissions.returnDecide)) {
      return null;
    }
    final actions = <({String value, String title, bool store})>[
      if (item.canDecide) ...[
        if (state.enums.decisionActions.contains('approve'))
          (value: 'approve', title: l10n.tr('returnsApprove'), store: false),
        if (state.enums.decisionActions.contains('reject'))
          (value: 'reject', title: l10n.tr('returnsReject'), store: false),
      ],
      if (item.canInspectReceivedReturn) ...[
        if (state.enums.storeConfirmActions.contains('approve'))
          (value: 'approve', title: l10n.tr('returnsConfirmReceipt'), store: true),
        if (state.enums.storeConfirmActions.contains('escalate'))
          (value: 'escalate', title: l10n.tr('returnsEscalate'), store: true),
      ],
    ];
    if (actions.isEmpty) return null;
    return SafeArea(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final action in actions)
              PrimaryButton(
                text: action.title,
                isLoading: state.isUpdating,
                onPressed: state.isUpdating
                    ? null
                    : () => _action(action.value, action.title, action.store),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(OrderReturn item) {
    final l10n = context;
    final request = item.customerRequest,
        pickup = item.pickup,
        inspection = item.confirmation;
    return [
      _section(l10n.tr('returnsDetails'), [
        CustomStatusChip(
          label: item.statusLabel,
          baseColor: Theme.of(context).colorScheme.tertiary,
          screenType: context.screenType,
        ),
        _row('ID', '${item.id}'),
        _row(l10n.tr('returnsCreatedAt'), _date(item.createdAt)),
        _row(l10n.tr('returnsPickupStatus'), item.pickupStatus),
        if (item.isDisputed || item.disputeReason.isNotEmpty) ...[
          _row(l10n.tr('returnsDisputeReason'), item.disputeReason),
          _row(l10n.tr('returnsDisputedAt'), _date(item.disputedAt)),
        ],
        _row(l10n.tr('returnsRefundAmount'), returnMoney(item.refundAmount)),
      ]),
      _section(l10n.tr('orders'), [
        _row(
          l10n.tr('returnsOrderNumber'),
          item.orderNumber.isEmpty
              ? '${item.orderId ?? '—'}'
              : item.orderNumber,
        ),
        if (item.orderItemId != null)
          _row(l10n.tr('returnsOrderItem'), '${item.orderItemId}'),
        _row(l10n.tr('store'), item.store.name),
        if (item.orderId != null &&
            PermissionChecker.hasPermission(AppPermissions.orderView))
          TextButton(
            onPressed: () =>
                context.push('${AppRoutes.orderDetails}/${item.orderId}'),
            child: Text(l10n.tr('orderDetails')),
          ),
      ]),
      _section(l10n.tr('product'), [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomNetworkImage(
              imageUrl: item.product.image,
              width: 72,
              height: 72,
              borderRadius: 8,
              errorWidget: const Icon(Icons.inventory_2_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.product.variantTitle.isNotEmpty)
                    Text(item.product.variantTitle),
                ],
              ),
            ),
          ],
        ),
        if (item.product.quantity != null)
          _row(l10n.tr('quantity'), '${item.product.quantity}'),
        if (item.product.unitPrice != null)
          _row(l10n.tr('returnsUnitPrice'), returnMoney(item.product.unitPrice)),
        for (final addon in item.product.addons)
          _row(addon.title, returnMoney(addon.price)),
      ]),
      if (request != null)
        _section(l10n.tr('returnsCustomerRequest'), [
          _row(l10n.tr('returnsReason'), request.reason),
          _row(l10n.tr('returnsDescription'), request.description),
          _photos(request.proofImages),
        ]),
      _section(l10n.tr('returnsCustomer'), [
        Row(
          children: [
            CustomNetworkImage(
              imageUrl: item.customer.image,
              width: 48,
              height: 48,
              isCircle: true,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.customer.name)),
          ],
        ),
        _row(l10n.tr('returnsMobile'), item.customer.mobile),
        _row(l10n.tr('email'), item.customer.email),
      ]),
      if (item.refundItems.isNotEmpty || item.refundTotal != null)
        _section(l10n.tr('returnsRefundBreakdown'), [
          for (final refund in item.refundItems)
            _row(refund.label, returnMoney(refund.amount)),
          if (item.refundTotal != null)
            _row(l10n.tr('total'), returnMoney(item.refundTotal)),
        ]),
      if (pickup != null)
        _section(l10n.tr('returnsPickupDetails'), [
          _row(l10n.tr('returnsRider'), pickup.riderName),
          _row(l10n.tr('returnsMobile'), pickup.riderMobile),
          _row(l10n.tr('returnsCondition'), pickup.condition),
          _row(l10n.tr('returnsRemarks'), pickup.remarks),
          if (pickup.otpRequired != null)
            _row(
              l10n.tr('returnsOtpRequired'),
              pickup.otpRequired! ? l10n.tr('yes') : l10n.tr('no'),
            ),
          if (pickup.otpVerified != null)
            _row(
              l10n.tr('returnsOtpVerified'),
              pickup.otpVerified! ? l10n.tr('yes') : l10n.tr('no'),
            ),
          if (pickup.otp.isNotEmpty) _row('OTP', pickup.otp),
          _row(l10n.tr('returnsPickedUpAt'), _date(pickup.pickedUpAt)),
          _photos(pickup.photos),
        ]),
      if (inspection != null)
        _section(l10n.tr('returnsInspection'), [
          _row(l10n.tr('returnsReceivedAt'), _date(inspection.receivedAt)),
          _row(l10n.tr('returnsRemarks'), inspection.sellerComment),
          _row(l10n.tr('returnsApprovedAt'), _date(inspection.approvedAt)),
          _row(l10n.tr('returnsRefundAt'), _date(inspection.refundProcessedAt)),
          _photos(inspection.photos),
        ]),
      if (item.timeline.isNotEmpty)
        _section(l10n.tr('returnsTimeline'), [
          for (final entry in item.timeline)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    entry.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: entry.done
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.label),
                        if (entry.at != null)
                          Text(
                            _date(entry.at),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ]),
    ];
  }

  String _date(DateTime? value) => value == null
      ? ''
      : DateFormat.yMMMd(
          Localizations.localeOf(context).languageCode,
        ).add_jm().format(value.toLocal());
  Widget _row(String label, String value) => value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(value, textAlign: TextAlign.end)),
            ],
          ),
        );
  Widget _section(String title, List<Widget> children) => Container(
    margin: EdgeInsets.only(bottom: UIUtils.gapMD(context.screenType)),
    padding: UIUtils.cardPadding(context.screenType),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(UIUtils.radiusLG(context.screenType)),
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant,
        width: 0.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: UIUtils.sectionTitle(context.screenType),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
  Widget _photos(List<String> urls) => urls.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final url in urls)
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: InteractiveViewer(
                              child: CustomNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: CustomNetworkImage(
                    imageUrl: url,
                    width: 88,
                    height: 88,
                    borderRadius: 8,
                  ),
                ),
            ],
          ),
        );
}
