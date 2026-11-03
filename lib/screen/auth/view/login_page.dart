import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/utils/formatters.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/auth/bloc/verify-user/verify_user_bloc.dart';
import 'package:hyper_local_seller/screen/auth/widgets/auth_header.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_phone_field.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/router/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoginEnabled = false;
  bool _isPhoneLoginEnabled = false;
  String _completePhoneNumber = '';
  late TabController _tabController;

  bool _isPhoneVerifying = false;
  bool _isPhoneVerified = false;
  String? _phoneVerificationError;
  String _phoneNum = '';
  final Debouncer _phoneDebouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _emailController.addListener(_updateLoginState);
    _passwordController.addListener(_updateLoginState);
    _phoneController.addListener(_updatePhoneLoginState);

    if (HiveStorage.demoMode) {
      _emailController.text = 'demoseller@gmail.com';
      _passwordController.text = '12345678';
      _updateLoginState();
    } else if (kDebugMode) {
      _emailController.text = 'seller@gmail.com';
      _passwordController.text = '12345678';
      _updateLoginState();
    } else {
      _emailController.text = '';
      _passwordController.text = '';
      _updateLoginState();
    }
  }

  void _updateLoginState() {
    final isEnabled =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    if (_isLoginEnabled != isEnabled) {
      setState(() {
        _isLoginEnabled = isEnabled;
      });
    }
  }

  void _updatePhoneLoginState() {
    final isEnabled =
        _phoneController.text.trim().isNotEmpty &&
        _completePhoneNumber.isNotEmpty &&
        _isPhoneVerified &&
        !_isPhoneVerifying &&
        _phoneVerificationError == null;

    if (_isPhoneLoginEnabled != isEnabled) {
      setState(() {
        _isPhoneLoginEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.removeListener(_updateLoginState);
    _passwordController.removeListener(_updateLoginState);
    _phoneController.removeListener(_updatePhoneLoginState);
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _phoneDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    log('::::::::: systemVendorType ::::::::: ${HiveStorage.systemVendorType}');

    return CustomScaffold(
      showAppbar: false,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthFailure) {
            showCustomSnackbar(
              context: context,
              message: state.error,
              isError: true,
            );
          } else if (state is AuthSuccess) {
            // IMPORTANT: Refresh all data BEFORE navigating.
            // This ensures BLoCs fetch fresh data with the new token
            // before the home screen widgets try to read state.

            await HiveStorage.setHasLoggedInBefore(true);

            // Navigate based on subscription availability and active plan
            if (HiveStorage.isSubscriptionAvailable &&
                (HiveStorage.activePlanId == null ||
                    HiveStorage.activePlanId == 0) &&
                HiveStorage.pendingSubscriptionId == null) {
              context.go(AppRoutes.subscriptionChoosePlan);
            } else {
              context.go(AppRoutes.home);
            }

            showCustomSnackbar(context: context, message: state.message);
          } else if (state is AuthOTPSent) {
            // Navigate to OTP verification page
            showCustomSnackbar(context: context, message: state.message);
            context.push(
              AppRoutes.otp,
              extra: {
                'verificationId': state.verificationId,
                'phoneNumber': state.phoneNumber,
              },
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const AuthHeader(
                    title: '',
                    subtitle: '',
                    showBackButton: false,
                  ),
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: UIUtils.gapLG(screenType)),
                        Text(
                          !HiveStorage.hasLoggedInBefore
                              ? (l10n?.tr('heyThere') ?? "Hey There!")
                              : (l10n?.tr('welcomeBack') ?? "Welcome Back"),
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamily,
                            fontWeight: UIUtils.bold,
                            fontSize: UIUtils.appTitle(screenType),
                            color: isDark
                                ? AppColors.darkFontColor
                                : AppColors.lightFontColor,
                          ),
                        ),
                        SizedBox(height: UIUtils.gapSM(screenType)),
                        Text(
                          l10n?.tr('signInToContinue') ??
                              "Sign in to your account to continue",
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamily,
                            fontSize: UIUtils.body(screenType),
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: UIUtils.gapXL(screenType)),
                        // TabBar
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.mainDarkContainerBgColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(
                              UIUtils.radiusMD(screenType),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(
                                UIUtils.radiusMD(screenType),
                              ),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark
                                ? Colors.grey
                                : Colors.black54,
                            labelStyle: TextStyle(
                              fontFamily: AppConstants.fontFamily,
                              fontWeight: UIUtils.bold,
                              fontSize: UIUtils.body(screenType),
                            ),
                            tabs: [
                              Tab(text: context.tr('email')),
                              Tab(text: context.tr('phone')),
                            ],
                          ),
                        ),
                        SizedBox(height: UIUtils.gapXL(screenType)),
                        // TabBarView
                        SizedBox(
                          height: screenType == ScreenType.tablet ? 400 : 250,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Email Tab
                              _buildEmailTab(context, l10n, screenType, isDark),
                              // Phone Tab
                              _buildPhoneTab(context, l10n, screenType),
                            ],
                          ),
                        ),
                        if (HiveStorage.systemVendorType != 'single') ...[
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: UIUtils.gapMD(screenType),
                                ),
                                child: Text(
                                  l10n?.tr('or') ?? "OR",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontFamily: AppConstants.fontFamily,
                                    fontSize: UIUtils.body(screenType),
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          SizedBox(height: UIUtils.gapSM(screenType)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n?.tr('dontHaveAccount') ?? "Don't have Account?",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: AppConstants.fontFamily,
                                  fontSize: UIUtils.body(screenType),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push('/signup');
                                },
                                child: Text(
                                  l10n?.tr('signUp') ?? "Sign Up",
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: UIUtils.bold,
                                    fontFamily: AppConstants.fontFamily,
                                    fontSize: UIUtils.body(screenType),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Full-screen loading overlay
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withValues(
                      alpha: 0.4,
                    ), // semi-transparent overlay
                    child: const Center(child: CustomLoadingIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTab(
    BuildContext context,
    BuildContext? l10n,
    ScreenType screenType,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            hint: l10n?.tr('emailAddress') ?? "Email Address",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              LowerCaseTextFormatter(),
            ],
            focusNode: _emailFocusNode,
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),
          CustomTextField(
            hint: l10n?.tr('password') ?? "Password",
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.push(AppRoutes.forgotPassword);
              },
              child: Text(
                l10n?.tr('forgotPassword') ?? "Forgot Password?",
                style: TextStyle(
                  fontFamily: AppConstants.fontFamily,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: UIUtils.body(screenType),
                ),
              ),
            ),
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return PrimaryButton(
                text: l10n?.tr('login') ?? "Login",
                backgroundColor: _isLoginEnabled
                    ? AppColors.primaryColor
                    : Colors.grey,
                onPressed: (!_isLoginEnabled || state is AuthLoading)
                    ? null
                    : () {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        final emailError = ValidatorUtils.validateEmail(
                          context,
                          email,
                        );
                        final passwordError = ValidatorUtils.validatePassword(
                          context,
                          password,
                        );

                        if (emailError != null) {
                          showCustomSnackbar(
                            context: context,
                            message: emailError,
                            isError: true,
                          );
                          return;
                        }

                        if (passwordError != null) {
                          showCustomSnackbar(
                            context: context,
                            message: passwordError,
                            isError: true,
                          );
                          return;
                        }

                        context.read<AuthBloc>().add(
                          AuthLoginRequested(email, password),
                        );
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTab(
    BuildContext context,
    BuildContext? l10n,
    ScreenType screenType,
  ) {
    return BlocListener<VerifyUserBloc, VerifyUserState>(
      listener: (context, state) {
        if (state is VerifyUserLoading && state.type == 'mobile') {
          setState(() {
            _isPhoneVerifying = true;
            _isPhoneVerified = false;
            _phoneVerificationError = null;
          });
          _updatePhoneLoginState();
        } else if (state is VerifyUserAlreadyExists && state.type == 'mobile') {
          // In the context of logging in, "already exists" is SUCCESS!
          setState(() {
            _isPhoneVerified = true;
            _isPhoneVerifying = false;
            _phoneVerificationError = null;
          });
          _updatePhoneLoginState();
        } else if (state is VerifyUserValid && state.type == 'mobile') {
          // If available/valid, it means the user does NOT exist! This is an error for login.
          setState(() {
            _isPhoneVerified = false;
            _isPhoneVerifying = false;
            _phoneVerificationError = "User does not exist";
          });
          _updatePhoneLoginState();
        } else if (state is VerifyUserError && state.type == 'mobile') {
          setState(() {
            _isPhoneVerified = false;
            _isPhoneVerifying = false;
            _phoneVerificationError = state.message;
          });
          _updatePhoneLoginState();
        }
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomPhoneField(
              hint: l10n?.tr('phoneNumber') ?? "Phone Number",
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              suffixIcon: _buildPhoneSuffixIcon(),
              disableLengthCheck: true,
              onChanged: (PhoneNumber phone) {
                setState(() {
                  _completePhoneNumber = phone.completeNumber;
                  _phoneNum = phone.number;
                });

                // Clear previous errors when user edits
                if (_phoneVerificationError != null || _isPhoneVerified) {
                  setState(() {
                    _phoneVerificationError = null;
                    _isPhoneVerified = false;
                  });
                }

                // Verify phone if it meets basic criteria (5-16 digits)
                if (_phoneNum.isNotEmpty &&
                    _phoneNum.length >= 5 &&
                    _phoneNum.length <= 16 &&
                    RegExp(r'^\d+$').hasMatch(_phoneNum)) {
                  setState(() {
                    _isPhoneVerifying = true;
                  });
                  _phoneDebouncer.run(() {
                    context.read<VerifyUserBloc>().add(
                      VerifyUserPhone('mobile', _phoneNum, isVerifyUser: true),
                    );
                  });
                } else {
                  setState(() {
                    _isPhoneVerifying = false;
                    _isPhoneVerified = false;
                  });
                }
                _updatePhoneLoginState();
              },
            ),

            SizedBox(height: UIUtils.gapXL(screenType)),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: _phoneVerificationError ?? l10n?.tr('sendOTP') ?? "Send OTP",
                  backgroundColor: _isPhoneLoginEnabled
                      ? AppColors.primaryColor
                      : Colors.grey,
                  onPressed: (!_isPhoneLoginEnabled || state is AuthLoading)
                      ? null
                      : () {
                          if (_completePhoneNumber.isEmpty) {
                            showCustomSnackbar(
                              context: context,
                              message: context.tr('invalidPhone'),
                              isError: true,
                            );
                            return;
                          }

                          context.read<AuthBloc>().add(
                            AuthPhoneSendOTPRequested(_completePhoneNumber),
                          );
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
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
