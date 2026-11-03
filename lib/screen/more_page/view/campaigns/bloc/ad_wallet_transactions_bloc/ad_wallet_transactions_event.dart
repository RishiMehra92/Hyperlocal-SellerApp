part of 'ad_wallet_transactions_bloc.dart';

abstract class AdWalletTransactionsEvent extends Equatable {
  const AdWalletTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsInitial extends AdWalletTransactionsEvent {
  final String? transactionType;
  final String? status;

  const LoadTransactionsInitial({this.transactionType, this.status});

  @override
  List<Object?> get props => [transactionType, status];
}

class FilterTransactions extends AdWalletTransactionsEvent {
  final String? transactionType;
  final String? status;

  const FilterTransactions({this.transactionType, this.status});

  @override
  List<Object?> get props => [transactionType, status];
}

class LoadMoreTransactions extends AdWalletTransactionsEvent {}

class RefreshTransactions extends AdWalletTransactionsEvent {}

class TransactionsReset extends AdWalletTransactionsEvent {}

class _UpdateTransactionsState extends AdWalletTransactionsEvent {
  final AdWalletTransactionsState state;

  const _UpdateTransactionsState(this.state);

  @override
  List<Object?> get props => [state];
}
