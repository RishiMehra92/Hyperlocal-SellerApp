import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/colors.dart';
import '../../../../../utils/ui_utils.dart';
import '../../../../../widgets/custom/custom_dropdown.dart';
import '../../../../../widgets/custom/custom_textfield.dart';
import '../view/add_items_in_group_page.dart';

class AddOnsItemCard extends StatefulWidget {
  final int index;
  final AddonItemController controller;
  final ScreenType screenType;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const AddOnsItemCard({
    super.key,
    required this.index,
    required this.controller,
    required this.screenType,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<AddOnsItemCard> createState() => _AddOnsItemCardState();
}

class _AddOnsItemCardState extends State<AddOnsItemCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = context;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${l10n?.tr('itemNo') ?? "Item #"} ${widget.index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CustomTextField(
                  label: l10n?.tr('itemTitle') ?? "Item Title",
                  hint: context.tr('eGExtraCheese'),
                  controller: widget.controller.titleController,
                  onChanged: (val) => widget.onChanged(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        isRequired: true,
                        label: l10n?.tr('price') ?? "Price",
                        hint: "e.g \$19",
                        controller: widget.controller.priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => widget.onChanged(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: l10n?.tr('cost') ?? "Cost",
                        hint: "e.g \$10",
                        controller: widget.controller.costController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => widget.onChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomDropdown<String?>(
                  label: l10n?.tr('indicator') ?? "Indicator",
                  value: widget.controller.indicator,
                  items: [
                    CustomDropdownItem(
                      label: l10n?.tr('none') ?? "None",
                      value: null,
                    ),
                    CustomDropdownItem(label: l10n?.tr('veg') ?? "Veg", value: "veg"),
                    CustomDropdownItem(
                      label: l10n?.tr('nonVeg') ?? "Non-Veg",
                      value: "non_veg",
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => widget.controller.indicator = val);
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 16),
                CustomDropdown<String>(
                  label: l10n?.tr('status') ?? "Status",
                  value: widget.controller.status,
                  items: [
                    CustomDropdownItem(
                      label: l10n?.tr('active') ?? "Active",
                      value: "active",
                    ),
                    CustomDropdownItem(
                      label: l10n?.tr('inactive') ?? "Inactive",
                      value: "inactive",
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => widget.controller.status = val);
                      widget.onChanged();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.tr('availability') ?? "Available",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: widget.controller.isAvailable,
                      onChanged: (val) {
                        setState(() => widget.controller.isAvailable = val);
                        widget.onChanged();
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primaryColor,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      trackOutlineWidth: WidgetStateProperty.all(0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
