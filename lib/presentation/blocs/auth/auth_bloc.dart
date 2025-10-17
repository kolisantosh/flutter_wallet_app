import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository userRepository;
  final WalletRepository walletRepository;

  AuthBloc({required this.userRepository, required this.walletRepository}) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(const AuthError(message: 'Email and password are required'));
        return;
      }

      if (!_isValidEmail(event.email)) {
        emit(const AuthError(message: 'Please enter a valid email'));
        return;
      }

      final user = await userRepository.login(email: event.email, password: event.password);

      emit(AuthAuthenticated(user: user));
    } on AuthenticationFailure catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      if (event.email.isEmpty || event.password.isEmpty || event.name.isEmpty) {
        emit(const AuthError(message: 'All fields are required'));
        return;
      }

      if (!_isValidEmail(event.email)) {
        emit(const AuthError(message: 'Please enter a valid email'));
        return;
      }

      if (event.password.length < 6) {
        emit(const AuthError(message: 'Password must be at least 6 characters'));
        return;
      }

      final user = await userRepository.register(email: event.email, password: event.password, name: event.name);

      emit(AuthAuthenticated(user: user));
    } on AuthenticationFailure catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {}

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
