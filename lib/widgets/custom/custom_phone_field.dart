import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:hyper_local_seller/config/colors.dart';

class CustomPhoneField extends StatefulWidget {
  final String? label;
  final String? hint;
  final bool isRequired;
  final TextEditingController? controller;
  final ValueChanged<PhoneNumber>? onChanged;
  final String? Function(PhoneNumber?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final String initialCountryCode;
  final ValueChanged<String>? onCountryChanged;
  final Widget? suffixIcon;
  final bool disableLengthCheck;
  final List<String>? countries;
  final List<TextInputFormatter>? inputFormatters;

  const CustomPhoneField({
    super.key,
    this.label,
    this.hint,
    this.isRequired = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.initialCountryCode = 'IN',
    this.onCountryChanged,
    this.suffixIcon,
    this.disableLengthCheck = true,
    this.countries,
    this.inputFormatters,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  PhoneNumber? _currentPhone;
  late String _currentCountryCode;

  @override
  void initState() {
    super.initState();
    _currentCountryCode = widget.initialCountryCode;
    if (widget.controller != null && widget.controller!.text.isNotEmpty) {
      _currentPhone = PhoneNumber(
        countryISOCode: _currentCountryCode,
        countryCode: '',
        number: widget.controller!.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tertiary = theme.colorScheme.tertiary;

    return FormField<String>(
      autovalidateMode: widget.autovalidateMode,
      initialValue: widget.controller?.text,
      validator: (val) {
        if (widget.validator != null) {
          if (widget.controller != null && widget.controller!.text.isEmpty) {
            _currentPhone = null;
          }
          return widget.validator!(_currentPhone);
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              RichText(
                text: TextSpan(
                  text: widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tertiary,
                  ),
                  children: [
                    if (widget.isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            IntlPhoneField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              autovalidateMode: AutovalidateMode.disabled,
              initialCountryCode: widget.initialCountryCode,
              disableLengthCheck: widget.disableLengthCheck,
              textInputAction: TextInputAction.done,
              inputFormatters: widget.inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 15,
                color: widget.enabled ? tertiary : Colors.grey,
              ),
              cursorColor: AppColors.primaryColor,
              dropdownTextStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              decoration: InputDecoration(
                errorText: state.errorText,
                suffixIcon: widget.suffixIcon,
                hintText: widget.hint ?? 'Enter your mobile number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: widget.enabled
                    ? (isDark ? const Color(0xFF0D1117) : Colors.white)
                    : (isDark ? const Color(0xFF161B22) : Colors.grey.shade100),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.darkErrorColor,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.darkErrorColor,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              languageCode: "en",
              onChanged: (phone) {
                _currentPhone = phone;
                _currentCountryCode = phone.countryISOCode;
                state.didChange(phone.number);
                widget.onChanged?.call(phone);
                widget.onCountryChanged?.call(phone.countryCode);
              },
              onCountryChanged: (country) {
                _currentCountryCode = country.code;
                if (widget.controller != null) {
                  _currentPhone = PhoneNumber(
                    countryISOCode: _currentCountryCode,
                    countryCode: '+${country.dialCode}',
                    number: widget.controller!.text,
                  );
                }
                widget.onCountryChanged?.call(country.code);
                state.didChange(widget.controller?.text ?? '');
              },
              validator: (val) {
                return null;
              },
              // Customize the country picker dialog
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              dropdownIcon: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey,
              ),
              showDropdownIcon: true,
              dropdownIconPosition: IconPosition.trailing,
              // Custom country picker theme
              pickerDialogStyle: PickerDialogStyle(
                backgroundColor: theme.colorScheme.surface,
                searchFieldCursorColor: AppColors.primaryColor,
                searchFieldInputDecoration: InputDecoration(
                  hintText: context.tr('searchCountry'),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0D1117)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
