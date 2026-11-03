import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/custom_field_widget.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class CustomProductSectionWidget extends StatefulWidget {
  final int index;
  final CustomProductSection section;
  final VoidCallback onRemove;
  final Function(CustomProductSection) onChanged;

  const CustomProductSectionWidget({
    super.key,
    required this.index,
    required this.section,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<CustomProductSectionWidget> createState() => _CustomProductSectionWidgetState();
}

class _CustomProductSectionWidgetState extends State<CustomProductSectionWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _descriptionController = TextEditingController(text: widget.section.description);
    _sortOrderController = TextEditingController(text: widget.section.sortOrder.toString());
  }

  @override
  void didUpdateWidget(CustomProductSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section.title != _titleController.text) {
      _titleController.text = widget.section.title ?? "";
    }
    if (widget.section.description != _descriptionController.text) {
      _descriptionController.text = widget.section.description ?? "";
    }
    if (widget.section.sortOrder.toString() != _sortOrderController.text) {
      _sortOrderController.text = widget.section.sortOrder.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('sectionWithIndex', positionalArgs: [widget.index + 1]), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              OutlinedButton(
                onPressed: widget.onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: Text(context.tr('remove')),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            spacing: 12,
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  label: context.tr('title'),
                  hint: context.tr('enterSectionTitle'),
                  controller: _titleController,
                  onChanged: (val) => widget.onChanged(widget.section.copyWith(title: val)),
                ),
              ),

              Expanded(
                child: CustomTextField(
                  label: context.tr('sortOrder'),
                  hint: "0",
                  keyboardType: TextInputType.number,
                  controller: _sortOrderController,
                  onChanged: (val) => widget.onChanged(widget.section.copyWith(sortOrder: int.tryParse(val) ?? 0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          CustomTextField(
            maxLines: 2,
            label: context.tr('productDescription'),
            hint: context.tr('enterSectionDescription'),
            controller: _descriptionController,
            onChanged: (val) => widget.onChanged(widget.section.copyWith(description: val)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('fields'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SecondaryButton(
                onPressed: () {
                  final newFields = List<CustomProductField>.from(widget.section.fields)
                    ..add(CustomProductField(title: ""));
                  widget.onChanged(widget.section.copyWith(fields: newFields));
                },
                icon: Icons.add,
                text: context.tr('addField'),
                // style: TextButton.styleFrom(
                //   foregroundColor: Theme.of(context).primaryColor,
                // ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.section.fields.asMap().entries.map((entry) {
            final fieldIndex = entry.key;
            final field = entry.value;
            return CustomProductFieldWidget(
              sectionIndex: widget.index,
              fieldIndex: fieldIndex,
              field: field,
              onRemove: () {
                final newFields = List<CustomProductField>.from(widget.section.fields)..removeAt(fieldIndex);
                widget.onChanged(widget.section.copyWith(fields: newFields));
              },
              onChanged: (updatedField) {
                final newFields = List<CustomProductField>.from(widget.section.fields);
                newFields[fieldIndex] = updatedField;
                widget.onChanged(widget.section.copyWith(fields: newFields));
              },
            );
          }),
        ],
      ),
    );
  }
}
