import 'package:equatable/equatable.dart';
import '../../domain/entities/leaderboard_entry.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();
  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myEntry;
  final String currentTab;
  final String currentPeriod;

  const LeaderboardLoaded({
    required this.entries,
    this.myEntry,
    required this.currentTab,
    required this.currentPeriod,
  });

  @override
  List<Object?> get props => [entries, myEntry, currentTab, currentPeriod];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
