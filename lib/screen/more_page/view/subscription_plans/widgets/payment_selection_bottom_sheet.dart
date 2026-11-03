import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/currency_helper.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/user_helper.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/repo/wallet_repo.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

class PaymentSelectionBottomSheet extends StatefulWidget {
  final Map<String, dynamic> paymentSettings;
  final Function(String method) onPaymentMethodSelected;
  final String? defaultPaymentMethod;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.paymentSettings,
    required this.onPaymentMethodSelected,
    this.defaultPaymentMethod,
  });

  @override
  State<PaymentSelectionBottomSheet> createState() =>
      _PaymentSelectionBottomSheetState();
}

class _PaymentSelectionBottomSheetState
    extends State<PaymentSelectionBottomSheet> {
  String? _selectedMethod;
  bool _isLoadingWallet = false;
  String _walletBalance = UserHelper.walletBalance;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.defaultPaymentMethod;
    if (widget.paymentSettings['wallet'] == true) {
      _fetchLatestWalletBalance();
    }
  }

  Future<void> _fetchLatestWalletBalance() async {
    setState(() {
      _isLoadingWallet = true;
    });
    try {
      final repo = WalletRepository();
      final response = await repo.fetchWallet();

      if (response != null && response.success == true) {
        final balanceStr = response.data?.balance;
        if (balanceStr != null) {
          final balance = double.tryParse(balanceStr) ?? 0.0;
          setState(() {
            _walletBalance = balance.toStringAsFixed(2);
          });
          // Also update HiveStorage for consistency
          HiveStorage.setWalletBalance(balance.toStringAsFixed(2));
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch latest wallet balance: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);
    final st = context.screenType;

    final List<Map<String, dynamic>> methods = _buildPaymentMethods(l10n);

    return Container(
      padding: EdgeInsets.only(
        left: UIUtils.gapLG(st),
        right: UIUtils.gapLG(st),
        top: UIUtils.gapLG(st),
        bottom: UIUtils.gapLG(st) + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.tr('selectPaymentMethod') ?? 'Select Payment Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: methods.length,
              separatorBuilder: (context, index) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final method = methods[index];
                final isSelected = _selectedMethod == method['id'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMethod = method['id'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : theme.dividerColor.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (method['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              (method['isPng'] == true ||
                                  (method['img'] as String).endsWith('.png'))
                              ? Image.asset(
                                  method['img'] as String,
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.contain,
                                )
                              : CustomSvg(
                                  svgPath: method['img'] as String,
                                  colorFilterOn: method['color_filter'] as bool,
                                  color: method['color_filter']
                                      ? method['color'] as Color
                                      : null,
                                  height: 24,
                                  width: 24,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              if (method['id'] == 'wallet')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _isLoadingWallet
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryColor,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          '${CurrencyHelper.symbol}$_walletBalance',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryColor,
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            color: theme.dividerColor.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          PrimaryButton(
            text: l10n?.tr('proceedToPay') ?? 'Proceed to Pay',
            onPressed: _selectedMethod == null
                ? null
                : () {
                    if (!DemoGuard.shouldProceed(context)) {
                      Navigator.pop(context);
                      return;
                    } else {
                      widget.onPaymentMethodSelected(_selectedMethod!);
                      Navigator.pop(context);
                    }
                  },
            borderRadius: 16,
            height: 56,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildPaymentMethods(BuildContext? l10n) {
    final List<Map<String, dynamic>> methods = [];

    if (widget.paymentSettings['stripePayment'] == true) {
      methods.add({
        'id': 'stripePayment',
        'title':
            // l10n?.tr('stripe') ??
            'Stripe',
        'img': ImagesPath.stripeSvg,
        'color': Colors.indigo,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['razorpayPayment'] == true) {
      methods.add({
        'id': 'razorpayPayment',
        'title':
            // l10n?.tr('razorpay') ??
            'Razorpay',
        'img': ImagesPath.razorpaySvg,
        'color': Colors.blue,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['paystackPayment'] == true) {
      methods.add({
        'id': 'paystackPayment',
        'title':
            // l10n?.tr('paystack') ??
            'Paystack',
        'img': ImagesPath.paystackSvg,
        'color': Colors.cyan,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['flutterwavePayment'] == true) {
      methods.add({
        'id': 'flutterwavePayment',
        'title':
            // l10n?.tr('flutterwave') ??
            'Flutterwave',
        'img': ImagesPath.flutterWaveSvg,
        'color': Colors.orange,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['xenditPayment'] == true ||
        widget.paymentSettings['xendit'] == true ||
        widget.paymentSettings['xendit_payment'] == true) {
      final id = widget.paymentSettings['xenditPayment'] == true
          ? 'xenditPayment'
          : (widget.paymentSettings['xendit'] == true
                ? 'xendit'
                : 'xendit_payment');
      methods.add({
        'id': id,
        'title': 'Xendit',
        'img': ImagesPath.xenditPng,
        'color': const Color(0xFF0052FF),
        'color_filter': false,
        'isPng': true,
      });
    }

    if (widget.paymentSettings['paypalPayment'] == true ||
        widget.paymentSettings['paypal'] == true ||
        widget.paymentSettings['payPalPayment'] == true) {
      methods.add({
        'id': 'paypalPayment',
        'title': 'PayPal',
        'img': ImagesPath.paypalSvg,
        'color': Colors.blue,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['phonepePayment'] == true ||
        widget.paymentSettings['phonepe'] == true ||
        widget.paymentSettings['phonePePayment'] == true) {
      methods.add({
        'id': 'phonepePayment',
        'title': 'PhonePe',
        'img': ImagesPath.phonepeSvg,
        'color': Colors.deepPurple,
        'color_filter': false,
      });
    }

    if (widget.paymentSettings['wallet'] == true) {
      methods.add({
        'id': 'wallet',
        'title': l10n?.tr('wallet') ?? 'Wallet',
        'img': ImagesPath.walletSvg,
        'color': Colors.green,
        'color_filter': true,
      });
    }

    return methods;
  }
}
