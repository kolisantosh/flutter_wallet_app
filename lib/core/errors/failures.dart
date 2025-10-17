import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure(String message) : super(message);
}

class TransactionFailure extends Failure {
  const TransactionFailure(String message) : super(message);
}
