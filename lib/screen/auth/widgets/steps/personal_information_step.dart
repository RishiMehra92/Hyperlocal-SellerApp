import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/auth/bloc/verify-user/verify_user_bloc.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_phone_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

/// Resolves the settings-API dial code (e.g. "91") to an ISO-2 country code
/// (e.g. "IN") that IntlPhoneField's `initialCountryCode` expects. Falls back
/// to "IN" when the dial code is empty or unrecognised.
String _initialIsoFromDialCode(String dialCode) {
  final cleaned = dialCode.replaceAll('+', '').trim();
  if (cleaned.isEmpty) return 'IN';
  final match = countries.firstWhere(
    (c) => c.dialCode == cleaned,
    orElse: () => countries.firstWhere((c) => c.code == 'IN', orElse: () => countries.first),
  );
  return match.code;
}

class PersonalInformationStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode nameFocusNode;
  final FocusNode mobileFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final Function(String code, String flag) onCountryChanged;
  final String selectedCountryCode;
  final String selectedCountryFlag;
  final Function(bool isValid)? onValidationStatusChanged;

  const PersonalInformationStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocusNode,
    required this.mobileFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.onCountryChanged,
    required this.selectedCountryCode,
    required this.selectedCountryFlag,
    this.onValidationStatusChanged,
  });

  @override
  State<PersonalInformationStep> createState() => _PersonalInformationStepState();
}

