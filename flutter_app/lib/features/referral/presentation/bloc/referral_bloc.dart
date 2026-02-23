import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_referral_stats.dart';
import 'referral_event.dart';
import 'referral_state.dart';

export 'referral_event.dart';
export 'referral_state.dart';

class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final GetReferralStats _getReferralStats;

  ReferralBloc({required GetReferralStats getReferralStats})
      : _getReferralStats = getReferralStats,
        super(const ReferralInitial()) {
    on<LoadReferralStats>(_onLoadReferralStats);
  }

  Future<void> _onLoadReferralStats(LoadReferralStats event, Emitter<ReferralState> emit) async {
    emit(const ReferralLoading());
    try {
      final stats = await _getReferralStats();
      emit(ReferralLoaded(stats: stats));
    } catch (e) {
      emit(ReferralError(message: e.toString()));
    }
  }
}
