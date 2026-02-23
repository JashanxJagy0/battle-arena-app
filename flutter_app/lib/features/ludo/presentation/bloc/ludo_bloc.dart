import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/ludo_repository.dart';
import '../../domain/entities/ludo_game.dart';
import '../../engine/ludo_engine.dart';
import '../../engine/move_validator.dart';
import 'ludo_event.dart';
import 'ludo_state.dart';

export 'ludo_event.dart';
export 'ludo_state.dart';

class LudoBloc extends Bloc<LudoEvent, LudoState> {
  final LudoRepository _repository;
  final LudoEngine _engine;

  String? _myUserId;
  String? _currentMatchId;
  int _timerSeconds = 30;
  Timer? _timer;

  LudoBloc({required LudoRepository repository})
      : _repository = repository,
        _engine = LudoEngine(),
        super(const LudoInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<CreateMatch>(_onCreateMatch);
    on<JoinMatch>(_onJoinMatch);
    on<ConnectToMatch>(_onConnectToMatch);
    on<DisconnectFromMatch>(_onDisconnectFromMatch);
    on<MatchJoined>(_onMatchJoined);
    on<PlayerReady>(_onPlayerReady);
    on<GameStarted>(_onGameStarted);
    on<RollDice>(_onRollDice);
    on<DiceRolled>(_onDiceRolled);
    on<ValidMovesReceived>(_onValidMovesReceived);
    on<MovePiece>(_onMovePiece);
    on<PieceMoved>(_onPieceMoved);
    on<PieceHome>(_onPieceHome);
    on<TurnChanged>(_onTurnChanged);
    on<GameEnded>(_onGameEnded);
    on<TimerTick>(_onTimerTick);
    on<OpponentDisconnected>(_onOpponentDisconnected);
    on<SendEmoji>(_onSendEmoji);
    on<EmojiReceived>(_onEmojiReceived);
    on<GameStateUpdated>(_onGameStateUpdated);
  }

  // ── HTTP handlers ──────────────────────────────────────────────────────────

