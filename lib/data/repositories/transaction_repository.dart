import 'package:uuid/uuid.dart';

import '../../core/constants/database_constants.dart';
import '../../core/errors/failures.dart';
import '../database/app_database.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final AppDatabase database;
  final Uuid _uuid = const Uuid();

  TransactionRepository(this.database);

  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      final db = await database.database;
      await db.insert(DatabaseConstants.tableTransactions, transaction.toMap());
    } catch (e) {
      throw DatabaseFailure('Failed to create transaction: ${e.toString()}');
    }
  }

  Future<void> createMoneyAddedTransaction({required String userId, required double amount, required String note}) async {
    final transaction = TransactionModel(
      transactionId: _uuid.v4(),
      fromUserId: null,
      toUserId: userId,
      amount: amount,
      type: TransactionType.credit,
      datetime: DateTime.now(),
      note: note,
    );

    await createTransaction(transaction);
  }

  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final db = await database.database;

      final result = await db.query(
        DatabaseConstants.tableTransactions,
        where: '${DatabaseConstants.columnFromUserId} = ? OR ${DatabaseConstants.columnToUserId} = ?',
        whereArgs: [userId, userId],
        orderBy: '${DatabaseConstants.columnDatetime} DESC',
      );

      return result.map((map) => TransactionModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to get transactions: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getTransactionSummary(String userId) async {
    try {
      final transactions = await getUserTransactions(userId);

      double totalSent = 0;
      double totalReceived = 0;

      for (var transaction in transactions) {
        if (transaction.fromUserId == userId && transaction.type == TransactionType.debit) {
          totalSent += transaction.amount;
        } else if (transaction.toUserId == userId && transaction.type == TransactionType.credit) {
          totalReceived += transaction.amount;
        }
      }

      return {'totalSent': totalSent, 'totalReceived': totalReceived, 'netBalance': totalReceived - totalSent};
    } catch (e) {
      throw DatabaseFailure('Failed to calculate summary: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> searchTransactions({required String userId, String? searchQuery, TransactionType? filterType}) async {
    try {
      final allTransactions = await getUserTransactions(userId);

      var filtered = allTransactions;

      if (filterType != null) {
        filtered = filtered.where((t) => t.type == filterType).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        filtered =
            filtered.where((t) {
              return t.note.toLowerCase().contains(searchQuery.toLowerCase()) || t.amount.toString().contains(searchQuery);
            }).toList();
      }

      return filtered;
    } catch (e) {
      throw DatabaseFailure('Failed to search transactions: ${e.toString()}');
    }
  }
}
