import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_wagers.dart';
import '../../domain/usecases/get_wager_stats.dart';
import '../../domain/repositories/wager_repository.dart';
import 'wager_event.dart';
import 'wager_state.dart';

export 'wager_event.dart';
export 'wager_state.dart';

class WagerBloc extends Bloc<WagerEvent, WagerState> {
  final GetWagers _getWagers;
  final GetWagerStats _getWagerStats;
  final WagerRepository _repository;

  WagerBloc({
    required GetWagers getWagers,
    required GetWagerStats getWagerStats,
    required WagerRepository repository,
  })  : _getWagers = getWagers,
        _getWagerStats = getWagerStats,
        _repository = repository,
        super(const WagerInitial()) {
    on<LoadWagerHistory>(_onLoadWagerHistory);
    on<LoadMoreWagers>(_onLoadMoreWagers);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadWagerHistory(LoadWagerHistory event, Emitter<WagerState> emit) async {
    emit(const WagerLoading());
    try {
      final results = await Future.wait([
        _getWagerStats(period: event.period),
        _getWagers(period: event.period, page: 1),
        _repository.getChartData(period: event.period),
      ]);

      emit(WagerLoaded(
        stats: results[0] as dynamic,
        wagers: results[1] as dynamic,
        chartData: results[2] as dynamic,
        currentPeriod: event.period,
        currentPage: 1,
        hasMore: (results[1] as List).length >= 20,
      ));
    } catch (e) {
      emit(WagerError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreWagers(LoadMoreWagers event, Emitter<WagerState> emit) async {
    final current = state;
    if (current is! WagerLoaded || !current.hasMore) return;
    try {
      final nextPage = current.currentPage + 1;
      final newWagers = await _getWagers(period: current.currentPeriod, page: nextPage);
      emit(current.copyWith(
        wagers: [...current.wagers, ...newWagers],
        currentPage: nextPage,
        hasMore: newWagers.length >= 20,
      ));
    } catch (_) {}
  }

  Future<void> _onChangePeriod(ChangePeriod event, Emitter<WagerState> emit) async {
    add(LoadWagerHistory(period: event.period));
  }
}
