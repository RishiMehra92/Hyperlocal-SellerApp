import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';
import '../cubit/return_details_cubit.dart';

class ReturnActionSheet extends StatefulWidget {
  final String action, title;
  final bool storeConfirmation;
  const ReturnActionSheet({
    super.key,
    required this.action,
    required this.title,
    required this.storeConfirmation,
  });
  @override
  State<ReturnActionSheet> createState() => _ReturnActionSheetState();
}

class _ReturnActionSheetState extends State<ReturnActionSheet> {
  final _comment = TextEditingController();
  final List<String> _photos = [];
  String? _reason, _validationError;
  bool _submitting = false, _picking = false;
  bool get _isEscalation =>
      widget.storeConfirmation && widget.action == 'escalate';
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final path = await ImagePickerUtils.pickMedia(context);
      if (path != null && mounted) setState(() => _photos.add(path));
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message: e.toString(),
          isError: true,
          showAtTop: true,
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (!PermissionChecker.hasPermission(AppPermissions.returnDecide)) return;
    if (!DemoGuard.shouldProceed(context)) return;
    if (_isEscalation) {
      final l10n = context;
      final error = _reason == null
          ? l10n.tr('returnsReasonRequired')
          : _comment.text.trim().isEmpty
          ? l10n.tr('returnsRemarksRequired')
          : _photos.isEmpty
          ? l10n.tr('returnsPhotoRequired')
          : null;
      if (error != null) {
        setState(() => _validationError = error);
        return;
      }
    }
    setState(() {
      _submitting = true;
      _validationError = null;
    });
    final success = await context.read<ReturnDetailsCubit>().submit(
      action: widget.action,
      storeConfirmation: widget.storeConfirmation,
      comment: _comment.text,
      disputeReason: _reason,
      photos: List.of(_photos),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    return BlocBuilder<ReturnDetailsCubit, ReturnDetailsState>(
      builder: (context, state) => PopScope(
        canPop: !_submitting && !_picking,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  if (_isEscalation) ...[
                    CustomDropdown<String>(
                      label: l10n.tr('returnsDisputeReason'),
                      hint: l10n.tr('selectOption'),
                      isRequired: true,
                      value: _reason,
                      items: state.enums.disputeReasons
                          .map((e) => CustomDropdownItem(value: e, label: e))
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() {
                              _reason = value;
                              _validationError = null;
                            }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    label: l10n.tr('returnsRemarks'),
                    isRequired: _isEscalation,
                    controller: _comment,
                    maxLines: 3,
                    enabled: !_submitting,
                  ),
                  if (widget.storeConfirmation) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          l10n.tr('returnsPhotos'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_isEscalation)
                          Text(
                            ' *',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final path in _photos)
                          SizedBox(
                            width: 120,
                            child: CustomUploadArea(
                              hint: l10n.tr('returnsPhotos'),
                              fileName: path,
                              height: 100,
                              onRemove: _submitting
                                  ? null
                                  : () => setState(() => _photos.remove(path)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomUploadArea(
                      hint: l10n.tr('returnsAddPhoto'),
                      height: 90,
                      onTap: _submitting || _picking ? null : _pick,
                    ),
                  ],
                  if (_validationError != null || state.operationError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _validationError ?? state.operationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: l10n.tr('submit'),
                    isLoading: _submitting,
                    onPressed: _submitting || _picking ? null : _submit,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _submitting || _picking
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(l10n.tr('cancel')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
