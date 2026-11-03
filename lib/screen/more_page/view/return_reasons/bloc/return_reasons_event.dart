import 'package:equatable/equatable.dart';
import '../model/return_reason_model.dart';

abstract class ReturnReasonsEvent extends Equatable {
  const ReturnReasonsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReturnReasonsInitial extends ReturnReasonsEvent {}

class LoadMoreReturnReasons extends ReturnReasonsEvent {}

class AddReturnReasonEvent extends ReturnReasonsEvent {
  final ReturnReason reason;

  const AddReturnReasonEvent(this.reason);

  @override
  List<Object?> get props => [reason];
}

class DeleteReturnReasonEvent extends ReturnReasonsEvent {
  final int id;

  const DeleteReturnReasonEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateReturnReasonEvent extends ReturnReasonsEvent {
  final ReturnReason reason;

  const UpdateReturnReasonEvent(this.reason);

  @override
  List<Object?> get props => [reason];
}
