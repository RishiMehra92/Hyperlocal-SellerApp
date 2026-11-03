import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/order_return_model.dart';
import '../repo/order_returns_repo.dart';

class ReturnDetailsState extends Equatable {
  final OrderReturn? details;
  final ReturnEnums enums;
  final bool isLoading, isUpdating;
  final String? error, enumsError, operationError, operationMessage;
  const ReturnDetailsState({
    this.details,
    this.enums = const ReturnEnums(),
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.enumsError,
    this.operationError,
    this.operationMessage,
  });
  @override
  List<Object?> get props => [
    details,
    enums,
    isLoading,
    isUpdating,
    error,
    enumsError,
    operationError,
    operationMessage,
  ];
}

class ReturnDetailsCubit extends Cubit<ReturnDetailsState> {
  final OrderReturnsRepo _repo;
  final int id;
  ReturnDetailsCubit(this._repo, this.id) : super(const ReturnDetailsState());

  Future<void> load() async {
    if (state.isLoading || state.isUpdating) return;
    emit(
      ReturnDetailsState(
        details: state.details,
        enums: state.enums,
        isLoading: true,
      ),
    );
    // Enum failure leaves details readable, with retry and actions disabled.
    ReturnEnums enums = state.enums;
    String? enumsError;
    final enumsFuture = _repo
        .getEnums()
        .then((value) {
          enums = value;
        })
        .catchError((Object e) {
          enumsError = e.toString();
        });
    try {
      final details = await _repo.getDetails(id);
      await enumsFuture;
      if (!isClosed) {
        emit(
          ReturnDetailsState(
            details: details,
            enums: enums,
            enumsError: enumsError,
          ),
        );
      }
    } catch (e) {
      await enumsFuture;
      if (!isClosed) {
        emit(
          ReturnDetailsState(
            enums: enums,
            error: e.toString(),
            enumsError: enumsError,
          ),
        );
      }
    }
  }

  Future<bool> submit({
    required String action,
    required bool storeConfirmation,
    String? comment,
    String? disputeReason,
    List<String> photos = const [],
  }) async {
    final current = state;
    final details = current.details;
    if (current.isUpdating ||
        current.isLoading ||
        details == null ||
        current.enumsError != null) {
      return false;
    }
    final allowed = storeConfirmation
        ? details.canInspectReceivedReturn &&
              current.enums.storeConfirmActions.contains(action)
        : details.canDecide && current.enums.decisionActions.contains(action);
    if (!allowed) return false;
    if (storeConfirmation &&
        action == 'escalate' &&
        (!current.enums.disputeReasons.contains(disputeReason) ||
            (comment?.trim().isEmpty ?? true) ||
            photos.isEmpty ||
            photos.any((path) => path.trim().isEmpty))) {
      return false;
    }
    emit(
      ReturnDetailsState(
        details: details,
        enums: current.enums,
        isUpdating: true,
      ),
    );
    String message;
    try {
      message = storeConfirmation
          ? await _repo.confirmStore(
              id,
              action: action,
              remarks: comment,
              disputeReason: disputeReason,
              inspectionPhotos: photos,
            )
          : await _repo.decide(id, action: action, sellerComment: comment);
    } catch (e) {
      if (!isClosed) {
        emit(
          ReturnDetailsState(
            details: details,
            enums: current.enums,
            operationError: e.toString(),
          ),
        );
      }
      return false;
    }
    // A partial mutation response is not a replacement for full detail data.
    // Hide stale actions until authoritative details have been reloaded.
    if (!isClosed) {
      emit(
        ReturnDetailsState(
          enums: current.enums,
          isLoading: true,
          operationMessage: message,
        ),
      );
    }
    try {
      final updated = await _repo.getDetails(id);
      if (!isClosed) {
        emit(
          ReturnDetailsState(
            details: updated,
            enums: current.enums,
            operationMessage: message,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          ReturnDetailsState(
            enums: current.enums,
            error: e.toString(),
            operationMessage: message,
          ),
        );
      }
    }
    return true;
  }
}
