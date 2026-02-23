import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

export 'leaderboard_event.dart';
export 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GetLeaderboard _getLeaderboard;
  final LeaderboardRepository _repository;
  String _currentTab = 'ludo';
  String _currentPeriod = 'weekly';

  LeaderboardBloc({
    required GetLeaderboard getLeaderboard,
    required LeaderboardRepository repository,
  })  : _getLeaderboard = getLeaderboard,
        _repository = repository,
        super(const LeaderboardInitial()) {
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<ChangeLeaderboardTab>(_onChangeTab);
    on<ChangeLeaderboardPeriod>(_onChangePeriod);
  }

  Future<void> _onLoadLeaderboard(LoadLeaderboard event, Emitter<LeaderboardState> emit) async {
    _currentTab = event.tab;
    _currentPeriod = event.period;
    emit(const LeaderboardLoading());
    try {
      final results = await Future.wait([
        _getLeaderboard(tab: event.tab, period: event.period),
        _repository.getMyRank(tab: event.tab, period: event.period),
      ]);
      emit(LeaderboardLoaded(
        entries: results[0] as dynamic,
        myEntry: results[1] as dynamic,
        currentTab: event.tab,
        currentPeriod: event.period,
      ));
    } catch (e) {
      emit(LeaderboardError(message: e.toString()));
    }
  }

  Future<void> _onChangeTab(ChangeLeaderboardTab event, Emitter<LeaderboardState> emit) async {
    add(LoadLeaderboard(tab: event.tab, period: _currentPeriod));
  }

  Future<void> _onChangePeriod(ChangeLeaderboardPeriod event, Emitter<LeaderboardState> emit) async {
    add(LoadLeaderboard(tab: _currentTab, period: event.period));
  }
}
