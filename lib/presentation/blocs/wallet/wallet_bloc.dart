import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;
  final TransactionRepository transactionRepository;
  final Uuid _uuid = const Uuid();

  WalletBloc({required this.walletRepository, required this.transactionRepository}) : super(const WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletAddMoneyRequested>(_onAddMoneyRequested);
    on<WalletSendMoneyRequested>(_onSendMoneyRequested);
  }

  Future<void> _onLoadRequested(WalletLoadRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      final wallet = await walletRepository.getWalletBalance(event.userId);
      emit(WalletLoaded(wallet: wallet));
    } catch (e) {
      emit(WalletError(message: 'Failed to load wallet: ${e.toString()}'));
    }
  }

  Future<void> _onAddMoneyRequested(WalletAddMoneyRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      if (event.amount <= 0) {
        emit(const WalletError(message: 'Amount must be greater than 0'));
        return;
      }

      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        fromUserId: null,
        toUserId: event.userId,
        amount: event.amount,
        type: TransactionType.credit,
        datetime: DateTime.now(),
        note: event.note.isEmpty ? 'Money added to wallet' : event.note,
      );

      await walletRepository.executeAddMoney(userId: event.userId, amount: event.amount, transaction: transaction);

      final updatedWallet = await walletRepository.getWalletBalance(event.userId);

      emit(WalletTransactionSuccess(message: 'Money added successfully', wallet: updatedWallet));
    } catch (e) {
      emit(WalletError(message: 'Failed to add money: ${e.toString()}'));
    }
  }

  Future<void> _onSendMoneyRequested(WalletSendMoneyRequested event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());

    try {
      if (event.amount <= 0) {
        emit(const WalletError(message: 'Amount must be greater than 0'));
        return;
      }

      if (event.fromUserId == event.toUserId) {
        emit(const WalletError(message: 'Cannot send money to yourself'));
        return;
      }

      final hasSufficientBalance = await walletRepository.hasSufficientBalance(event.fromUserId, event.amount);

      if (!hasSufficientBalance) {
        emit(const WalletError(message: 'Insufficient balance'));
        return;
      }

      await _executeAtomicTransfer(
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        amount: event.amount,
        note: event.note.isEmpty ? 'Money transfer' : event.note,
      );

      final updatedWallet = await walletRepository.getWalletBalance(event.fromUserId);

      emit(WalletTransactionSuccess(message: 'Money sent successfully', wallet: updatedWallet));
    } on InsufficientBalanceFailure catch (e) {
      emit(WalletError(message: e.message));
    } on TransactionFailure catch (e) {
      emit(WalletError(message: e.message));
    } catch (e) {
      emit(WalletError(message: 'Failed to send money: ${e.toString()}'));
    }
  }

  Future<void> _executeAtomicTransfer({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String note,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final now = DateTime.now();

      final debitTransaction = TransactionModel(
        transactionId: '${transactionId}_debit',
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        type: TransactionType.debit,
        datetime: now,
        note: note,
      );

      final creditTransaction = TransactionModel(
        transactionId: '${transactionId}_credit',
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        type: TransactionType.credit,
        datetime: now,
        note: note,
      );

      await walletRepository.executeAtomicTransfer(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        debitTransaction: debitTransaction,
        creditTransaction: creditTransaction,
      );
    } catch (e) {
      if (e is InsufficientBalanceFailure || e is TransactionFailure) {
        rethrow;
      }
      throw TransactionFailure('Atomic transfer failed: ${e.toString()}');
    }
  }
}
