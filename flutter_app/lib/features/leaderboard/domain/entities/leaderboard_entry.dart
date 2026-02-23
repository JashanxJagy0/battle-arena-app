import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final double statValue;
  final int gamesPlayed;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.statValue,
    required this.gamesPlayed,
  });

  @override
  List<Object?> get props => [userId, rank];
}
