import 'package:equatable/equatable.dart';

enum BonusType { daily, weekly, monthly, promo, referral }

class Bonus extends Equatable {
  final String id;
  final BonusType bonusType;
  final double amount;
  final double wageringRequirement;
  final double wageredAmount;
  final bool isClaimed;
  final bool isExpired;
  final DateTime? expiresAt;
  final DateTime? claimedAt;
  final String? promoCode;
  final String? description;

  const Bonus({
    required this.id,
    required this.bonusType,
    required this.amount,
    required this.wageringRequirement,
    required this.wageredAmount,
    required this.isClaimed,
    required this.isExpired,
    this.expiresAt,
    this.claimedAt,
    this.promoCode,
    this.description,
  });

  double get wageringProgress => wageringRequirement > 0 ? (wageredAmount / wageringRequirement).clamp(0.0, 1.0) : 1.0;

  @override
  List<Object?> get props => [id, bonusType, amount, wageringRequirement, wageredAmount, isClaimed, isExpired, expiresAt, claimedAt];
}
