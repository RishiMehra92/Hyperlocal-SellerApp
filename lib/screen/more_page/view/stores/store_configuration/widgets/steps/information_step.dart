import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class InformationStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const InformationStep({super.key, required this.formKey});

  @override
  State<InformationStep> createState() => _InformationStepState();
}

class _InformationStepState extends State<InformationStep> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _aboutUsController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _aboutUsController.dispose();
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
            label: context.tr('productDescription'),
            isRequired: true,
            hint: context.tr('enterVisitingEgHi'),
            controller: _descriptionController,
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: context.tr('aboutus'),
            hint: context.tr('selectBrand'),
            controller: _aboutUsController,
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
