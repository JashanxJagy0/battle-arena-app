import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.userId,
    required super.username,
    super.avatarUrl,
    required super.rank,
    required super.statValue,
    required super.gamesPlayed,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json, {int rank = 0}) {
    return LeaderboardEntryModel(
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      rank: json['rank'] as int? ?? rank,
      statValue: (json['statValue'] as num?)?.toDouble() ??
          (json['earnings'] as num?)?.toDouble() ??
          (json['wins'] as num?)?.toDouble() ??
          0.0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
    );
  }
}
