import 'package:equatable/equatable.dart';

import '../../domain/entities/bonus.dart';

abstract class BonusState extends Equatable {
  const BonusState();

  @override
  List<Object?> get props => [];
}

class BonusInitial extends BonusState {
  const BonusInitial();
}

class BonusLoading extends BonusState {
  const BonusLoading();
}

class BonusLoaded extends BonusState {
  final Bonus? dailyBonus;
  final Bonus? weeklyBonus;
  final Bonus? monthlyBonus;
  final List<Bonus> bonusHistory;
  final int currentStreak;
  final Map<String, dynamic> weeklyProgress;
  final Map<String, dynamic> monthlyProgress;

  const BonusLoaded({
    this.dailyBonus,
    this.weeklyBonus,
    this.monthlyBonus,
    this.bonusHistory = const [],
    this.currentStreak = 0,
    this.weeklyProgress = const {},
    this.monthlyProgress = const {},
  });

  @override
  List<Object?> get props => [dailyBonus, weeklyBonus, monthlyBonus, bonusHistory, currentStreak];

  BonusLoaded copyWith({
    Bonus? dailyBonus,
    Bonus? weeklyBonus,
    Bonus? monthlyBonus,
    List<Bonus>? bonusHistory,
    int? currentStreak,
    Map<String, dynamic>? weeklyProgress,
    Map<String, dynamic>? monthlyProgress,
  }) {
    return BonusLoaded(
      dailyBonus: dailyBonus ?? this.dailyBonus,
      weeklyBonus: weeklyBonus ?? this.weeklyBonus,
      monthlyBonus: monthlyBonus ?? this.monthlyBonus,
      bonusHistory: bonusHistory ?? this.bonusHistory,
      currentStreak: currentStreak ?? this.currentStreak,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
    );
  }
}

class BonusError extends BonusState {
  final String message;
  const BonusError({required this.message});

  @override
  List<Object?> get props => [message];
}

class BonusClaimed extends BonusState {
  final Bonus bonus;
  const BonusClaimed({required this.bonus});

  @override
  List<Object?> get props => [bonus];
}

class PromoCodeRedeemed extends BonusState {
  final Bonus bonus;
  const PromoCodeRedeemed({required this.bonus});

  @override
  List<Object?> get props => [bonus];
}

class PromoCodeError extends BonusState {
  final String message;
  const PromoCodeError({required this.message});

  @override
  List<Object?> get props => [message];
}
