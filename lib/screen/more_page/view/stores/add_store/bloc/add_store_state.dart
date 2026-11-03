import 'package:equatable/equatable.dart';

class AddStoreState extends Equatable {
  final Map<String, dynamic> formData;
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final bool isEditMode;
  final bool isPickupEnabled;

  const AddStoreState({
    required this.formData,
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.isEditMode = false,
    this.isPickupEnabled = false,
  });

  AddStoreState copyWith({
    Map<String, dynamic>? formData,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    bool? isEditMode,
    bool? isPickupEnabled,
  }) {
    return AddStoreState(
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      isEditMode: isEditMode ?? this.isEditMode,
      isPickupEnabled: isPickupEnabled ?? this.isPickupEnabled,
    );
  }

  @override
  List<Object?> get props => [
    formData,
    isLoading,
    successMessage,
    errorMessage,
    isEditMode,
    isPickupEnabled,
  ];
}
