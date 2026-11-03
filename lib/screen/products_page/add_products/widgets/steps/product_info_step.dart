import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/brand_selection_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/custom_section_widget.dart';

class ProductInfoStep extends StatefulWidget {
  const ProductInfoStep({super.key});

  @override
  State<ProductInfoStep> createState() => _ProductInfoStepState();
}

class _ProductInfoStepState extends State<ProductInfoStep> {
  final TextEditingController _brandController = TextEditingController();
  final List<Map<String, dynamic>> _customFields = [];
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _madeInController = TextEditingController();
  final FocusNode _hsnFocus = FocusNode();

  String? _selectedIndicator;
  int? _selectedBrandId;
  int _basePrepTime = 20;

  @override
  void initState() {
    super.initState();
    // Load brands
    context.read<BrandsBloc>().add(LoadBrandsInitial());

    // Initialize from existing state
    final productData = context.read<AddProductBloc>().state.productData;
    _hsnController.text = productData.hsnCode ?? "";
    _madeInController.text = productData.madeIn ?? "";
    _selectedIndicator = productData.indicator;
    _selectedBrandId = productData.brandId;
    _brandController.text = productData.brandName ?? "";
    _basePrepTime = productData.prepTime;

    if (productData.customFields.isNotEmpty) {
      for (var field in productData.customFields) {
        if (field.containsKey('key') && field.containsKey('value')) {
          _customFields.add({
            'key': TextEditingController(text: field['key']),
            'value': TextEditingController(text: field['value']),
            'keyFocus': FocusNode(),
            'valueFocus': FocusNode(),
          });
        }
      }
    }
  }

