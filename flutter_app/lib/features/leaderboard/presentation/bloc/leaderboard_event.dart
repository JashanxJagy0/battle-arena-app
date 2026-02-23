import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeaderboard extends LeaderboardEvent {
  final String tab;
  final String period;
  const LoadLeaderboard({this.tab = 'ludo', this.period = 'weekly'});
  @override
  List<Object?> get props => [tab, period];
}

class ChangeLeaderboardTab extends LeaderboardEvent {
  final String tab;
  const ChangeLeaderboardTab(this.tab);
  @override
  List<Object?> get props => [tab];
}

class ChangeLeaderboardPeriod extends LeaderboardEvent {
  final String period;
  const ChangeLeaderboardPeriod(this.period);
  @override
  List<Object?> get props => [period];
}
