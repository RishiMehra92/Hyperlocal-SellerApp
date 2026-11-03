import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../repo/return_reasons_repo.dart';
import '../model/return_reason_model.dart';
import 'return_reasons_event.dart';
import 'return_reasons_state.dart';

class ReturnReasonsBloc extends Bloc<ReturnReasonsEvent, ReturnReasonsState> {
  final ReturnReasonsRepo _repo;

  ReturnReasonsBloc(this._repo) : super(const ReturnReasonsState()) {
    on<LoadReturnReasonsInitial>(_onLoadReturnReasonsInitial);
    on<LoadMoreReturnReasons>(_onLoadMoreReturnReasons);
    on<AddReturnReasonEvent>(_onAddReturnReason);
    on<UpdateReturnReasonEvent>(_onUpdateReturnReason);
    on<DeleteReturnReasonEvent>(_onDeleteReturnReason);
  }

  Future<void> _onLoadReturnReasonsInitial(
    LoadReturnReasonsInitial event,
    Emitter<ReturnReasonsState> emit,
  ) async {
    emit(
      state.copyWith(
        fetchStatus: ApiStatus.loading,
        items: [],
        currentPage: 1,
        hasMore: true,
        clearOperation: true,
      ),
    );
    try {
      final response = await _repo.getReturnReasons(page: 1);
      final success = response['success'] as bool? ?? false;
      if (success && response['data'] != null) {
        final dataMap = response['data'] as Map<String, dynamic>;
        final list = dataMap['data'] as List? ?? [];
        final items = list
            .map((e) => ReturnReason.fromJson(e as Map<String, dynamic>))
            .toList();
        final currentPage = dataMap['current_page'] as int? ?? 1;
        final lastPage = dataMap['last_page'] as int? ?? 1;

        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            items: items,
            currentPage: currentPage,
            hasMore: currentPage < lastPage,
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failure,
            errorMessage: 'Failed to fetch return reasons',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreReturnReasons(
    LoadMoreReturnReasons event,
    Emitter<ReturnReasonsState> emit,
  ) async {
    if (state.fetchStatus == ApiStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(fetchStatus: ApiStatus.loadingMore));
    final nextPage = state.currentPage + 1;
    try {
      final response = await _repo.getReturnReasons(page: nextPage);
      final success = response['success'] as bool? ?? false;
      if (success && response['data'] != null) {
        final dataMap = response['data'] as Map<String, dynamic>;
        final list = dataMap['data'] as List? ?? [];
        final items = list
            .map((e) => ReturnReason.fromJson(e as Map<String, dynamic>))
            .toList();
        final currentPage = dataMap['current_page'] as int? ?? nextPage;
        final lastPage = dataMap['last_page'] as int? ?? nextPage;

        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            items: List.from(state.items)..addAll(items),
            currentPage: currentPage,
            hasMore: currentPage < lastPage,
          ),
        );
      } else {
        emit(
          state.copyWith(fetchStatus: ApiStatus.success),
        ); // Keep previous items on failure
      }
    } catch (e) {
      emit(state.copyWith(fetchStatus: ApiStatus.success));
    }
  }

  Future<void> _onAddReturnReason(
    AddReturnReasonEvent event,
    Emitter<ReturnReasonsState> emit,
  ) async {
    emit(state.copyWith(addStatus: ApiStatus.loading, clearOperation: true));
    try {
      final response = await _repo.addReturnReason(event.reason);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Return reason added successfully';
      if (success) {
        emit(
          state.copyWith(
            addStatus: ApiStatus.success,
            operationSuccess: true,
            operationMessage: message,
          ),
        );
        // Reload list automatically
        add(LoadReturnReasonsInitial());
      } else {
        emit(
          state.copyWith(
            addStatus: ApiStatus.failure,
            operationSuccess: false,
            operationMessage: 'Failed to add return reason',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          addStatus: ApiStatus.failure,
          operationSuccess: false,
          operationMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateReturnReason(
    UpdateReturnReasonEvent event,
    Emitter<ReturnReasonsState> emit,
  ) async {
    emit(state.copyWith(updateStatus: ApiStatus.loading, clearOperation: true));
    try {
      final response = await _repo.updateReturnReason(event.reason);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ??
          'Return reason updated successfully';
      if (success) {
        emit(
          state.copyWith(
            updateStatus: ApiStatus.success,
            operationSuccess: true,
            operationMessage: message,
          ),
        );
        // Reload list automatically
        add(LoadReturnReasonsInitial());
      } else {
        emit(
          state.copyWith(
            updateStatus: ApiStatus.failure,
            operationSuccess: false,
            operationMessage: 'Failed to update return reason',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          updateStatus: ApiStatus.failure,
          operationSuccess: false,
          operationMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteReturnReason(
    DeleteReturnReasonEvent event,
    Emitter<ReturnReasonsState> emit,
  ) async {
    emit(state.copyWith(deleteStatus: ApiStatus.loading, clearOperation: true));
    try {
      final response = await _repo.deleteReturnReason(event.id);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ??
          'Return reason deleted successfully';
      if (success) {
        emit(
          state.copyWith(
            deleteStatus: ApiStatus.success,
            operationSuccess: true,
            operationMessage: message,
          ),
        );
        // Reload list automatically
        add(LoadReturnReasonsInitial());
      } else {
        emit(
          state.copyWith(
            deleteStatus: ApiStatus.failure,
            operationSuccess: false,
            operationMessage: 'Failed to delete return reason',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          deleteStatus: ApiStatus.failure,
          operationSuccess: false,
          operationMessage: e.toString(),
        ),
      );
    }
  }
}
