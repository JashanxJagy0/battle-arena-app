import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/ludo_game.dart';
import '../../domain/repositories/ludo_repository.dart';
import '../models/ludo_game_model.dart';

class LudoRepositoryImpl implements LudoRepository {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;

  LudoRepositoryImpl({
    required ApiClient apiClient,
    required WebSocketClient wsClient,
  })  : _apiClient = apiClient,
        _wsClient = wsClient;

  // ── HTTP ────────────────────────────────────────────────────────────────────

  @override
  Future<List<LudoGame>> getMatches() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.ludoMatches);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => LudoGameModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LudoGame> createMatch({
    required String gameMode,
    required double entryFee,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.ludoMatches,
      data: {'gameMode': gameMode, 'entryFee': entryFee},
    );
    return LudoGameModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LudoGame> joinMatch(String matchId) async {
    final path = '${ApiEndpoints.ludoMatches}/$matchId/join';
    final response = await _apiClient.post<dynamic>(path);
    return LudoGameModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LudoGame> getMatchDetails(String matchId) async {
    final path = ApiEndpoints.ludoMatchDetails.replaceFirst(':matchId', matchId);
    final response = await _apiClient.get<dynamic>(path);
    return LudoGameModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> rollDice(String matchId) async {
    final path = '${ApiEndpoints.ludoMatches}/$matchId/roll';
    final response = await _apiClient.post<dynamic>(path);
    return Map<String, dynamic>.from(response.data as Map<dynamic, dynamic>);
  }

  @override
  Future<void> movePiece({
    required String matchId,
    required int pieceId,
    required int toPos,
  }) async {
    final path = '${ApiEndpoints.ludoMatches}/$matchId/move';
    await _apiClient.post<dynamic>(
      path,
      data: {'pieceId': pieceId, 'toPos': toPos},
    );
  }

  @override
  Future<void> sendEmoji({
    required String matchId,
    required String emoji,
  }) async {
    final path = '${ApiEndpoints.ludoMatches}/$matchId/emoji';
    await _apiClient.post<dynamic>(path, data: {'emoji': emoji});
  }

  // ── WebSocket ───────────────────────────────────────────────────────────────

  @override
  Future<void> connectToMatch(String matchId) async {
    await _wsClient.connect(ApiEndpoints.wsLudoNamespace);
    _wsClient.emit(ApiEndpoints.wsLudoNamespace, 'joinMatch', {'matchId': matchId});
  }

  @override
  void disconnectFromMatch() {
    _wsClient.disconnect(ApiEndpoints.wsLudoNamespace);
  }

  @override
  void onGameState(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'gameState', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onPlayerJoined(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'playerJoined', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onDiceRolled(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'diceRolled', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onPieceMoved(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'pieceMoved', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onGameEnded(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'gameEnded', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onTurnChanged(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'turnChanged', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onEmoji(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'emoji', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });

  @override
  void onConnectionState(void Function(Map<String, dynamic>) handler) =>
      _wsClient.on(ApiEndpoints.wsLudoNamespace, 'connectionState', (data) {
        handler(Map<String, dynamic>.from(data as Map<dynamic, dynamic>));
      });
}
