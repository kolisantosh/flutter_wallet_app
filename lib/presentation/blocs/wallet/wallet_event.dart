import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  final String userId;

  const WalletLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class WalletAddMoneyRequested extends WalletEvent {
  final String userId;
  final double amount;
  final String note;

  const WalletAddMoneyRequested({required this.userId, required this.amount, required this.note});

  @override
  List<Object?> get props => [userId, amount, note];
}

class WalletSendMoneyRequested extends WalletEvent {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String note;

  const WalletSendMoneyRequested({required this.fromUserId, required this.toUserId, required this.amount, required this.note});

  @override
  List<Object?> get props => [fromUserId, toUserId, amount, note];
}
