import 'package:equatable/equatable.dart';

class LeaderboardModel extends Equatable {
  final int rank;
  final String userId;
  final String username;
  final int kills;
  final int placement;
  final int points;
  final double prize;

  const LeaderboardModel({
    required this.rank,
    required this.userId,
    required this.username,
    required this.kills,
    required this.placement,
    required this.points,
    required this.prize,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      kills: json['kills'] as int? ?? 0,
      placement: json['placement'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      prize: (json['prize'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props =>
      [rank, userId, username, kills, placement, points, prize];
}