  Future<void> _onLoadMatches(LoadMatches event, Emitter<LudoState> emit) async {
    emit(const LudoLoading());
    try {
      final allMatches = await _repository.getMatches();
      final openMatches = allMatches.where((m) => m.status == 'open').toList();
      final myMatches = _myUserId == null
          ? <LudoGame>[]
          : allMatches
              .where((m) => m.players.any((p) => p.userId == _myUserId))
              .toList();
      emit(LudoLobbyLoaded(openMatches: openMatches, myMatches: myMatches));
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  Future<void> _onCreateMatch(CreateMatch event, Emitter<LudoState> emit) async {
    emit(const LudoLoading());
    try {
      final match = await _repository.createMatch(
        gameMode: event.gameMode,
        entryFee: event.entryFee,
      );
      _currentMatchId = match.matchId;
      emit(LudoMatchmaking(match: match, matchCode: match.matchCode));
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  Future<void> _onJoinMatch(JoinMatch event, Emitter<LudoState> emit) async {
    emit(const LudoLoading());
    try {
      final match = await _repository.joinMatch(event.matchId);
      _currentMatchId = match.matchId;
      if (match.status == 'waiting') {
        emit(LudoWaitingForPlayers(match));
      } else {
        emit(LudoMatchmaking(match: match, matchCode: match.matchCode));
      }
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  // ── WebSocket connection ───────────────────────────────────────────────────

  Future<void> _onConnectToMatch(ConnectToMatch event, Emitter<LudoState> emit) async {
    _myUserId = event.myUserId;
    _currentMatchId = event.matchId;
    _engine.myUserId = event.myUserId;

    try {
      await _repository.connectToMatch(event.matchId);

      _repository.onGameState((data) {
        final game = _cachedGame(data);
        if (game != null) add(GameStateUpdated(game));
      });

      _repository.onPlayerJoined((data) {
        final game = _cachedGame(data);
        if (game != null) add(MatchJoined(game));
      });

      _repository.onDiceRolled((data) {
        final value = data['dice_value'] as int? ?? data['diceValue'] as int? ?? 0;
        final byUser = data['user_id'] as String? ?? data['userId'] as String? ?? '';
        add(DiceRolled(diceValue: value, byUserId: byUser));
      });

      _repository.onPieceMoved((data) {
        add(PieceMoved(
          color: data['color'] as String? ?? '',
          pieceId: data['piece_id'] as int? ?? data['pieceId'] as int? ?? 0,
          fromPos: data['from_pos'] as int? ?? data['fromPos'] as int? ?? 0,
          toPos: data['to_pos'] as int? ?? data['toPos'] as int? ?? 0,
          isKill: data['is_kill'] as bool? ?? data['isKill'] as bool? ?? false,
        ));
      });

      _repository.onGameEnded((data) {
        add(GameEnded(
          winnerId: data['winner_id'] as String? ?? data['winnerId'] as String? ?? '',
          prizeWon: (data['prize_won'] as num? ?? data['prizeWon'] as num? ?? 0).toDouble(),
        ));
      });

      _repository.onTurnChanged((data) {
        final userId = data['user_id'] as String? ?? data['userId'] as String? ?? '';
        add(TurnChanged(userId));
      });

      _repository.onEmoji((data) {
        add(EmojiReceived(
          userId: data['user_id'] as String? ?? data['userId'] as String? ?? '',
          emoji: data['emoji'] as String? ?? '',
        ));
      });

      _repository.onConnectionState((data) {
        final userId = data['user_id'] as String? ?? data['userId'] as String? ?? '';
        final connected = data['connected'] as bool? ?? false;
        if (!connected && userId.isNotEmpty) {
          add(OpponentDisconnected(userId));
        }
      });
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  Future<void> _onDisconnectFromMatch(
      DisconnectFromMatch event, Emitter<LudoState> emit) async {
    _stopTimer();
    _repository.disconnectFromMatch();
    _engine.dispose();
    _currentMatchId = null;
  }

  // ── Game event handlers ────────────────────────────────────────────────────

  Future<void> _onMatchJoined(MatchJoined event, Emitter<LudoState> emit) async {
    emit(LudoWaitingForPlayers(event.game));
  }

  Future<void> _onPlayerReady(PlayerReady event, Emitter<LudoState> emit) async {
    // UI-only acknowledgement; no server call needed here.
  }

  Future<void> _onGameStarted(GameStarted event, Emitter<LudoState> emit) async {
    final myUserId = _myUserId ?? '';
    _engine.processGameState(event.game, myUserId);
    _resetTimer();
    emit(LudoInProgress(
      game: event.game,
      myUserId: myUserId,
      isMyTurn: _engine.isMyTurn,
    ));
  }

  Future<void> _onRollDice(RollDice event, Emitter<LudoState> emit) async {
    final current = state;
    if (current is! LudoInProgress) return;
    emit(LudoDiceRolling(game: current.game, myUserId: current.myUserId));
    try {
      await _repository.rollDice(event.matchId);
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  Future<void> _onDiceRolled(DiceRolled event, Emitter<LudoState> emit) async {
    _engine.processDiceRoll(event.diceValue, event.byUserId);

    final game = _engine.currentGame;
    final myUserId = _myUserId ?? '';

    if (game == null) return;

    if (_engine.isMyTurn) {
      emit(LudoSelectingPiece(
        game: game,
        myUserId: myUserId,
        diceValue: event.diceValue,
        validMoves: List<ValidMove>.from(_engine.validMoves),
      ));
    } else {
      final current = state;
      if (current is LudoInProgress) {
        emit(current.copyWith(lastDiceValue: event.diceValue, validMoves: []));
      } else {
        emit(LudoInProgress(
          game: game,
          myUserId: myUserId,
          isMyTurn: false,
          lastDiceValue: event.diceValue,
        ));
      }
    }
  }

  Future<void> _onValidMovesReceived(
      ValidMovesReceived event, Emitter<LudoState> emit) async {
    final current = state;
    if (current is LudoInProgress) {
      emit(current.copyWith(validMoves: event.moves));
    }
  }

  Future<void> _onMovePiece(MovePiece event, Emitter<LudoState> emit) async {
    final game = _engine.currentGame;
    final myUserId = _myUserId ?? '';
    if (game == null) return;

    emit(LudoAnimatingMove(
      game: game,
      myUserId: myUserId,
      movingColor: _myColor(game, myUserId),
      pieceId: event.pieceId,
      fromPos: _pieceFromPos(game, myUserId, event.pieceId),
      toPos: event.toPos,
    ));

    try {
      await _repository.movePiece(
        matchId: event.matchId,
        pieceId: event.pieceId,
        toPos: event.toPos,
      );
    } catch (e) {
      emit(LudoError(e.toString()));
    }
  }

  Future<void> _onPieceMoved(PieceMoved event, Emitter<LudoState> emit) async {
    _engine.processPieceMove(
      color: event.color,
      pieceId: event.pieceId,
      fromPos: event.fromPos,
      toPos: event.toPos,
      isKill: event.isKill,
    );

    final game = _engine.currentGame;
    final myUserId = _myUserId ?? '';
    if (game == null) return;

    emit(LudoInProgress(
      game: game,
      myUserId: myUserId,
      isMyTurn: _engine.isMyTurn,
      validMoves: List<ValidMove>.from(_engine.validMoves),
    ));
  }

  Future<void> _onPieceHome(PieceHome event, Emitter<LudoState> emit) async {
    // Piece reaching home is reflected in the next game-state update.
  }

  Future<void> _onTurnChanged(TurnChanged event, Emitter<LudoState> emit) async {
    final myUserId = _myUserId ?? '';
    final isMyTurn = event.userId == myUserId;
    _engine.isMyTurn = isMyTurn;

    _resetTimer();

    final current = state;
    if (current is LudoInProgress) {
      emit(current.copyWith(
        isMyTurn: isMyTurn,
        validMoves: [],
        timerSeconds: _timerSeconds,
      ));
    } else {
      final game = _engine.currentGame;
      if (game != null) {
        emit(LudoInProgress(
          game: game,
          myUserId: myUserId,
          isMyTurn: isMyTurn,
          timerSeconds: _timerSeconds,
        ));
      }
    }
  }

  Future<void> _onGameEnded(GameEnded event, Emitter<LudoState> emit) async {
    _stopTimer();
    final game = _engine.currentGame;
    final myUserId = _myUserId ?? '';
    if (game == null) return;
    emit(LudoGameOver(
      game: game,
      winnerId: event.winnerId,
      prizeWon: event.prizeWon,
      myUserId: myUserId,
    ));
  }

  Future<void> _onTimerTick(TimerTick event, Emitter<LudoState> emit) async {
    final current = state;
    if (current is LudoInProgress) {
      emit(current.copyWith(timerSeconds: event.secondsLeft));
    }
  }

  Future<void> _onOpponentDisconnected(
      OpponentDisconnected event, Emitter<LudoState> emit) async {
    final current = state;
    if (current is LudoInProgress) {
      emit(current.copyWith(isConnected: false));
    }
  }

  Future<void> _onSendEmoji(SendEmoji event, Emitter<LudoState> emit) async {
    try {
      await _repository.sendEmoji(matchId: event.matchId, emoji: event.emoji);
    } catch (_) {}
  }

  Future<void> _onEmojiReceived(EmojiReceived event, Emitter<LudoState> emit) async {
    final current = state;
    if (current is LudoInProgress) {
      emit(current.copyWith(
        lastEmoji: event.emoji,
        lastEmojiUserId: event.userId,
      ));
    }
  }

  Future<void> _onGameStateUpdated(
      GameStateUpdated event, Emitter<LudoState> emit) async {
    final myUserId = _myUserId ?? '';
    _engine.processGameState(event.game, myUserId);

    final status = event.game.status;

    if (status == 'finished') {
      final winnerId = event.game.winnerId ?? '';
      emit(LudoGameOver(
        game: event.game,
        winnerId: winnerId,
        prizeWon: 0,
        myUserId: myUserId,
      ));
      return;
    }

    if (status == 'in_progress') {
      final current = state;
      if (current is LudoInProgress) {
        emit(current.copyWith(
          game: event.game,
          isMyTurn: _engine.isMyTurn,
          validMoves: List<ValidMove>.from(_engine.validMoves),
        ));
      } else {
        emit(LudoInProgress(
          game: event.game,
          myUserId: myUserId,
          isMyTurn: _engine.isMyTurn,
        ));
      }
      return;
    }

    if (status == 'waiting') {
      emit(LudoWaitingForPlayers(event.game));
      return;
    }

    emit(LudoMatchmaking(match: event.game, matchCode: event.game.matchCode));
  }

  // ── Timer helpers ──────────────────────────────────────────────────────────

  void _resetTimer() {
    _stopTimer();
    _timerSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerSeconds > 0) {
        _timerSeconds--;
        add(TimerTick(_timerSeconds));
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Utility helpers ────────────────────────────────────────────────────────

  /// Returns the engine's cached [LudoGame] when a WebSocket push arrives.
  ///
  /// Full deserialization of [data] into a [LudoGame] requires a
  /// `LudoGame.fromJson` factory that is not yet defined in the domain layer.
  /// Until that factory exists, the engine's cached snapshot (kept up-to-date
  /// via [GameStateUpdated] events) is returned instead.
  LudoGame? _cachedGame(Map<String, dynamic> data) {
    return _engine.currentGame;
  }

  String _myColor(LudoGame game, String myUserId) {
    try {
      return game.players.firstWhere((p) => p.userId == myUserId).color;
    } catch (_) {
      return '';
    }
  }

  int _pieceFromPos(LudoGame game, String myUserId, int pieceId) {
    try {
      final player = game.players.firstWhere((p) => p.userId == myUserId);
      return player.pieces[pieceId];
    } catch (_) {
      return -1;
    }
  }

  @override
  Future<void> close() {
    _stopTimer();
    _engine.dispose();
    return super.close();
  }
}
