/// Represents a single valid move a player can make.
class ValidMove {
  final int pieceId;
  final int fromPos;
  final int toPos;
  final bool isKill;

  const ValidMove({
    required this.pieceId,
    required this.fromPos,
    required this.toPos,
    required this.isKill,
  });

  @override
  String toString() =>
      'ValidMove(pieceId: $pieceId, from: $fromPos, to: $toPos, isKill: $isKill)';
}

/// Client-side move prediction for UI responsiveness.
///
/// Mirrors the server's move-validation logic so the UI can highlight valid
/// pieces immediately after a dice roll, without waiting for a round-trip.
class MoveValidator {
  // Home column logical position offsets per colour (matches BoardLogic).
  static const Map<String, int> _homeColOffset = {
    'red': 52,
    'green': 57,
    'yellow': 62,
    'blue': 67,
  };

  // Length of the shared path.
  static const int _sharedPathLength = 52;

  // Number of steps in each home column (excluding centre cell).
  static const int _homeColLength = 5;

  // Logical position for the centre / finished cell.
  static const int _centrePosition = 72;

  // Shared path index at which each colour enters the home column.
  static const Map<String, int> _homeColumnEntry = {
    'red': 51,    // after position 51 → home col
    'green': 12,
    'yellow': 25,
    'blue': 38,
  };

  /// Returns all valid moves for [color]'s pieces given [diceValue].
  ///
  /// [piecePositions] has one entry per piece using the LudoPlayer.pieces
  /// scheme: -1 = home base, 0-51 = shared path, 52+ = home column, 72 = done.
  List<ValidMove> getValidMoves({
    required String color,
    required List<int> piecePositions,
    required int diceValue,
    required int startingPosition,
  }) {
    final moves = <ValidMove>[];

    for (int i = 0; i < piecePositions.length; i++) {
      final pos = piecePositions[i];

      // Already finished – skip.
      if (pos == _centrePosition) continue;

      if (pos == -1) {
        // Piece is in home base; can only leave on a 6.
        if (canLeaveBase(diceValue)) {
          moves.add(ValidMove(
            pieceId: i,
            fromPos: pos,
            toPos: startingPosition,
            isKill: false, // kill check handled below via calculateNewPosition
          ));
        }
      } else {
        final newPos = calculateNewPosition(pos, diceValue, color);
        if (newPos != pos) {
          moves.add(ValidMove(
            pieceId: i,
            fromPos: pos,
            toPos: newPos,
            isKill: false, // caller should cross-reference opponent positions
          ));
        }
      }
    }

    return moves;
  }

  /// A piece can leave home base only when the dice shows 6.
  bool canLeaveBase(int diceValue) => diceValue == 6;

  /// Calculates the new logical position after moving [diceValue] steps from
  /// [currentPos] for [color].
  ///
  /// Returns [currentPos] unchanged if the move would overshoot the centre.
  int calculateNewPosition(int currentPos, int diceValue, String color) {
    final c = color.toLowerCase();
    final homeOffset = _homeColOffset[c]!;
    final entryPoint = _homeColumnEntry[c]!;

    // ── Already in home column ──────────────────────────────────────────────
    if (currentPos >= homeOffset && currentPos < homeOffset + _homeColLength) {
      final colIndex = currentPos - homeOffset; // 0-4
      final newColIndex = colIndex + diceValue;
      if (newColIndex == _homeColLength) {
        return _centrePosition; // lands exactly on centre
      } else if (newColIndex < _homeColLength) {
        return homeOffset + newColIndex;
      } else {
        return currentPos; // overshoot – invalid
      }
    }

    // ── On shared path ──────────────────────────────────────────────────────
    int steps = diceValue;
    int pos = currentPos;

    while (steps > 0) {
      // Check if this step crosses into the home column entry.
      if (pos == entryPoint) {
        // Next step goes into home column position 0.
        steps--;
        final colIndex = steps; // remaining steps go deeper into col
        if (colIndex == _homeColLength) {
          return _centrePosition;
        } else if (colIndex < _homeColLength) {
          return homeOffset + colIndex;
        } else {
          return currentPos; // overshoot
        }
      }

      pos = (pos + 1) % _sharedPathLength;
      steps--;
    }

    return pos;
  }
}
