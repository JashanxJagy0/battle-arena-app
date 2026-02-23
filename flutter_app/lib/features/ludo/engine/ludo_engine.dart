import '../domain/entities/ludo_game.dart';
import '../domain/entities/ludo_player.dart';
import 'board_logic.dart';
import 'dice_engine.dart';
import 'move_validator.dart';
import 'piece_controller.dart';

/// Main game controller for the Ludo engine layer.
///
/// Processes server state updates and coordinates [BoardLogic],
/// [MoveValidator], [PieceController], and [DiceEngine].
class LudoEngine {
  final BoardLogic boardLogic;
  final MoveValidator moveValidator;
  final PieceController pieceController;
  final DiceEngine diceEngine;

  // ── Display state ──────────────────────────────────────────────────────────

  /// The most recent full game state received from the server.
  LudoGame? currentGame;

  /// Valid moves for the local player after the current dice roll.
  List<ValidMove> validMoves = [];

  /// Whether it is currently the local player's turn.
  bool isMyTurn = false;

  /// The local player's user ID, set when joining the game.
  String? myUserId;

  LudoEngine()
      : boardLogic = BoardLogic(),
        moveValidator = MoveValidator(),
        pieceController = PieceController(),
        diceEngine = DiceEngine();

  // ── Server event handlers ──────────────────────────────────────────────────

  /// Processes a full game-state snapshot from the server.
  ///
  /// Updates [currentGame], [isMyTurn], and clears stale valid-move data.
  void processGameState(LudoGame game, String userId) {
    myUserId = userId;
    currentGame = game;
    isMyTurn = game.turnUserId == userId;
    validMoves = [];
  }

  /// Processes a dice-roll event from the server.
  ///
  /// Starts the dice animation and, if it is the local player's turn,
  /// immediately computes valid moves so the UI can respond without waiting
  /// for the animation to finish.
  void processDiceRoll(int diceValue, String userId) {
    diceEngine.startRoll(diceValue);

    if (currentGame == null) return;

    isMyTurn = userId == myUserId;

    if (isMyTurn) {
      final me = _findPlayer(myUserId!);
      if (me != null) {
        validMoves = computeValidMoves(me.color, me.pieces, diceValue);
      }
    } else {
      validMoves = [];
    }
  }

  /// Processes a piece-move event from the server and updates animation state.
  void processPieceMove({
    required String color,
    required int pieceId,
    required int fromPos,
    required int toPos,
    required bool isKill,
  }) {
    final pieceKey = '${color}_$pieceId';
    pieceController.setMoving(pieceKey);

    if (isKill) {
      // The killed piece belongs to a different player; mark it killed.
      // The caller is responsible for providing the opponent's pieceKey if needed.
      // Here we mark the moving piece as the aggressor and the UI handles the victim.
    }

    // Clear the valid move that was just executed.
    validMoves.removeWhere((m) => m.pieceId == pieceId);
  }

  // ── Move computation ───────────────────────────────────────────────────────

  /// Returns valid moves for [color]'s pieces given [diceValue] and current
  /// [positions] (using LudoPlayer.pieces encoding).
  List<ValidMove> computeValidMoves(
    String color,
    List<int> positions,
    int diceValue,
  ) {
    return moveValidator.getValidMoves(
      color: color,
      piecePositions: positions,
      diceValue: diceValue,
      startingPosition: boardLogic.getStartingPosition(color),
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Releases resources and resets all sub-components.
  void dispose() {
    pieceController.reset();
    diceEngine.reset();
    currentGame = null;
    validMoves = [];
    isMyTurn = false;
    myUserId = null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  LudoPlayer? _findPlayer(String userId) {
    if (currentGame == null) return null;
    try {
      return currentGame!.players.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }
}
