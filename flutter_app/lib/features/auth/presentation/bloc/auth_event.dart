import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  const LoginRequested({required this.identifier, required this.password});

  @override
  List<Object?> get props => [identifier, password];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String password;
  final String? email;
  final String? phone;
  final String? referralCode;

  const RegisterRequested({
    required this.username,
    required this.password,
    this.email,
    this.phone,
    this.referralCode,
  });

  @override
  List<Object?> get props => [username, password, email, phone, referralCode];
}

class OTPSent extends AuthEvent {
  final String phone;

  const OTPSent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class OTPVerified extends AuthEvent {
  final String phone;
  final String otp;

  const OTPVerified({required this.phone, required this.otp});

  @override
  List<Object?> get props => [phone, otp];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
