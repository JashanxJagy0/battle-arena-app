import '../entities/ludo_game.dart';

abstract class LudoRepository {
  // HTTP
  Future<List<LudoGame>> getMatches();
  Future<LudoGame> createMatch({required String gameMode, required double entryFee});
  Future<LudoGame> joinMatch(String matchId);
  Future<LudoGame> getMatchDetails(String matchId);
  Future<Map<String, dynamic>> rollDice(String matchId);
  Future<void> movePiece({required String matchId, required int pieceId, required int toPos});
  Future<void> sendEmoji({required String matchId, required String emoji});

  // WebSocket
  Future<void> connectToMatch(String matchId);
  void disconnectFromMatch();
  void onGameState(void Function(Map<String, dynamic>) handler);
  void onPlayerJoined(void Function(Map<String, dynamic>) handler);
  void onDiceRolled(void Function(Map<String, dynamic>) handler);
  void onPieceMoved(void Function(Map<String, dynamic>) handler);
  void onGameEnded(void Function(Map<String, dynamic>) handler);
  void onTurnChanged(void Function(Map<String, dynamic>) handler);
  void onEmoji(void Function(Map<String, dynamic>) handler);
  void onConnectionState(void Function(Map<String, dynamic>) handler);
}
