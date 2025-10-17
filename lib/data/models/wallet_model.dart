import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final String userId;
  final double balance;
  final DateTime updatedAt;

  const WalletModel({required this.userId, required this.balance, required this.updatedAt});

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      userId: map['user_id'] as String,
      balance: (map['balance'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'user_id': userId, 'balance': balance, 'updated_at': updatedAt.toIso8601String()};
  }

  WalletModel copyWith({String? userId, double? balance, DateTime? updatedAt}) {
    return WalletModel(userId: userId ?? this.userId, balance: balance ?? this.balance, updatedAt: updatedAt ?? this.updatedAt);
  }

  @override
  List<Object?> get props => [userId, balance, updatedAt];
}
