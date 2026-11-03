import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import '../model/order_return_model.dart';
import '../model/return_filters.dart';

class ReturnFilterSheet extends StatefulWidget {
  final ReturnFilters filters;
  final ReturnEnums enums;
  const ReturnFilterSheet({
    super.key,
    required this.filters,
    required this.enums,
  });
  @override
  State<ReturnFilterSheet> createState() => _ReturnFilterSheetState();
}

class _ReturnFilterSheetState extends State<ReturnFilterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _min, _max;
  late final TextEditingController _fromText, _toText;
  String? _status, _error;
  DateTime? _from, _to;
  @override
  void initState() {
    super.initState();
    _status = widget.filters.status;
    _from = widget.filters.dateFrom;
    _to = widget.filters.dateTo;
    _min = TextEditingController(
      text: widget.filters.refundMin?.toString() ?? '',
    );
    _max = TextEditingController(
      text: widget.filters.refundMax?.toString() ?? '',
    );
    _fromText = TextEditingController(
      text: TimeUtils.formatScheduledDate(_from?.toIso8601String()),
    );
    _toText = TextEditingController(
      text: TimeUtils.formatScheduledDate(_to?.toIso8601String()),
    );
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _fromText.dispose();
    _toText.dispose();
    super.dispose();
  }

  Future<void> _date(bool from) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (from) {
        _from = selected;
        _fromText.text = TimeUtils.formatScheduledDate(
          selected.toIso8601String(),
        );
      } else {
        _to = selected;
        _toText.text = TimeUtils.formatScheduledDate(
          selected.toIso8601String(),
        );
      }
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final min = double.tryParse(_min.text.trim()),
        max = double.tryParse(_max.text.trim());
    if ((_from != null && _to != null && _to!.isBefore(_from!)) ||
        (min != null && max != null && max < min)) {
      setState(
        () => _error = context.tr('returnsInvalidRange'),
      );
      return;
    }
    Navigator.pop(
      context,
      ReturnFilters(
        search: widget.filters.search,
        status: _status,
        statusGroup: _status == null ? widget.filters.statusGroup : null,
        dateFrom: _from,
        dateTo: _to,
        refundMin: min,
        refundMax: max,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    String? amountValidator(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      final amount = double.tryParse(value.trim());
      return amount == null || !amount.isFinite || amount < 0
          ? l10n.tr('returnsInvalidAmount')
          : null;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('filters'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                CustomDropdown<String>(
                  label: l10n.tr('status'),
                  value: _status ?? '',
                  items: [
                    CustomDropdownItem(value: '', label: l10n.tr('all')),
                    ...widget.enums.statuses.map(
                      (e) => CustomDropdownItem(value: e.value, label: e.label),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value == '' ? null : value),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: l10n.tr('returnsDateFrom'),
                  controller: _fromText,
                  readOnly: true,
                  onTap: () => _date(true),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _from = null;
                      _fromText.clear();
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: l10n.tr('returnsDateTo'),
                  controller: _toText,
                  readOnly: true,
                  onTap: () => _date(false),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _to = null;
                      _toText.clear();
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: l10n.tr('returnsMinRefund'),
                  controller: _min,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: amountValidator,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: l10n.tr('returnsMaxRefund'),
                  controller: _max,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: amountValidator,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                PrimaryButton(text: l10n.tr('returnsApply'), onPressed: _apply),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ReturnFilters(search: widget.filters.search),
                  ),
                  child: Text(l10n.tr('clearFilters')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
