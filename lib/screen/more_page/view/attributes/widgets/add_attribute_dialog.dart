import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';

class AddAttributeDialog extends StatefulWidget {
  final Attribute? attribute;
  final Function(String title, String label, String swatchType)? onSave;
  
  const AddAttributeDialog({super.key, this.attribute, this.onSave});

  @override
  State<AddAttributeDialog> createState() => _AddAttributeDialogState();
}

class _AddAttributeDialogState extends State<AddAttributeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _labelController;
  String _selectedSwatchType = 'text';

  final List<String> _swatchTypes = ['text', 'color', 'image'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.attribute?.title ?? '',
    );
    _labelController = TextEditingController(
      text: widget.attribute?.label ?? '',
    );
    _selectedSwatchType = widget.attribute?.swatcheType.toLowerCase() ?? 'text';
    if (!_swatchTypes.contains(_selectedSwatchType)) {
      _selectedSwatchType = 'text';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.read<ScreenSizeBloc>().state.screenType;
    final l10n = context;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.attribute == null
                      ? l10n?.tr('addAttribute') ?? "Create New Attribute"
                      : l10n?.tr('editAttribute') ?? "Edit Attribute",
                  style: TextStyle(
                    fontSize: UIUtils.body(screenType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            SizedBox(height: UIUtils.gapMD(screenType)),
            CustomTextField(
              label: l10n?.tr('title') ?? "Title",
              controller: _titleController,
              hint: l10n?.tr('attributeName') ?? "Attribute Name",
              isRequired: true,
              validator: (v) => v!.isEmpty ? "Title is required" : null,
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            CustomTextField(
              label: l10n?.tr('label') ?? "Label",
              controller: _labelController,
              hint: l10n?.tr('label') ?? "Label",
              isRequired: true,
              validator: (v) => v!.isEmpty ? "Label is required" : null,
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            CustomDropdown<String>(
              label: l10n?.tr('swatchType') ?? "Swatch Type",
              value: _selectedSwatchType,
              items: _swatchTypes.map((type) {
                return CustomDropdownItem(
                  label: type[0].toUpperCase() + type.substring(1),
                  value: type,
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedSwatchType = v!),
              isRequired: true,
            ),
            SizedBox(height: UIUtils.gapLG(screenType)),
            PrimaryButton(
              text: widget.attribute == null
                  ? l10n?.tr('add') ?? "Create"
                  : l10n?.tr('update') ?? "Update",
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!DemoGuard.shouldProceed(context)) {
        Navigator.pop(context);
        return;
      }

      widget.onSave?.call(
        _titleController.text,
        _labelController.text,
        _selectedSwatchType,
      );
      Navigator.pop(context);
    }
  }
}
