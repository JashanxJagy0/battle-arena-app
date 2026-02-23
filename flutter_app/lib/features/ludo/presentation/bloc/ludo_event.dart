import 'package:equatable/equatable.dart';

import '../../domain/entities/ludo_game.dart';
import '../../engine/move_validator.dart';

abstract class LudoEvent extends Equatable {
  const LudoEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatches extends LudoEvent {
  const LoadMatches();
}

class CreateMatch extends LudoEvent {
  final String gameMode;
  final double entryFee;

  const CreateMatch({required this.gameMode, required this.entryFee});

  @override
  List<Object?> get props => [gameMode, entryFee];
}

class JoinMatch extends LudoEvent {
  final String matchId;

  const JoinMatch(this.matchId);

  @override
  List<Object?> get props => [matchId];
}

class MatchJoined extends LudoEvent {
  final LudoGame game;

  const MatchJoined(this.game);

  @override
  List<Object?> get props => [game];
}

class PlayerReady extends LudoEvent {
  const PlayerReady();
}

class GameStarted extends LudoEvent {
  final LudoGame game;

  const GameStarted(this.game);

  @override
  List<Object?> get props => [game];
}

class RollDice extends LudoEvent {
  final String matchId;

  const RollDice(this.matchId);

  @override
  List<Object?> get props => [matchId];
}

class DiceRolled extends LudoEvent {
  final int diceValue;
  final String byUserId;

  const DiceRolled({required this.diceValue, required this.byUserId});

  @override
  List<Object?> get props => [diceValue, byUserId];
}

class ValidMovesReceived extends LudoEvent {
  final List<ValidMove> moves;

  const ValidMovesReceived(this.moves);

  @override
  List<Object?> get props => [moves];
}

class MovePiece extends LudoEvent {
  final String matchId;
  final int pieceId;
  final int toPos;

  const MovePiece({
    required this.matchId,
    required this.pieceId,
    required this.toPos,
  });

  @override
  List<Object?> get props => [matchId, pieceId, toPos];
}

class PieceMoved extends LudoEvent {
  final String color;
  final int pieceId;
  final int fromPos;
  final int toPos;
  final bool isKill;

  const PieceMoved({
    required this.color,
    required this.pieceId,
    required this.fromPos,
    required this.toPos,
    required this.isKill,
  });

  @override
  List<Object?> get props => [color, pieceId, fromPos, toPos, isKill];
}

class PieceHome extends LudoEvent {
  final String color;
  final int pieceId;

  const PieceHome({required this.color, required this.pieceId});

  @override
  List<Object?> get props => [color, pieceId];
}

class TurnChanged extends LudoEvent {
  final String userId;

  const TurnChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GameEnded extends LudoEvent {
  final String winnerId;
  final double prizeWon;

  const GameEnded({required this.winnerId, required this.prizeWon});

  @override
  List<Object?> get props => [winnerId, prizeWon];
}

class TimerTick extends LudoEvent {
  final int secondsLeft;

  const TimerTick(this.secondsLeft);

  @override
  List<Object?> get props => [secondsLeft];
}

class OpponentDisconnected extends LudoEvent {
  final String userId;

  const OpponentDisconnected(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SendEmoji extends LudoEvent {
  final String matchId;
  final String emoji;

  const SendEmoji({required this.matchId, required this.emoji});

  @override
  List<Object?> get props => [matchId, emoji];
}

class EmojiReceived extends LudoEvent {
  final String userId;
  final String emoji;

  const EmojiReceived({required this.userId, required this.emoji});

  @override
  List<Object?> get props => [userId, emoji];
}

class GameStateUpdated extends LudoEvent {
  final LudoGame game;

  const GameStateUpdated(this.game);

  @override
  List<Object?> get props => [game];
}

class ConnectToMatch extends LudoEvent {
  final String matchId;
  final String myUserId;

  const ConnectToMatch({required this.matchId, required this.myUserId});

  @override
  List<Object?> get props => [matchId, myUserId];
}

class DisconnectFromMatch extends LudoEvent {
  const DisconnectFromMatch();
}
