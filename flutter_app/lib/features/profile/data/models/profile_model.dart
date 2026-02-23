import '../../domain/entities/user_profile.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.id,
    required super.username,
    required super.email,
    super.avatarUrl,
    super.freefireUid,
    super.freefireIgn,
    required super.level,
    required super.xp,
    required super.xpToNextLevel,
    required super.totalGames,
    required super.totalWins,
    required super.totalLosses,
    required super.winRate,
    required super.memberSince,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final games = stats['totalGames'] as int? ?? json['totalGames'] as int? ?? 0;
    final wins = stats['totalWins'] as int? ?? json['totalWins'] as int? ?? 0;
    final losses = stats['totalLosses'] as int? ?? json['totalLosses'] as int? ?? 0;
    final winRate = games > 0 ? (wins / games * 100) : 0.0;

    return ProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      freefireUid: json['freefireUid'] as String?,
      freefireIgn: json['freefireIgn'] as String? ?? json['ign'] as String?,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 1000,
      totalGames: games,
      totalWins: wins,
      totalLosses: losses,
      winRate: winRate.toDouble(),
      memberSince: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
