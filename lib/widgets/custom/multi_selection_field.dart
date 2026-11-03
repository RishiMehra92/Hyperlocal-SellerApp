import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class MultiSelectionField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final List<T> selectedItems;
  final String Function(T) itemLabel;
  final VoidCallback onTap;
  final Function(T) onDeleted;
  final bool isRequired;
  final String? Function(String?)? validator;

  const MultiSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedItems,
    required this.itemLabel,
    required this.onTap,
    required this.onDeleted,
    this.isRequired = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hint: hint,
      isRequired: isRequired,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      controller: TextEditingController(
        text: selectedItems.isEmpty
            ? ""
            : "${selectedItems.length} items selected",
      ),
    );
  }
}
