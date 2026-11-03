import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';

class AddProductProcessBottomSheet extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepSelected;

  const AddProductProcessBottomSheet({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Down arrow for close
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF424242),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                context.tr('addProductsProcess'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  itemCount: totalSteps,
                  itemBuilder: (context, index) {
                    final step = index + 1;
                    bool isCompleted = step < currentStep;
                    bool isCurrent = step == currentStep;

                    Color cardBgColor;
                    Color circleColor;
                    Color circleBorderColor;
                    Color textColor;
                    Color subTextColor;
                    Color numberTextColor;

                    if (isCompleted) {
                      cardBgColor = isDark
                          ? const Color(0xFF161B22)
                          : Colors.white;
                      circleColor = Colors.transparent;
                      circleBorderColor = AppColors.stepCompletedColor;
                      textColor = isDark ? Colors.white : Colors.black;
                      subTextColor = AppColors.stepCompletedColor;
                      numberTextColor = AppColors.stepCompletedColor;
                    } else if (isCurrent) {
                      cardBgColor = isDark
                          ? AppColors.primaryColor.withValues(alpha: 0.15)
                          : AppColors.stepCurrentBgColor;
                      circleColor = AppColors.stepCurrentColor;
                      circleBorderColor = AppColors.stepCurrentColor;
                      textColor = isDark ? Colors.white : Colors.black;
                      subTextColor = isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B);
                      numberTextColor = Colors.white;
                    } else {
                      cardBgColor = isDark
                          ? const Color(0xFF161B22)
                          : AppColors.stepPendingBgColor;
                      circleColor = isDark
                          ? const Color(0xFF30363D)
                          : AppColors.stepPendingCircleColor;
                      circleBorderColor = isDark
                          ? const Color(0xFF30363D)
                          : AppColors.stepPendingCircleColor;
                      textColor = isDark ? Colors.grey.shade300 : Colors.black;
                      subTextColor = AppColors.stepPendingColor;
                      numberTextColor = isDark
                          ? Colors.grey.shade300
                          : Colors.black;
                    }

                    return GestureDetector(
                      onTap: () => onStepSelected(step),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isCompleted || isCurrent
                              ? Border.all(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFE2E8F0),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: circleColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: circleBorderColor,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "$step.",
                                style: TextStyle(
                                  color: numberTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getStepTitle(context, step),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    isCompleted
                                        ? context.tr('stepCompleted')
                                        : isCurrent
                                        ? context.tr('stepCurrent')
                                        : context.tr('stepPending'),
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStepTitle(BuildContext context, int step) {
    switch (step) {
      case 1:
        return context.tr('selectCategory');
      case 2:
        return context.tr('productsDescription');
      case 3:
        return context.tr('productInformation');
      case 4:
        return context.tr('productVariation');
      case 5:
        return context.tr('productImages');
      case 6:
        return context.tr('policiesAndFeatures');
      case 7:
        return context.tr('pricingAndTaxes');
      default:
        return "";
    }
  }
}
