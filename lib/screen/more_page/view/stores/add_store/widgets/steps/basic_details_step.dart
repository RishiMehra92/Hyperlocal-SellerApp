import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/utils/formatters.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_phone_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class BasicDetailsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const BasicDetailsStep({super.key, required this.formKey});

  @override
  State<BasicDetailsStep> createState() => _BasicDetailsStepState();
}

class _BasicDetailsStepState extends State<BasicDetailsStep> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupInstructionsController =
      TextEditingController();
  final FocusNode storeNameNode = FocusNode();
  final FocusNode emailNode = FocusNode();
  final FocusNode phoneNode = FocusNode();
  final FocusNode pickupInstructionsNode = FocusNode();

  bool _allowCustomerPickup = false;
  bool _isSyncing = false;

  @override
  void dispose() {
    storeNameNode.dispose();
    emailNode.dispose();
    phoneNode.dispose();
    pickupInstructionsNode.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pickupInstructionsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final formData = context.read<AddStoreBloc>().state.formData;
    _syncWithFormData(formData);

    _storeNameController.addListener(_updateBloc);
    _emailController.addListener(_updateBloc);
    _phoneController.addListener(_updateBloc);
    _pickupInstructionsController.addListener(_updateBloc);
  }

  void _syncWithFormData(Map<String, dynamic> data) {
    _isSyncing = true;
    if (data['name'] != _storeNameController.text) {
      _storeNameController.text = data['name'] ?? '';
    }
    if (data['contact_email'] != _emailController.text) {
      _emailController.text = data['contact_email'] ?? '';
    }
    if (data['contact_number'] != _phoneController.text) {
      _phoneController.text = data['contact_number'] ?? '';
    }
    final allowPickup = data['allows_pickup'] ?? false;
    if (allowPickup != _allowCustomerPickup) {
      _allowCustomerPickup = allowPickup;
    }
    final instructions = data['pickup_instructions'] ?? '';
    if (instructions != _pickupInstructionsController.text) {
      _pickupInstructionsController.text = instructions;
    }
    _isSyncing = false;
  }

  void _updateBloc() {
    if (_isSyncing) return;
    context.read<AddStoreBloc>().add(
      UpdateStoreField({
        'name': _storeNameController.text,
        'contact_email': _emailController.text,
        'contact_number': _phoneController.text,
        'mobile': _phoneController.text,
        'allows_pickup': _allowCustomerPickup,
        'pickup_instructions': _pickupInstructionsController.text,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    return BlocListener<AddStoreBloc, AddStoreState>(
      listenWhen: (previous, current) => previous.formData != current.formData,
      listener: (context, state) {
        _syncWithFormData(state.formData);
      },
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: l10n?.tr('storeName') ?? "Store Name",
              isRequired: true,
              hint: l10n?.tr('enterNickName') ?? "Enter Nickname",
              controller: _storeNameController,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: storeNameNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.tr('contactEmail') ?? "Contact Email",
              isRequired: true,
              hint: l10n?.tr('enterEmail') ?? "Enter Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                LowerCaseTextFormatter(),
              ],
              validator: (value) =>
                  ValidatorUtils.validateEmail(context, value),
              focusNode: emailNode,
            ),
            const SizedBox(height: 20),
            CustomPhoneField(
              label: l10n?.tr('mobileNumber') ?? "Mobile Number",
              isRequired: true,
              controller: _phoneController,
              focusNode: phoneNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            // const SizedBox(height: 20),
            // BlocBuilder<AddStoreBloc, AddStoreState>(
            //   buildWhen: (previous, current) => previous.isPickupEnabled != current.isPickupEnabled,
            //   builder: (context, state) {
            //     if (!state.isPickupEnabled) return const SizedBox.shrink();
            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Switch(
            //               value: _allowCustomerPickup,
            //               onChanged: (value) {
            //                 setState(() {
            //                   _allowCustomerPickup = value;
            //                 });
            //                 _updateBloc();
            //               },
            //               activeThumbColor: Colors.white,
            //               activeTrackColor: AppColors.primaryColor,
            //               inactiveThumbColor: Colors.white,
            //               inactiveTrackColor: Colors.grey.shade300,
            //               trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            //               trackOutlineWidth: WidgetStateProperty.all(0),
            //             ),
            //             const SizedBox(width: 8),
            //             Text(
            //               l10n?.tr('allowCustomerPickup') ?? "Allow Customer Pickup",
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w500,
            //                 color: Theme.of(context).colorScheme.tertiary,
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 20),
            //         CustomTextField(
            //           label: l10n?.tr('pickupInstructions') ?? "Pickup Instructions",
            //           hint: l10n?.tr('enterPickupInstructions') ?? "Enter pickup instructions",
            //           controller: _pickupInstructionsController,
            //           maxLines: 3,
            //           focusNode: pickupInstructionsNode,
            //         ),
            //         const SizedBox(height: 20),
            //       ],
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
