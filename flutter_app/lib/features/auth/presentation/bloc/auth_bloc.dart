import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OTPSent>(_onOTPSent);
    on<OTPVerified>(_onOTPVerified);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          emit(const Unauthenticated());
        }
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.login(
        identifier: event.identifier,
        password: event.password,
      );
      emit(Authenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        username: event.username,
        password: event.password,
        email: event.email,
        phone: event.phone,
        referralCode: event.referralCode,
      );
      emit(RegistrationSuccess(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onOTPSent(
    OTPSent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendOtp(phone: event.phone);
      emit(OTPSentState(phone: event.phone));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onOTPVerified(
    OTPVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.verifyOtp(
        phone: event.phone,
        otp: event.otp,
      );
      emit(Authenticated(user: result.user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
