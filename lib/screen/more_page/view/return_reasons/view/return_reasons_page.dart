import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/multi_selection_field.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_selection_sheet.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

import '../bloc/return_reasons_bloc.dart';
import '../bloc/return_reasons_event.dart';
import '../bloc/return_reasons_state.dart';
import '../model/return_reason_model.dart';

class ReturnReasonsPage extends StatefulWidget {
  const ReturnReasonsPage({super.key});

  @override
  State<ReturnReasonsPage> createState() => _ReturnReasonsPageState();
}

class _ReturnReasonsPageState extends State<ReturnReasonsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ReturnReasonsBloc>().add(LoadReturnReasonsInitial());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ReturnReasonsBloc>().add(LoadMoreReturnReasons());
    }
  }

  Future<void> _onRefresh() async {
    context.read<ReturnReasonsBloc>().add(LoadReturnReasonsInitial());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id) {
    final l10n = context;
    showAppAlertDialog(
      context: context,
      title: l10n?.tr('deleteReturnReason') ?? 'Delete Return Reason',
      message:
          l10n?.tr('deleteReturnReasonConfirm') ??
          'Are you sure you want to delete this return reason?',
      isDestructive: true,
      confirmText: l10n?.tr('delete') ?? 'Delete',
      onConfirm: () {
        if (!DemoGuard.shouldProceed(context)) return;
        context.read<ReturnReasonsBloc>().add(DeleteReturnReasonEvent(id));
      },
    );
  }

  void _showEditBottomSheet(BuildContext context, ReturnReason item) {
    AddReturnReasonBottomSheet.show(
      context,
      initialReason: item,
      onSave: (reason) {
        context.read<ReturnReasonsBloc>().add(UpdateReturnReasonEvent(reason));
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ignore: unused_local_variable
    final containerColor = isDark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surface;
    // ignore: unused_local_variable
    final borderColor = isDark
        ? theme.colorScheme.surfaceContainer
        : AppColors.customBoxBorder;
    // ignore: unused_local_variable
    final titleColor = isDark
        ? AppColors.darkFontColor
        : AppColors.lightFontColor;

    return BlocListener<ReturnReasonsBloc, ReturnReasonsState>(
      listener: (context, state) {
        if (state.operationSuccess != null && state.operationMessage != null) {
          showCustomSnackbar(
            context: context,
            message: state.operationMessage!,
            isError: !state.operationSuccess!,
          );
        }
      },
      child: CustomScaffold(
        showAppbar: true,
        title: l10n?.tr('returnReasons') ?? 'Return Reasons',
        centerTitle: true,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            if (!PermissionChecker.hasPermission(AppPermissions.returnDecide)) {
              showCustomSnackbar(
                context: context,
                message:
                    l10n?.tr('noPermissionError') ??
                    'You do not have permission to perform this action',
                isWarning: true,
              );
              return;
            }
            AddReturnReasonBottomSheet.show(
              context,
              onSave: (reason) {
                context.read<ReturnReasonsBloc>().add(
                  AddReturnReasonEvent(reason),
                );
              },
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<ReturnReasonsBloc, ReturnReasonsState>(
          builder: (context, state) {
            if (state.fetchStatus == ApiStatus.loading && state.items.isEmpty) {
              return const Center(child: CustomLoadingIndicator());
            }

            if (state.fetchStatus == ApiStatus.failure && state.items.isEmpty) {
              return Center(
                child: Text(
                  state.errorMessage ??
                      l10n?.tr('failedToLoadReturnReasons') ??
                      'Failed to load return reasons',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }

            if (state.items.isEmpty) {
              return Center(
                child: EmptyStateWidget(
                  svgPath: ImagesPath.noProductFoundSvg,
                  title:
                      l10n?.tr('noReturnReasonsFound') ?? 'No Return Reasons Found',
                  subtitle:
                      l10n?.tr('addFirstReturnReasonInstructions') ??
                      'Tap the "+" button below to add your first return reason.',
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: _onRefresh,
              child: ListView.separated(
                controller: _scrollController,
                padding: UIUtils.pagePadding(screenType),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount:
                    state.items.length +
                    (state.fetchStatus == ApiStatus.loadingMore ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CustomLoadingIndicator()),
                    );
                  }

                  final item = state.items[index];
                  return CustomCard(
                    type: CardType.returnReason,
                    screenType: screenType,
                    data: {
                      'id': item.id,
                      'titleReason': item.titleReason,
                      'status': item.status,
                      'riderOtpRequired': item.riderOtpRequired,
                      'riderCustomerImageProof': item.riderCustomerImageProof,
                      'selectedProductsLength': item.selectedProducts.length,
                    },
                    onEdit: item.id != null
                        ? () {
                            if (!PermissionChecker.hasPermission(
                              AppPermissions.returnDecide,
                            )) {
                              showCustomSnackbar(
                                context: context,
                                message: l10n?.tr('noPermissionError') ??
                                    'You do not have permission to perform this action',
                                isWarning: true,
                              );
                              return;
                            }
                            _showEditBottomSheet(context, item);
                          }
                        : null,
                    onDelete: item.id != null
                        ? () {
                            if (!PermissionChecker.hasPermission(
                              AppPermissions.returnDecide,
                            )) {
                              showCustomSnackbar(
                                context: context,
                                message: l10n?.tr('noPermissionError') ??
                                    'You do not have permission to perform this action',
                                isWarning: true,
                              );
                              return;
                            }
                            _showDeleteConfirmationDialog(
                              context,
                              item.id!,
                            );
                          }
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddReturnReasonBottomSheet extends StatefulWidget {
  final ReturnReason? initialReason;
  final Function(ReturnReason) onSave;

  const AddReturnReasonBottomSheet({
    super.key,
    this.initialReason,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    ReturnReason? initialReason,
    required Function(ReturnReason) onSave,
  }) {
    final bloc = BlocProvider.of<ReturnReasonsBloc>(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: AddReturnReasonBottomSheet(
            initialReason: initialReason,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  @override
  State<AddReturnReasonBottomSheet> createState() =>
      _AddReturnReasonBottomSheetState();
}

class _AddReturnReasonBottomSheetState
    extends State<AddReturnReasonBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleReasonController = TextEditingController();
  bool _riderOtpRequired = false;
  bool _riderCustomerImageProof = false;
  bool _isActive = true;
  final List<Product> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialReason != null) {
      _titleReasonController.text = widget.initialReason!.titleReason;
      _riderOtpRequired = widget.initialReason!.riderOtpRequired;
      _riderCustomerImageProof = widget.initialReason!.riderCustomerImageProof;
      _isActive = widget.initialReason!.status.toLowerCase() == 'active';
      _selectedProducts.addAll(widget.initialReason!.selectedProducts);
    }
  }

  @override
  void dispose() {
    _titleReasonController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!DemoGuard.shouldProceed(context)) {
      Navigator.pop(context);
      return;
    }
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        ReturnReason(
          id: widget.initialReason?.id,
          titleReason: _titleReasonController.text,
          riderOtpRequired: _riderOtpRequired,
          riderCustomerImageProof: _riderCustomerImageProof,
          status: _isActive ? 'active' : 'inactive',
          selectedProducts: List.from(_selectedProducts),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final l10n = context;

    return BlocConsumer<ReturnReasonsBloc, ReturnReasonsState>(
      listenWhen: (previous, current) {
        return (previous.addStatus != current.addStatus &&
                current.addStatus == ApiStatus.success) ||
            (previous.updateStatus != current.updateStatus &&
                current.updateStatus == ApiStatus.success);
      },
      listener: (context, state) {
        Navigator.pop(context);
      },
      builder: (context, state) {
        final isLoading =
            state.addStatus == ApiStatus.loading ||
            state.updateStatus == ApiStatus.loading;

        return Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UIUtils.radiusLG(screenType)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: UIUtils.pagePadding(screenType),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: UIUtils.gapMD(screenType)),
                      Text(
                        widget.initialReason != null
                            ? (l10n?.tr('editReturnReason') ?? 'Edit Return Reason')
                            : (l10n?.tr('addReturnReason') ?? 'Add Return Reason'),
                        style: TextStyle(
                          fontSize: UIUtils.pageTitle(screenType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: UIUtils.gapLG(screenType)),

                      // Title Reason Textfield
                      CustomTextField(
                        controller: _titleReasonController,
                        label: l10n?.tr('titleReason') ?? 'Title Reason',
                        hint: l10n?.tr('enterReturnReason') ?? 'Enter return reason',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.tr('pleaseEnterReturnReasonTitle') ??
                                'Please enter a return reason title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: UIUtils.gapMD(screenType)),

                      // Toggle Buttons / Switches
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.tr('riderOtpRequiredLabel') ??
                                      "Rider OTP Required",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Switch(
                                  value: _riderOtpRequired,
                                  onChanged: (val) =>
                                      setState(() => _riderOtpRequired = val),
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
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n?.tr('riderCustomerImageProofLabel') ??
                                      "Rider & Customer Image Proof",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Switch(
                                  value: _riderCustomerImageProof,
                                  onChanged: (val) => setState(
                                    () => _riderCustomerImageProof = val,
                                  ),
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
                          ),
                        ],
                      ),
                      SizedBox(height: UIUtils.gapMD(screenType)),

                      // Active Switch
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.tr('statusActiveLabel') ?? "Status (Active)",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Switch(
                                value: _isActive,
                                onChanged: (val) =>
                                    setState(() => _isActive = val),
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
                      SizedBox(height: UIUtils.gapMD(screenType)),

                      // Multi Selection Dropdown / Field for Products
                      MultiSelectionField<Product>(
                        isRequired: true,
                        label: l10n?.tr('products') ?? "Products",
                        hint: l10n?.tr('searchProductsHint') ?? "Search Products..",
                        selectedItems: _selectedProducts,
                        itemLabel: (p) => p.title,
                        validator: (value) {
                          if (_selectedProducts.isEmpty) {
                            return l10n?.tr('pleaseSelectAtLeastOneProduct') ??
                                'Please select at least one product';
                          }
                          return null;
                        },
                        onTap: () {
                          ProductSelectionSheet.show(
                            context,
                            onSelected: (product) {
                              setState(() {
                                if (!_selectedProducts.any(
                                  (p) => p.id == product.id,
                                )) {
                                  _selectedProducts.add(product);
                                }
                              });
                            },
                          );
                        },
                        onDeleted: (p) {
                          setState(() {
                            _selectedProducts.removeWhere(
                              (prod) => prod.id == p.id,
                            );
                          });
                        },
                      ),
                      if (_selectedProducts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedProducts.map((product) {
                            return InputChip(
                              label: Text(
                                product.title,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedProducts.removeWhere(
                                    (p) => p.id == product.id,
                                  );
                                });
                              },
                              deleteIconColor: Colors.redAccent,
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: UIUtils.gapXL(screenType)),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: l10n?.tr('save') ?? 'Save',
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleSave,
                        ),
                      ),
                      SizedBox(height: UIUtils.gapMD(screenType)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
