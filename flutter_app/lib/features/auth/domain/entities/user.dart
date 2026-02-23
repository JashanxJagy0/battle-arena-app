import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final double walletBalance;
  final String? referralCode;
  final bool isVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.walletBalance,
    this.referralCode,
    required this.isVerified,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phone,
        avatarUrl,
        walletBalance,
        referralCode,
        isVerified,
        createdAt,
      ];
}
