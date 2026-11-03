// ignore_for_file: deprecated_member_use

import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';

/// Full screen widget displayed when app is under maintenance
class MaintenanceScreen extends StatelessWidget {
  final String? message;

  const MaintenanceScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CustomSvg(
                  svgPath: ImagesPath.underMaintenanceSvg,
                  width: 220,
                  height: 220,
                  colorFilterOn: false,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.tr('appUnderMaintenance'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppConstants.fontFamily,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message ?? l10n.tr('maintenanceMessage'),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppConstants.fontFamily,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
