import 'ludo_player_model.dart';
import '../../domain/entities/ludo_game.dart';

class LudoGameModel extends LudoGame {
  const LudoGameModel({
    required super.matchId,
    required super.matchCode,
    required super.gameMode,
    required super.entryFee,
    required super.prizePool,
    required super.status,
    required super.players,
    required super.boardState,
    super.turnUserId,
    super.winnerId,
  });

  factory LudoGameModel.fromJson(Map<String, dynamic> json) {
    return LudoGameModel(
      matchId: json['matchId'] as String? ?? json['_id'] as String,
      matchCode: json['matchCode'] as String,
      gameMode: json['gameMode'] as String,
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prizePool'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => LudoPlayerModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      boardState: Map<String, dynamic>.from(
        json['boardState'] as Map<dynamic, dynamic>? ?? {},
      ),
      turnUserId: json['turnUserId'] as String?,
      winnerId: json['winnerId'] as String?,
    );
  }
}
