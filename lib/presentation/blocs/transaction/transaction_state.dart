import 'package:equatable/equatable.dart';

import '../../../data/models/transaction_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  const TransactionLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

class TransactionSummaryLoaded extends TransactionState {
  final Map<String, double> summary;
  final List<TransactionModel> transactions;

  const TransactionSummaryLoaded({required this.summary, required this.transactions});

  @override
  List<Object?> get props => [summary, transactions];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}
