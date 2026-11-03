import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../model/return_reason_model.dart';

class ReturnReasonsState extends Equatable {
  final List<ReturnReason> items;
  final ApiStatus fetchStatus;
  final ApiStatus addStatus;
  final ApiStatus updateStatus;
  final ApiStatus deleteStatus;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
  final bool? operationSuccess;
  final String? operationMessage;

  const ReturnReasonsState({
    this.items = const [],
    this.fetchStatus = ApiStatus.initial,
    this.addStatus = ApiStatus.initial,
    this.updateStatus = ApiStatus.initial,
    this.deleteStatus = ApiStatus.initial,
    this.hasMore = true,
    this.currentPage = 1,
    this.errorMessage,
    this.operationSuccess,
    this.operationMessage,
  });

  ReturnReasonsState copyWith({
    List<ReturnReason>? items,
    ApiStatus? fetchStatus,
    ApiStatus? addStatus,
    ApiStatus? updateStatus,
    ApiStatus? deleteStatus,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    bool? operationSuccess,
    String? operationMessage,
    bool clearOperation = false,
  }) {
    return ReturnReasonsState(
      items: items ?? this.items,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      addStatus: addStatus ?? this.addStatus,
      updateStatus: updateStatus ?? this.updateStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearOperation ? null : (errorMessage ?? this.errorMessage),
      operationSuccess: clearOperation
          ? null
          : (operationSuccess ?? this.operationSuccess),
      operationMessage: clearOperation
          ? null
          : (operationMessage ?? this.operationMessage),
    );
  }

  @override
  List<Object?> get props => [
    items,
    fetchStatus,
    addStatus,
    updateStatus,
    deleteStatus,
    hasMore,
    currentPage,
    errorMessage,
    operationSuccess,
    operationMessage,
  ];
}
