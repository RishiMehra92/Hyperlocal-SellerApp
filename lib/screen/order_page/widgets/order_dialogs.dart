import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class OrderDialogs {
  static void showAcceptDialog(BuildContext context, Future<void> Function() onConfirm) {
    showAppAlertDialog(
      context: context,
      title: context.tr('acceptOrderTitle'),
      message: context.tr('acceptOrderConfirmation'),
      svgPath: ImagesPath.acceptSvg,
      size: 24,
      padding: 24,
      iconColor: Colors.green,
      confirmColor: Colors.green,
      confirmText: context.tr('accept'),
      onConfirm: () async {
        await _handleAction(context, onConfirm, context.tr('orderAccepted'));
      },
    );
  }

  static void showRejectDialog(BuildContext context, Future<void> Function() onConfirm) {
    showAppAlertDialog(
      context: context,
      title: context.tr('rejectOrderTitle'),
      message: context.tr('rejectOrderConfirmation'),
      svgPath: ImagesPath.rejectSvg,
      iconColor: Colors.red,
      confirmColor: Colors.red,
      confirmText: context.tr('reject'),
      onConfirm: () async {
        await _handleAction(context, onConfirm, context.tr('orderRejected'));
      },
    );
  }

  static void showPreparedDialog(BuildContext context, Future<void> Function() onConfirm) {
    showAppAlertDialog(
      context: context,
      title: context.tr('markAsPreparedTitle'),
      message: context.tr('markAsPreparedConfirmation'),
      svgPath: ImagesPath.markAsPrepareSvg,
      iconColor: Colors.blue,
      confirmText: context.tr('markAsPreparedTitle'),
      size: 36,
      padding: 12,
      onConfirm: () async {
        await _handleAction(context, onConfirm, context.tr('orderMarkedAsPrepared'));
      },
    );
  }

  static Future<void> _handleAction(BuildContext context, Future<void> Function() onConfirm, String message) async {
    // Check Guard first
    final bool allowed = DemoGuard.shouldProceed(context);
    if (!allowed) {
      // If not allowed, DemoGuard already showed a snackbar.
      // We just return immediately.
      return;
    }

    _showLoading(context);
    try {
      await onConfirm();
      if (context.mounted) {
        _hideLoading(context);
        showCustomSnackbar(context: context, message: message);
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        showCustomSnackbar(context: context, message: e.toString().replaceAll("Exception: ", ""), isError: true);
      }
    }
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
