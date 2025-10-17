import '../../core/constants/database_constants.dart';
import '../../core/errors/failures.dart';
import '../database/app_database.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  final AppDatabase database;

  WalletRepository(this.database);

  Future<WalletModel> getWalletBalance(String userId) async {
    try {
      final db = await database.database;

      final result = await db.query(
        DatabaseConstants.tableWalletBalance,
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        throw const DatabaseFailure('Wallet not found');
      }

      return WalletModel.fromMap(result.first);
    } catch (e) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to get wallet balance: ${e.toString()}');
    }
  }

  Future<void> updateBalance(String userId, double newBalance) async {
    try {
      final db = await database.database;

      final updated = await db.update(
        DatabaseConstants.tableWalletBalance,
        {DatabaseConstants.columnBalance: newBalance, DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String()},
        where: '${DatabaseConstants.columnUserId} = ?',
        whereArgs: [userId],
      );

      if (updated == 0) {
        throw const DatabaseFailure('Failed to update wallet balance');
      }
    } catch (e) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to update balance: ${e.toString()}');
    }
  }

  Future<bool> hasSufficientBalance(String userId, double amount) async {
    try {
      final wallet = await getWalletBalance(userId);
      return wallet.balance >= amount;
    } catch (e) {
      throw DatabaseFailure('Failed to check balance: ${e.toString()}');
    }
  }

  Future<void> executeAtomicTransfer({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required TransactionModel debitTransaction,
    required TransactionModel creditTransaction,
  }) async {
    final db = await database.database;

    try {
      await db.transaction((txn) async {
        final senderResult = await txn.query(
          DatabaseConstants.tableWalletBalance,
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [fromUserId],
        );

        if (senderResult.isEmpty) {
          throw const DatabaseFailure('Sender wallet not found');
        }

        final senderBalance = (senderResult.first[DatabaseConstants.columnBalance] as num).toDouble();

        if (senderBalance < amount) {
          throw const InsufficientBalanceFailure('Insufficient balance for transfer');
        }

        await txn.update(
          DatabaseConstants.tableWalletBalance,
          {DatabaseConstants.columnBalance: senderBalance - amount, DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String()},
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [fromUserId],
        );

        await txn.insert(DatabaseConstants.tableTransactions, debitTransaction.toMap());

        final receiverResult = await txn.query(
          DatabaseConstants.tableWalletBalance,
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [toUserId],
        );

        if (receiverResult.isEmpty) {
          throw const DatabaseFailure('Receiver wallet not found');
        }

        final receiverBalance = (receiverResult.first[DatabaseConstants.columnBalance] as num).toDouble();

        await txn.update(
          DatabaseConstants.tableWalletBalance,
          {DatabaseConstants.columnBalance: receiverBalance + amount, DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String()},
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [toUserId],
        );

        await txn.insert(DatabaseConstants.tableTransactions, creditTransaction.toMap());
      });
    } catch (e) {
      if (e is InsufficientBalanceFailure || e is DatabaseFailure) {
        rethrow;
      }
      throw TransactionFailure('Atomic transfer failed: ${e.toString()}');
    }
  }

  Future<void> executeAddMoney({required String userId, required double amount, required TransactionModel transaction}) async {
    final db = await database.database;

    try {
      await db.transaction((txn) async {
        final result = await txn.query(
          DatabaseConstants.tableWalletBalance,
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [userId],
        );

        if (result.isEmpty) {
          throw const DatabaseFailure('Wallet not found');
        }

        final currentBalance = (result.first[DatabaseConstants.columnBalance] as num).toDouble();

        await txn.update(
          DatabaseConstants.tableWalletBalance,
          {DatabaseConstants.columnBalance: currentBalance + amount, DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String()},
          where: '${DatabaseConstants.columnUserId} = ?',
          whereArgs: [userId],
        );

        await txn.insert(DatabaseConstants.tableTransactions, transaction.toMap());
      });
    } catch (e) {
      if (e is DatabaseFailure) rethrow;
      throw TransactionFailure('Failed to add money: ${e.toString()}');
    }
  }
}
