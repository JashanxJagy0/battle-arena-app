/// Visual / animation state of a single Ludo piece.
enum PieceAnimationState { idle, moving, killed, celebrating }

/// Manages the [PieceAnimationState] for every piece on the board.
///
/// Piece keys follow the convention `'<color>_<index>'`, e.g. `'red_0'`.
class PieceController {
  final Map<String, PieceAnimationState> _states = {};

  /// Returns the current animation state for [pieceKey].
  /// Defaults to [PieceAnimationState.idle] if the piece has not been seen before.
  PieceAnimationState getState(String pieceKey) =>
      _states[pieceKey] ?? PieceAnimationState.idle;

  /// Marks [pieceKey] as currently moving along the board.
  void setMoving(String pieceKey) =>
      _states[pieceKey] = PieceAnimationState.moving;

  /// Marks [pieceKey] as killed (sent back to home base).
  void setKilled(String pieceKey) =>
      _states[pieceKey] = PieceAnimationState.killed;

  /// Marks [pieceKey] as celebrating (reached centre home).
  void setCelebrating(String pieceKey) =>
      _states[pieceKey] = PieceAnimationState.celebrating;

  /// Returns [pieceKey] to the idle state.
  void setIdle(String pieceKey) =>
      _states[pieceKey] = PieceAnimationState.idle;

  /// Resets all pieces to [PieceAnimationState.idle].
  void reset() => _states.clear();
}
