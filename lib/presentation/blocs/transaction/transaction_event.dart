import 'package:equatable/equatable.dart';

import '../../../data/models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionLoadRequested extends TransactionEvent {
  final String userId;

  const TransactionLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class TransactionSearchRequested extends TransactionEvent {
  final String userId;
  final String searchQuery;
  final TransactionType? filterType;

  const TransactionSearchRequested({required this.userId, required this.searchQuery, this.filterType});

  @override
  List<Object?> get props => [userId, searchQuery, filterType];
}

class TransactionSummaryRequested extends TransactionEvent {
  final String userId;

  const TransactionSummaryRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}
