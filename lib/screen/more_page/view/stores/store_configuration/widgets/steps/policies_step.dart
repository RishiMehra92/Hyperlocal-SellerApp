import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class PoliciesStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const PoliciesStep({super.key, required this.formKey});

  @override
  State<PoliciesStep> createState() => _PoliciesStepState();
}

class _PoliciesStepState extends State<PoliciesStep> {
  final TextEditingController _promotionalTextController =
      TextEditingController();
  final TextEditingController _returnReplacementController =
      TextEditingController();
  final TextEditingController _refundPolicyController = TextEditingController();
  final TextEditingController _deliveryPolicyController =
      TextEditingController();

  @override
  void dispose() {
    _promotionalTextController.dispose();
    _returnReplacementController.dispose();
    _refundPolicyController.dispose();
    _deliveryPolicyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: context.tr('promotionaltext'),
            hint: context.tr('enterWritingEgHi'),
            controller: _promotionalTextController,
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: context.tr('returnreplacementpolicy'),
            hint: context.tr('selectBrand'),
            controller: _returnReplacementController,
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: context.tr('refundpolicy'),
            hint: context.tr('selectBrand'),
            controller: _refundPolicyController,
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: context.tr('deliverypolicy'),
            hint: context.tr('selectBrand'),
            controller: _deliveryPolicyController,
            maxLines: 4,
            minLines: 2,
          ),
        ],
      ),
    );
  }
}
