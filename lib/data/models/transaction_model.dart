import 'package:equatable/equatable.dart';

enum TransactionType {
  credit,
  debit;

  String get value => name;

  static TransactionType fromString(String type) {
    return TransactionType.values.firstWhere((e) => e.name == type.toLowerCase(), orElse: () => TransactionType.credit);
  }
}

class TransactionModel extends Equatable {
  final String transactionId;
  final String? fromUserId;
  final String toUserId;
  final double amount;
  final TransactionType type;
  final DateTime datetime;
  final String note;

  const TransactionModel({
    required this.transactionId,
    this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.type,
    required this.datetime,
    required this.note,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transaction_id'] as String,
      fromUserId: map['from_user_id'] as String?,
      toUserId: map['to_user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String),
      datetime: DateTime.parse(map['datetime'] as String),
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'type': type.value,
      'datetime': datetime.toIso8601String(),
      'note': note,
    };
  }

  @override
  List<Object?> get props => [transactionId, fromUserId, toUserId, amount, type, datetime, note];
}
