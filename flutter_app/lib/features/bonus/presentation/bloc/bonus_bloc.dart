import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/claim_daily_bonus.dart';
import '../../domain/usecases/claim_weekly_bonus.dart';
import '../../domain/usecases/claim_monthly_bonus.dart';
import '../../domain/usecases/redeem_promo_code.dart';
import '../../domain/repositories/bonus_repository.dart';
import 'bonus_event.dart';
import 'bonus_state.dart';

export 'bonus_event.dart';
export 'bonus_state.dart';

class BonusBloc extends Bloc<BonusEvent, BonusState> {
  final ClaimDailyBonus _claimDailyBonus;
  final ClaimWeeklyBonus _claimWeeklyBonus;
  final ClaimMonthlyBonus _claimMonthlyBonus;
  final RedeemPromoCode _redeemPromoCode;
  final BonusRepository _repository;

  BonusBloc({
    required ClaimDailyBonus claimDailyBonus,
    required ClaimWeeklyBonus claimWeeklyBonus,
    required ClaimMonthlyBonus claimMonthlyBonus,
    required RedeemPromoCode redeemPromoCode,
    required BonusRepository repository,
  })  : _claimDailyBonus = claimDailyBonus,
        _claimWeeklyBonus = claimWeeklyBonus,
        _claimMonthlyBonus = claimMonthlyBonus,
        _redeemPromoCode = redeemPromoCode,
        _repository = repository,
        super(const BonusInitial()) {
    on<LoadBonuses>(_onLoadBonuses);
    on<ClaimDailyBonusEvent>(_onClaimDailyBonus);
    on<ClaimWeeklyBonusEvent>(_onClaimWeeklyBonus);
    on<ClaimMonthlyBonusEvent>(_onClaimMonthlyBonus);
    on<RedeemPromoCodeEvent>(_onRedeemPromoCode);
  }

  Future<void> _onLoadBonuses(LoadBonuses event, Emitter<BonusState> emit) async {
    emit(const BonusLoading());
    try {
      final results = await Future.wait([
        _repository.getDailyBonus().then<dynamic>((v) => v).catchError((_) => null),
        _repository.getWeeklyBonus().then<dynamic>((v) => v).catchError((_) => null),
        _repository.getMonthlyBonus().then<dynamic>((v) => v).catchError((_) => null),
        _repository.getBonuses().then<dynamic>((v) => v).catchError((_) => <dynamic>[]),
        _repository.getCurrentStreak().then<dynamic>((v) => v).catchError((_) => 0),
        _repository.getWeeklyProgress().then<dynamic>((v) => v).catchError((_) => <String, dynamic>{}),
        _repository.getMonthlyProgress().then<dynamic>((v) => v).catchError((_) => <String, dynamic>{}),
      ]);

      emit(BonusLoaded(
        dailyBonus: results[0] as dynamic,
        weeklyBonus: results[1] as dynamic,
        monthlyBonus: results[2] as dynamic,
        bonusHistory: (results[3] as List?)?.cast() ?? [],
        currentStreak: results[4] as int? ?? 0,
        weeklyProgress: results[5] as Map<String, dynamic>? ?? {},
        monthlyProgress: results[6] as Map<String, dynamic>? ?? {},
      ));
    } catch (e) {
      emit(BonusError(message: e.toString()));
    }
  }

  Future<void> _onClaimDailyBonus(ClaimDailyBonusEvent event, Emitter<BonusState> emit) async {
    try {
      final bonus = await _claimDailyBonus(event.bonusId);
      emit(BonusClaimed(bonus: bonus));
      add(const LoadBonuses());
    } catch (e) {
      emit(BonusError(message: e.toString()));
    }
  }

  Future<void> _onClaimWeeklyBonus(ClaimWeeklyBonusEvent event, Emitter<BonusState> emit) async {
    try {
      final bonus = await _claimWeeklyBonus(event.bonusId);
      emit(BonusClaimed(bonus: bonus));
      add(const LoadBonuses());
    } catch (e) {
      emit(BonusError(message: e.toString()));
    }
  }

  Future<void> _onClaimMonthlyBonus(ClaimMonthlyBonusEvent event, Emitter<BonusState> emit) async {
    try {
      final bonus = await _claimMonthlyBonus(event.bonusId);
      emit(BonusClaimed(bonus: bonus));
      add(const LoadBonuses());
    } catch (e) {
      emit(BonusError(message: e.toString()));
    }
  }

  Future<void> _onRedeemPromoCode(RedeemPromoCodeEvent event, Emitter<BonusState> emit) async {
    try {
      final bonus = await _redeemPromoCode(event.code);
      emit(PromoCodeRedeemed(bonus: bonus));
      add(const LoadBonuses());
    } catch (e) {
      emit(PromoCodeError(message: e.toString()));
    }
  }
}
