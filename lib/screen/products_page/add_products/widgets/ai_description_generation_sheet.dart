import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';

class AiDescriptionGenerationSheet extends StatefulWidget {
  final String productTitle;
  final String? categoryId;
  final Function(String shortDesc, String desc) onApply;

  const AiDescriptionGenerationSheet({super.key, required this.productTitle, this.categoryId, required this.onApply});

  @override
  State<AiDescriptionGenerationSheet> createState() => _AiDescriptionGenerationSheetState();
}

class _AiDescriptionGenerationSheetState extends State<AiDescriptionGenerationSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTone;
  final TextEditingController _highlightsController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = true;
  String? _fetchedShortDesc;
  String? _fetchedDesc;

  @override
  void dispose() {
    _highlightsController.dispose();
    super.dispose();
  }

  void _generateAiDescription() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String toneValue = "";
    if (_selectedTone == "professional") {
      toneValue = "Professional";
    } else if (_selectedTone == "punchy") {
      toneValue = "Punchy";
    } else if (_selectedTone == "detailed") {
      toneValue = "Detailed";
    } else if (_selectedTone == "seo") {
      toneValue = "SEO";
    } else {
      toneValue = _selectedTone ?? "";
    }

    context.read<AddProductBloc>().add(
      GenerateAiDescription(
        title: widget.productTitle,
        categoryId: widget.categoryId ?? "",
        tone: toneValue,
        keywords: _highlightsController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AddProductBloc, AddProductState>(
      listener: (context, state) {
        if (state is AiDescriptionGenerationLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is AiDescriptionGenerationSuccess) {
          setState(() {
            _isLoading = false;
            _fetchedShortDesc = state.shortDescription;
            _fetchedDesc = state.description;
            _isEdit = false;
          });
        } else if (state is AiDescriptionGenerationFailure) {
          setState(() {
            _isLoading = false;
          });
          showCustomSnackbar(context: context, message: state.error, isError: true, showAtTop: true);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('generateWithAiTitle'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);

                          setState(() {
                            _selectedTone = null;
                            _highlightsController.clear();
                            _fetchedShortDesc = null;
                            _fetchedDesc = null;
                            _isEdit = true;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FormField<String>(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('toneOfDescriptionIsRequired');
                      }
                      return null;
                    },
                    builder: (FormFieldState<String> state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomDropdown<String>(
                            label: context.tr('toneOfDescription'),
                            isRequired: true,
                            hint: context.tr('selectTone'),
                            value: state.value,
                            items: [
                              CustomDropdownItem(
                                label: context.tr('toneProfessional'),
                                value: "professional",
                              ),
                              CustomDropdownItem(label: context.tr('tonePunchy'), value: "punchy"),
                              CustomDropdownItem(label: context.tr('toneDetailed'), value: "detailed"),
                              CustomDropdownItem(label: context.tr('toneSeo'), value: "seo"),
                            ],
                            onChanged: (val) {
                              state.didChange(val);
                              setState(() {
                                _selectedTone = val;
                                _isEdit = true;
                              });
                            },
                          ),
                          if (state.hasError) ...[
                            const SizedBox(height: 5),
                            Text(state.errorText ?? "", style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  CustomTextField(
                    label: context.tr('keyFeatureHighlights'),
                    isRequired: false,
                    hint: context.tr('enterKeyFeaturesOrHighlights'),
                    maxLines: 3,
                    controller: _highlightsController,
                    onChanged: (v) {
                      setState(() {
                        _isEdit = true;
                      });
                    },
                  ),

                  if (_fetchedShortDesc != null || _fetchedDesc != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? const Color(0xFF161B22) : Colors.grey.shade50,
                        border: Border.all(
                          color: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('aiGeneratedContent'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          if (_fetchedShortDesc != null && _fetchedShortDesc!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              context.tr('shortDescription'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_fetchedShortDesc!, style: const TextStyle(fontSize: 14)),
                          ],
                          if (_fetchedDesc != null && _fetchedDesc!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              context.tr('productDescription'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_fetchedDesc!, style: const TextStyle(fontSize: 14)),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Center(child: CustomLoadingIndicator())
                  else if (_isEdit)
                    PrimaryButton(
                      text: context.tr('generate'),
                      borderRadius: 100,
                      onPressed: _generateAiDescription,
                    )
                  else
                    PrimaryButton(
                      text: context.tr('applyToForm'),
                      borderRadius: 100,
                      onPressed: () {
                        widget.onApply(_fetchedShortDesc ?? "", _fetchedDesc ?? "");
                        Navigator.pop(context);
                      },
                    ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