class _PersonalInformationStepState extends State<PersonalInformationStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Debouncer _emailDebouncer = Debouncer(milliseconds: 500);
  final Debouncer _phoneDebouncer = Debouncer(milliseconds: 500);

  bool _isEmailVerifying = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerifying = false;
  bool _isPhoneVerified = false;

  String? _emailVerificationError;
  String? _phoneVerificationError;
  PhoneNumber? _currentPhone;

  @override
  void initState() {
    super.initState();

    // Add listeners for email verification
    widget.emailController.addListener(_onEmailChanged);

    // Add listeners for phone verification
    widget.mobileController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _emailDebouncer.dispose();
    _phoneDebouncer.dispose();
    widget.emailController.removeListener(_onEmailChanged);
    widget.mobileController.removeListener(_onPhoneChanged);
    super.dispose();
  }

  void _updateValidationStatus() {
    final isValid =
        !_isEmailVerifying && !_isPhoneVerifying && _emailVerificationError == null && _phoneVerificationError == null;
    widget.onValidationStatusChanged?.call(isValid);
  }

  void _onEmailChanged() {
    final email = widget.emailController.text.trim();

    // Clear error and verification state when user starts typing
    if (_emailVerificationError != null || _isEmailVerified) {
      setState(() {
        _emailVerificationError = null;
        _isEmailVerified = false;
      });
      _updateValidationStatus();
    }

    // Validate email format before making API call
    if (email.isNotEmpty) {
      // Basic email validation regex
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

      if (emailRegex.hasMatch(email)) {
        setState(() {
          _isEmailVerifying = true;
        });
        _updateValidationStatus();
        _emailDebouncer.run(() {
          context.read<VerifyUserBloc>().add(VerifyUserEmail('email', email));
        });
      }
    } else {
      setState(() {
        _isEmailVerifying = false;
        _isEmailVerified = false;
      });
      _updateValidationStatus();
    }
  }

  void _onPhoneChanged() {
    final phone = widget.mobileController.text.trim();

    // Clear error and verification state when user starts typing
    if (_phoneVerificationError != null || _isPhoneVerified) {
      setState(() {
        _phoneVerificationError = null;
        _isPhoneVerified = false;
      });
      _updateValidationStatus();
    }

    bool isValid = false;
    try {
      isValid = _currentPhone?.isValidNumber() ?? false;
    } catch (e) {
      isValid = false;
    }

    // Only ping duplicate-check API when number is valid according to country rules
    if (phone.isNotEmpty && isValid) {
      setState(() {
        _isPhoneVerifying = true;
      });
      _updateValidationStatus();
      _phoneDebouncer.run(() {
        context.read<VerifyUserBloc>().add(VerifyUserPhone('mobile', phone));
      });
    } else {
      setState(() {
        _isPhoneVerifying = false;
        _isPhoneVerified = false;
      });
      _updateValidationStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    return BlocListener<VerifyUserBloc, VerifyUserState>(
      listener: (context, state) {
        if (state is VerifyUserLoading) {
          setState(() {
            if (state.type == 'email') {
              _isEmailVerifying = true;
              _isEmailVerified = false;
              _emailVerificationError = null;
            } else if (state.type == 'mobile') {
              _isPhoneVerifying = true;
              _isPhoneVerified = false;
              _phoneVerificationError = null;
            }
          });
          _updateValidationStatus();
        } else if (state is VerifyUserAlreadyExists) {
          setState(() {
            if (state.type == 'email') {
              _isEmailVerifying = false;
              _isEmailVerified = false;
              _emailVerificationError = l10n?.tr('thisEmailIsAlreadyTaken') ?? state.message;
            } else if (state.type == 'mobile') {
              _isPhoneVerifying = false;
              _isPhoneVerified = false;
              _phoneVerificationError = l10n?.tr('thisPhoneNumberIsAlreadyTaken') ?? state.message;
            }
          });
          _updateValidationStatus();
          widget.formKey.currentState?.validate();
        } else if (state is VerifyUserValid) {
          setState(() {
            if (state.type == 'email') {
              _isEmailVerifying = false;
              _isEmailVerified = true;
              _emailVerificationError = null;
            } else if (state.type == 'mobile') {
              _isPhoneVerifying = false;
              _isPhoneVerified = true;
              _phoneVerificationError = null;
            }
          });
          _updateValidationStatus();
          widget.formKey.currentState?.validate();
        } else if (state is VerifyUserError) {
          setState(() {
            if (state.type == 'email') {
              _isEmailVerifying = false;
              _isEmailVerified = false;
              _emailVerificationError = state.message;
            } else if (state.type == 'mobile') {
              _isPhoneVerifying = false;
              _isPhoneVerified = false;
              _phoneVerificationError = state.message;
            }
          });
          _updateValidationStatus();
          widget.formKey.currentState?.validate();
        }
      },
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: l10n?.tr('sellerName') ?? 'Seller Name',
              isRequired: true,
              hint: context.tr('enterName'),
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: widget.nameFocusNode,
            ),
            const SizedBox(height: 20),

            CustomPhoneField(
              label: l10n?.tr('mobileNumber') ?? "Mobile Number",
              isRequired: true,
              controller: widget.mobileController,
              focusNode: widget.mobileFocusNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              initialCountryCode: _initialIsoFromDialCode(HiveStorage.countryDialCode),
              suffixIcon: _buildPhoneSuffixIcon(),
              onChanged: (phone) {
                _currentPhone = phone;
              },
              onCountryChanged: (countryCode) {
                widget.formKey.currentState?.validate();
                _onPhoneChanged();
              },
              validator: (PhoneNumber? phone) {
                if (phone == null || phone.number.trim().isEmpty) {
                  return context.tr('fieldRequired') ?? 'Enter mobile number';
                }

                bool isValid = false;
                try {
                  isValid = phone.isValidNumber();
                } catch (e) {
                  isValid = false;
                }

                if (!isValid) {
                  return context.tr('invalidPhone') ?? 'Invalid phone number';
                }

                final formatErr = ValidatorUtils.validatePhone(context, phone.number);
                return formatErr ?? _phoneVerificationError;
              },
            ),

            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.tr('emailAddress') ?? 'Email Address',
              isRequired: true,
              hint: l10n?.tr('enterYourEmailAddress') ?? 'Enter Your Email Address',
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(text: newValue.text.toLowerCase()),
                ),
              ],
              suffixIcon: _buildEmailSuffixIcon(),
              validator: (value) {
                final formatErr = ValidatorUtils.validateEmail(context, value);
                // Surface format error first; otherwise surface the
                // verify-user API "already taken" error so the form blocks
                // Next on duplicates.
                return formatErr ?? _emailVerificationError;
              },
              focusNode: widget.emailFocusNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.tr('password') ?? 'Password',
              isRequired: true,
              hint: l10n?.tr('enterPassword') ?? 'Enter Password',
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) => ValidatorUtils.validatePassword(context, value),
              focusNode: widget.passwordFocusNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.tr('confirmPassword') ?? 'Confirm Password',
              isRequired: true,
              hint: l10n?.tr('confirmYourPassword') ?? 'Confirm Your Password',
              controller: widget.confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (value) =>
                  ValidatorUtils.validateConfirmPassword(context, value, widget.passwordController.text),
              focusNode: widget.confirmPasswordFocusNode,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget? _buildEmailSuffixIcon() {
    if (_isEmailVerifying) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    }
    if (_isEmailVerified) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_emailVerificationError != null) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return null;
  }

  Widget? _buildPhoneSuffixIcon() {
    if (_isPhoneVerifying) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    }
    if (_isPhoneVerified) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_phoneVerificationError != null) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return null;
  }
}
