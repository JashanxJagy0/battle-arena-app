import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? freefireUid;
  final String? freefireIgn;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final double winRate;
  final DateTime memberSince;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.freefireUid,
    this.freefireIgn,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.totalGames,
    required this.totalWins,
    required this.totalLosses,
    required this.winRate,
    required this.memberSince,
  });

  @override
  List<Object?> get props => [id, username, email, avatarUrl, level, xp];
}
