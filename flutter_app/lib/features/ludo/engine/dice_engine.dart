/// Lifecycle state of the dice widget.
enum DiceState { idle, rolling, result }

/// Controls the dice animation lifecycle.
///
/// The server is the source of truth for the dice value. Call [startRoll] as
/// soon as the server result is received; the UI drives the animation and calls
/// [onAnimationComplete] when the visual roll has finished.
class DiceEngine {
  DiceState state = DiceState.idle;

  /// The face currently shown during a rolling animation (may change rapidly).
  int currentFace = 1;

  /// The authoritative face value received from the server.
  int? resultFace;

  /// Called when the server sends a dice result.
  /// Begins the rolling animation that will land on [serverResult].
  void startRoll(int serverResult) {
    assert(serverResult >= 1 && serverResult <= 6,
        'serverResult must be between 1 and 6');
    resultFace = serverResult;
    state = DiceState.rolling;
  }

  /// Called by the animation layer once the visual roll has finished.
  /// Locks the face to [resultFace] and transitions to [DiceState.result].
  void onAnimationComplete() {
    if (resultFace != null) {
      currentFace = resultFace!;
    }
    state = DiceState.result;
  }

  /// Resets the dice to its idle state, ready for the next roll.
  void reset() {
    state = DiceState.idle;
    resultFace = null;
  }

  /// True while the dice is animating.
  bool get isRolling => state == DiceState.rolling;

  /// True once the animation has settled on the server result.
  bool get hasResult => state == DiceState.result;
}
