import 'ludo_player.dart';

class LudoGame {
  final String matchId;
  final String matchCode;
  final String gameMode;
  final double entryFee;
  final double prizePool;
  final String status;
  final List<LudoPlayer> players;
  final Map<String, dynamic> boardState;
  final String? turnUserId;
  final String? winnerId;

  const LudoGame({
    required this.matchId,
    required this.matchCode,
    required this.gameMode,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.players,
    required this.boardState,
    this.turnUserId,
    this.winnerId,
  });
}
