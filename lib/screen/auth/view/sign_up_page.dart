import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/auth/widgets/sign_up_step_header.dart';
import 'package:hyper_local_seller/screen/auth/widgets/steps/personal_information_step.dart';
import 'package:hyper_local_seller/screen/auth/widgets/steps/required_documents_step.dart';
import 'package:hyper_local_seller/screen/auth/widgets/steps/address_step.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  bool _personalInfoStepValid = true;
  final ScrollController _scrollController = ScrollController();

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Controllers for Step 1
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';

  // Paths for Step 2
  String? _businessLicensePath;
  String? _articlesOfIncorporationPath;
  String? _nationalIdCardPath;
  String? _authorizedSignaturePath;

  // Controllers for Step 3
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final _addressFocusNode = FocusNode();
  final _landmarkFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _stateFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _zipCodeFocusNode = FocusNode();
  final _latitudeFocusNode = FocusNode();
  final _longitudeFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _addressFocusNode.dispose();
    _landmarkFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _countryFocusNode.dispose();
    _zipCodeFocusNode.dispose();
    _latitudeFocusNode.dispose();
    _longitudeFocusNode.dispose();

    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    if (step >= 1 && step <= _totalSteps) {
      if (step > _currentStep) {
        // Validating current step before moving forward
        if (_formKeys[_currentStep - 1].currentState?.validate() ?? false) {
          FocusScope.of(context).unfocus();
          setState(() {
            _currentStep = step;
          });
          _scrollToTop();
        }
      } else {
        // Going back is always allowed
        FocusScope.of(context).unfocus();
        setState(() {
          _currentStep = step;
        });
        _scrollToTop();
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onStepTap(int step) {
    if (step == _currentStep) return;

    if (step > _currentStep) {
      if (_formKeys[_currentStep - 1].currentState?.validate() ?? false) {
        if (step > _currentStep + 1) {
          showCustomSnackbar(
            context: context,
            message: context.tr('completePreviousSteps'),
            isError: true,
          );
          return;
        }
        _onStepChanged(step);
      }
    } else {
      _onStepChanged(step);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;

    return CustomScaffold(
      title: l10n.tr('createNewAccount'),
      showAppbar: true,
      centerTitle: true,
      onBackTap: () => context.pop(),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showCustomSnackbar(
              context: context,
              message: state.error,
              isError: true,
            );
          } else if (state is AuthSignUpSuccess) {
            showCustomSnackbar(context: context, message: state.message);
            context.go('/login');
          } else if (state is AuthSignUpOTPSent) {
            showCustomSnackbar(
              context: context,
              // ignore: dead_null_aware_expression
              // ignore: dead_code
              message: l10n.tr('otpSentSuccess'),
            );
            context.push(
              '/otp',
              extra: {
                'verificationId': state.verificationId,
                'phoneNumber': state.phoneNumber,
                'isSignUp': true,
                'signUpData': {
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'phone': _mobileController.text,
                  'countryCode': _selectedCountryCode,
                  'password': _passwordController.text,
                  'address': _addressController.text,
                  'city': _cityController.text,
                  'state': _stateController.text,
                  'landmark': _landmarkController.text,
                  'zipcode': _zipCodeController.text,
                  'country': _countryController.text,
                  'latitude': _latitudeController.text,
                  'longitude': _longitudeController.text,
                  'businessLicensePath': _businessLicensePath ?? '',
                  'articlesOfIncorporationPath': _articlesOfIncorporationPath ?? '',
                  'nationalIdCardPath': _nationalIdCardPath ?? '',
                  'authorizedSignaturePath': _authorizedSignaturePath ?? '',
                },
              },
            );
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                SignUpStepHeader(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  screenType: screenType,
                  onStepTap: _onStepTap,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      UIUtils.gapMD(screenType),
                      0,
                      UIUtils.gapMD(screenType),
                      UIUtils.gapMD(screenType),
                    ),
                    child: _buildStepContent(_currentStep, l10n),
                  ),
                ),
              ],
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(child: CustomLoadingIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(screenType, l10n),
    );
  }

  Widget _buildStepContent(int step, BuildContext? l10n) {
    switch (step) {
      case 1:
        return PersonalInformationStep(
          formKey: _formKeys[0],
          nameController: _nameController,
          mobileController: _mobileController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          nameFocusNode: _nameFocusNode,
          mobileFocusNode: _mobileFocusNode,
          emailFocusNode: _emailFocusNode,
          passwordFocusNode: _passwordFocusNode,
          confirmPasswordFocusNode: _confirmPasswordFocusNode,
          selectedCountryCode: _selectedCountryCode,
          selectedCountryFlag: _selectedCountryFlag,
          onCountryChanged: (code, flag) {
            setState(() {
              _selectedCountryCode = code;
              _selectedCountryFlag = flag;
            });
          },
          onValidationStatusChanged: (isValid) {
            setState(() {
              _personalInfoStepValid = isValid;
            });
          },
        );
      case 2:
        return RequiredDocumentsStep(
          formKey: _formKeys[1],
          onFilePicked: (field, path) {
            setState(() {
              switch (field) {
                case 'Business License':
                  _businessLicensePath = path;
                  break;
                case 'Articles of Incorporation':
                  _articlesOfIncorporationPath = path;
                  break;
                case 'National ID Card':
                  _nationalIdCardPath = path;
                  break;
                case 'Authorized Signature':
                  _authorizedSignaturePath = path;
                  break;
              }
            });
          },
          businessLicensePath: _businessLicensePath,
          articlesOfIncorporationPath: _articlesOfIncorporationPath,
          nationalIdCardPath: _nationalIdCardPath,
          authorizedSignaturePath: _authorizedSignaturePath,
        );
      case 3:
        return BusinessAddressStep(
          formKey: _formKeys[2],
          addressController: _addressController,
          cityController: _cityController,
          stateController: _stateController,
          landmarkController: _landmarkController,
          zipCodeController: _zipCodeController,
          countryController: _countryController,
          latitudeController: _latitudeController,
          longitudeController: _longitudeController,
          addressNode: _addressFocusNode,
          cityNode: _cityFocusNode,
          stateNode: _stateFocusNode,
          landmarkNode: _landmarkFocusNode,
          zipCodeNode: _zipCodeFocusNode,
          countryNode: _countryFocusNode,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButtons(ScreenType screenType, BuildContext? l10n) {
    final bool isFirstStep = _currentStep == 1;
    final bool isLastStep = _currentStep == _totalSteps;

    return Container(
      padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onStepChanged(_currentStep - 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    side: const BorderSide(color: AppColors.primaryColor),
                  ),
                  child: Text(
                    l10n.tr('previous'),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: UIUtils.semiBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: (_currentStep == 1 && !_personalInfoStepValid)
                    ? null
                    : () {
                        if (_currentStep < _totalSteps) {
                          _onStepChanged(_currentStep + 1);
                        } else {
                          if (_formKeys[_currentStep - 1].currentState
                                  ?.validate() ??
                              false) {
                            _submitSignUp();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLastStep ? l10n.tr('register') : l10n.tr('next'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitSignUp() {
    context.read<AuthBloc>().add(
      AuthSignUpPhoneSendOTPRequested(
        '$_selectedCountryCode${_mobileController.text}',
      ),
    );
  }
}
