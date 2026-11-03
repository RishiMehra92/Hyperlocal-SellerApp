import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

void showCustomSnackbar({
  required BuildContext context,
  required String message,
  bool isError = false,
  bool isWarning = false,
  Color? backgroundColor,
  String? actionLabel,
  VoidCallback? onAction,
  bool showAtTop = false,
}) {
  final Color snackBackgroundColor =
      backgroundColor ??
      (isWarning
          ? AppColors.pendingColor
          : isError
          ? AppColors.errorColor
          : AppColors.successColor);

  IconData icon;
  if (isWarning) {
    icon = Icons.warning_amber_rounded;
  } else if (isError) {
    icon = Icons.error_outline;
  } else {
    icon = Icons.check_circle_outline;
  }

  if (showAtTop) {
    // When showAtTop is passed (used in BottomSheets), we use an Overlay
    // to render it at the bottom OVER the BottomSheet.
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: snackBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: UIUtils.body(context.screenTypeRead),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
    return;
  }

  // Fallback to standard ScaffoldMessenger
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.hideCurrentSnackBar();
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: UIUtils.body(context.screenTypeRead),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                onAction();
              },
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: snackBackgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 4,
      duration: const Duration(seconds: 4),
    ),
  );
}
