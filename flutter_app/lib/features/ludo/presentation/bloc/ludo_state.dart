import 'package:equatable/equatable.dart';

import '../../domain/entities/ludo_game.dart';
import '../../engine/move_validator.dart';

abstract class LudoState extends Equatable {
  const LudoState();

  @override
  List<Object?> get props => [];
}

class LudoInitial extends LudoState {
  const LudoInitial();
}

class LudoLoading extends LudoState {
  const LudoLoading();
}

class LudoError extends LudoState {
  final String message;

  const LudoError(this.message);

  @override
  List<Object?> get props => [message];
}

class LudoLobbyLoaded extends LudoState {
  final List<LudoGame> openMatches;
  final List<LudoGame> myMatches;

  const LudoLobbyLoaded({required this.openMatches, required this.myMatches});

  @override
  List<Object?> get props => [openMatches, myMatches];
}

class LudoMatchmaking extends LudoState {
  final LudoGame match;
  final String matchCode;

  const LudoMatchmaking({required this.match, required this.matchCode});

  @override
  List<Object?> get props => [match, matchCode];
}

class LudoWaitingForPlayers extends LudoState {
  final LudoGame match;

  const LudoWaitingForPlayers(this.match);

  @override
  List<Object?> get props => [match];
}

class LudoInProgress extends LudoState {
  final LudoGame game;
  final String myUserId;
  final bool isMyTurn;
  final int? lastDiceValue;
  final List<ValidMove> validMoves;
  final String? lastEmoji;
  final String? lastEmojiUserId;
  final int timerSeconds;
  final bool isConnected;

  const LudoInProgress({
    required this.game,
    required this.myUserId,
    required this.isMyTurn,
    this.lastDiceValue,
    this.validMoves = const [],
    this.lastEmoji,
    this.lastEmojiUserId,
    this.timerSeconds = 30,
    this.isConnected = true,
  });

  @override
  List<Object?> get props => [
        game,
        myUserId,
        isMyTurn,
        lastDiceValue,
        validMoves,
        lastEmoji,
        lastEmojiUserId,
        timerSeconds,
        isConnected,
      ];

  // Sentinel used by copyWith to distinguish "pass null explicitly" from "keep existing value".
  static const Object _absent = Object();

  LudoInProgress copyWith({
    LudoGame? game,
    String? myUserId,
    bool? isMyTurn,
    // Use the _absent sentinel to clear nullable fields:
    //   copyWith(lastDiceValue: null)           → keeps existing value
    //   copyWith(lastDiceValue: _absent)        → sets to null
    // Callers inside this file pass the sentinel via the named helpers below.
    Object? lastDiceValue = _absent,
    List<ValidMove>? validMoves,
    Object? lastEmoji = _absent,
    Object? lastEmojiUserId = _absent,
    int? timerSeconds,
    bool? isConnected,
  }) {
    return LudoInProgress(
      game: game ?? this.game,
      myUserId: myUserId ?? this.myUserId,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      lastDiceValue: identical(lastDiceValue, _absent)
          ? this.lastDiceValue
          : lastDiceValue as int?,
      validMoves: validMoves ?? this.validMoves,
      lastEmoji: identical(lastEmoji, _absent) ? this.lastEmoji : lastEmoji as String?,
      lastEmojiUserId: identical(lastEmojiUserId, _absent)
          ? this.lastEmojiUserId
          : lastEmojiUserId as String?,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Returns a copy with [lastDiceValue] explicitly cleared to null.
  LudoInProgress clearDiceValue() => copyWith(lastDiceValue: _absent);

  /// Returns a copy with emoji fields explicitly cleared to null.
  LudoInProgress clearEmoji() => copyWith(lastEmoji: _absent, lastEmojiUserId: _absent);
}

class LudoMyTurn extends LudoState {
  final LudoGame game;
  final String myUserId;

  const LudoMyTurn({required this.game, required this.myUserId});

  @override
  List<Object?> get props => [game, myUserId];
}

class LudoDiceRolling extends LudoState {
  final LudoGame game;
  final String myUserId;

  const LudoDiceRolling({required this.game, required this.myUserId});

  @override
  List<Object?> get props => [game, myUserId];
}

class LudoSelectingPiece extends LudoState {
  final LudoGame game;
  final String myUserId;
  final int diceValue;
  final List<ValidMove> validMoves;

  const LudoSelectingPiece({
    required this.game,
    required this.myUserId,
    required this.diceValue,
    required this.validMoves,
  });

  @override
  List<Object?> get props => [game, myUserId, diceValue, validMoves];
}

class LudoAnimatingMove extends LudoState {
  final LudoGame game;
  final String myUserId;
  final String movingColor;
  final int pieceId;
  final int fromPos;
  final int toPos;

  const LudoAnimatingMove({
    required this.game,
    required this.myUserId,
    required this.movingColor,
    required this.pieceId,
    required this.fromPos,
    required this.toPos,
  });

  @override
  List<Object?> get props => [game, myUserId, movingColor, pieceId, fromPos, toPos];
}

class LudoGameOver extends LudoState {
  final LudoGame game;
  final String winnerId;
  final double prizeWon;
  final String myUserId;

  const LudoGameOver({
    required this.game,
    required this.winnerId,
    required this.prizeWon,
    required this.myUserId,
  });

  @override
  List<Object?> get props => [game, winnerId, prizeWon, myUserId];
}
