import 'package:equatable/equatable.dart';

import '../../../data/models/wallet_model.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletLoaded extends WalletState {
  final WalletModel wallet;

  const WalletLoaded({required this.wallet});

  @override
  List<Object?> get props => [wallet];
}

class WalletTransactionSuccess extends WalletState {
  final String message;
  final WalletModel wallet;

  const WalletTransactionSuccess({required this.message, required this.wallet});

  @override
  List<Object?> get props => [message, wallet];
}

class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}
