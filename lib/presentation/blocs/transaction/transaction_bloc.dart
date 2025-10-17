import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository}) : super(const TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionSearchRequested>(_onSearchRequested);
    on<TransactionSummaryRequested>(_onSummaryRequested);
  }

  Future<void> _onLoadRequested(TransactionLoadRequested event, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());

    try {
      final transactions = await transactionRepository.getUserTransactions(event.userId);
      emit(TransactionLoaded(transactions: transactions));
    } catch (e) {
      emit(TransactionError(message: 'Failed to load transactions: ${e.toString()}'));
    }
  }

  Future<void> _onSearchRequested(TransactionSearchRequested event, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());

    try {
      final transactions = await transactionRepository.searchTransactions(
        userId: event.userId,
        searchQuery: event.searchQuery,
        filterType: event.filterType,
      );
      emit(TransactionLoaded(transactions: transactions));
    } catch (e) {
      emit(TransactionError(message: 'Failed to search transactions: ${e.toString()}'));
    }
  }

  Future<void> _onSummaryRequested(TransactionSummaryRequested event, Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());

    try {
      final summary = await transactionRepository.getTransactionSummary(event.userId);
      final transactions = await transactionRepository.getUserTransactions(event.userId);

      emit(TransactionSummaryLoaded(summary: summary, transactions: transactions));
    } catch (e) {
      emit(TransactionError(message: 'Failed to load summary: ${e.toString()}'));
    }
  }
}
