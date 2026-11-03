import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;

  const OtpInput({super.key, required this.onCompleted});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // Handle paste of full/partial OTP
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _controllers.length; i++) {
        if (index + i < digits.length) {
          _controllers[index + i].text = digits[i];
        }
      }
      final lastFilledIndex = (index + digits.length - 1).clamp(0, 5);
      _focusNodes[lastFilledIndex].requestFocus();

      if (_controllers.every((c) => c.text.isNotEmpty)) {
        final otp = _controllers.map((c) => c.text).join();
        widget.onCompleted(otp);
      }
      return;
    }

    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final otp = _controllers.map((c) => c.text).join();
        widget.onCompleted(otp);
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: UIUtils.inputHeight(screenType) * 1.2,
          height: UIUtils.inputHeight(screenType) * 1.4,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            // maxLength: 1,
            style: TextStyle(
              fontSize: UIUtils.appTitle(screenType),
              fontWeight: UIUtils.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            onChanged: (value) => _onChanged(value, index),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusMD(screenType),
                ),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusMD(screenType),
                ),
                borderSide: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusMD(screenType),
                ),
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.mainDarkContainerBgColor
                  : Colors.white,
            ),
          ),
        );
      }),
    );
  }
}
