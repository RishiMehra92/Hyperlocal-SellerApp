import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class ReturnFilters extends Equatable {
  final String search;
  final String? status, statusGroup;
  final DateTime? dateFrom, dateTo;
  final double? refundMin, refundMax;
  const ReturnFilters({
    this.search = '',
    this.status,
    this.statusGroup,
    this.dateFrom,
    this.dateTo,
    this.refundMin,
    this.refundMax,
  });

  ReturnFilters withSearch(String value) => ReturnFilters(
    search: value.trim(),
    status: status,
    statusGroup: statusGroup,
    dateFrom: dateFrom,
    dateTo: dateTo,
    refundMin: refundMin,
    refundMax: refundMax,
  );
  // A primary group clears the exact status so the two filters cannot conflict.
  ReturnFilters withGroup(String? value) => ReturnFilters(
    search: search,
    statusGroup: value,
    dateFrom: dateFrom,
    dateTo: dateTo,
    refundMin: refundMin,
    refundMax: refundMax,
  );
  int get advancedCount => [
    status,
    dateFrom,
    dateTo,
    refundMin,
    refundMax,
  ].where((e) => e != null).length;
  Map<String, dynamic> toQuery() => {
    if (search.isNotEmpty) 'search': search,
    if (status != null) 'status': status,
    if (statusGroup != null) 'status_group': statusGroup,
    if (dateFrom != null)
      'date_from': DateFormat('yyyy-MM-dd').format(dateFrom!),
    if (dateTo != null) 'date_to': DateFormat('yyyy-MM-dd').format(dateTo!),
    if (refundMin != null) 'refund_min': refundMin,
    if (refundMax != null) 'refund_max': refundMax,
  };
  @override
  List<Object?> get props => [
    search,
    status,
    statusGroup,
    dateFrom,
    dateTo,
    refundMin,
    refundMax,
  ];
}
