import 'package:equatable/equatable.dart';

abstract class BonusEvent extends Equatable {
  const BonusEvent();

  @override
  List<Object?> get props => [];
}

class LoadBonuses extends BonusEvent {
  const LoadBonuses();
}

class ClaimDailyBonusEvent extends BonusEvent {
  final String bonusId;
  const ClaimDailyBonusEvent(this.bonusId);

  @override
  List<Object?> get props => [bonusId];
}

class ClaimWeeklyBonusEvent extends BonusEvent {
  final String bonusId;
  const ClaimWeeklyBonusEvent(this.bonusId);

  @override
  List<Object?> get props => [bonusId];
}

class ClaimMonthlyBonusEvent extends BonusEvent {
  final String bonusId;
  const ClaimMonthlyBonusEvent(this.bonusId);

  @override
  List<Object?> get props => [bonusId];
}

class RedeemPromoCodeEvent extends BonusEvent {
  final String code;
  const RedeemPromoCodeEvent(this.code);

  @override
  List<Object?> get props => [code];
}