  void _showBrandSelection() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrandSelectionSheet(
        selectedBrandId: _selectedBrandId,
        onSelected: (brand) {
          setState(() {
            _selectedBrandId = brand.id;
            _brandController.text = brand.title;
          });
          _updateBloc();
        },
      ),
    );
  }

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
        'keyFocus': FocusNode(),
        'valueFocus': FocusNode(),
      });
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields[index]['keyFocus']?.dispose();
      _customFields[index]['valueFocus']?.dispose();
      _customFields.removeAt(index);
    });
    _updateBloc();
  }

  void _showCustomTimePickerDialog() {
    final controller = TextEditingController(text: _basePrepTime.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('basePrepTime')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: context.tr('minutesShort') ?? "Min",
            hintText: context.tr('enterTimeInMinutes') ?? "Enter time in minutes",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                setState(() {
                  _basePrepTime = val;
                });
                _updateBloc();
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      useSafeArea: true,
      showSearch: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: Theme.of(context).cardColor,
        inputDecoration: InputDecoration(
          hintText: context.tr('search'),

          hintStyle: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w400),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        searchTextStyle: const TextStyle(color: AppColors.primaryColor),
      ),
      showPhoneCode: false,
      searchAutofocus: true,
      onSelect: (Country country) {
        setState(() {
          _madeInController.text = country.name;
        });
        _updateBloc();
      },
    );
  }

  @override
  void dispose() {
    _hsnController.dispose();
    _madeInController.dispose();
    _brandController.dispose();
    _hsnFocus.dispose();
    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
      field['keyFocus']?.dispose();
      field['valueFocus']?.dispose();
    }
    super.dispose();
  }

  void _updateBloc() {
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;

    final List<Map<String, String>> customFieldsData = [];
    for (var field in _customFields) {
      final key = (field['key'] as TextEditingController).text;
      final value = (field['value'] as TextEditingController).text;
      if (key.isNotEmpty || value.isNotEmpty) {
        customFieldsData.add({'key': key, 'value': value});
      }
    }

    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          brandId: _selectedBrandId,
          brandName: _brandController.text,
          madeIn: _madeInController.text,
          hsnCode: _hsnController.text,
          indicator: _selectedIndicator,
          prepTime: _basePrepTime,
          customFields: customFieldsData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final productData = context.watch<AddProductBloc>().state.productData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showBrandSelection,
          child: AbsorbPointer(
            child: CustomTextField(
              label: context.tr('brand'),
              hint: context.tr('selectBrand'),
              controller: _brandController,
              suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _showCountryPicker,
          child: AbsorbPointer(
            child: CustomTextField(
              label: context.tr('madeIn'),
              hint: context.tr('selectCountry'),
              controller: _madeInController,
              // onChanged here won't trigger because of AbsorbPointer,
              // handled in _showCountryPicker
            ),
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: context.tr('hsnCode'),
          isRequired: false,
          hint: context.tr('enterHsnCode'),
          controller: _hsnController,
          onChanged: (v) => _updateBloc(),
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: context.tr('indicator'),
          isRequired: false,
          hint: context.tr('selectIndicator'),
          value: _selectedIndicator,
          items: [
            CustomDropdownItem(label: context.tr('none'), value: ''),
            CustomDropdownItem(label: context.tr('veg'), value: "veg"),
            CustomDropdownItem(label: context.tr('nonVeg'), value: "non_veg"),
          ],
          onChanged: (val) {
            setState(() => _selectedIndicator = val);
            _updateBloc();
          },
        ),
        const SizedBox(height: 20),
        _buildBasePrepTime(context.screenType),
        const SizedBox(height: 30),
        Text(
          context.tr('customFields'),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.tertiary),
        ),
        const SizedBox(height: 8),
        ...List.generate(_customFields.length, (index) => _buildCustomFieldRow(index, screenType)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addCustomField,
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.tr('addField')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('addCustomFieldHelper'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('customProductSections'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: PrimaryButton(
                onPressed: () {
                  final currentSections = List<CustomProductSection>.from(productData.customProductSections);
                  currentSections.add(CustomProductSection(title: ""));
                  final bloc = context.read<AddProductBloc>();
                  bloc.add(UpdateProductData(productData.copyWith(customProductSections: currentSections)));
                },
                icon: Icons.add,
                text: context.tr('addSection'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          context.tr('addCustomSectionsHint'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),

        const SizedBox(height: 16),
        ...productData.customProductSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          return CustomProductSectionWidget(
            index: index,
            section: section,
            onRemove: () {
              final currentSections = List<CustomProductSection>.from(productData.customProductSections);
              currentSections.removeAt(index);
              final bloc = context.read<AddProductBloc>();
              bloc.add(UpdateProductData(productData.copyWith(customProductSections: currentSections)));
            },
            onChanged: (updatedSection) {
              final currentSections = List<CustomProductSection>.from(productData.customProductSections);
              currentSections[index] = updatedSection;
              final bloc = context.read<AddProductBloc>();
              bloc.add(UpdateProductData(productData.copyWith(customProductSections: currentSections)));
            },
          );
        }),
      ],
    );
  }

  Widget _buildBasePrepTime(ScreenType screenType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: context.tr('basePrepTime'),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.tertiary),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),
        Text(
          context.tr('averageTimetoPrepareanorderinminutes'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.primaryColor),
                      onPressed: () {
                        if (_basePrepTime > 0) {
                          setState(() {
                            _basePrepTime -= 5;
                            _updateBloc();
                          });
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: _showCustomTimePickerDialog,
                      child: Text(
                        "$_basePrepTime ${context.tr('minutesShort')}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primaryColor),
                      onPressed: () {
                        setState(() {
                          _basePrepTime += 5;
                          _updateBloc();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomFieldRow(int index, ScreenType screenType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: _customFields[index]['key'],
              focusNode: _customFields[index]['keyFocus'],
              hint: context.tr('fieldName'),
              onChanged: (v) => _updateBloc(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: _customFields[index]['value'],
              focusNode: _customFields[index]['valueFocus'],
              hint: context.tr('value'),
              onChanged: (v) => _updateBloc(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _removeCustomField(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2), // Align with textfield
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
