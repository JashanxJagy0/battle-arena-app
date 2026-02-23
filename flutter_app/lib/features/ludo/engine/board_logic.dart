import 'dart:ui';

/// Encodes all coordinate mappings for the standard 15×15 Ludo board.
///
/// Logical position scheme (matching LudoPlayer.pieces values):
///   -1          → piece is in home base
///   0 – 51      → shared clockwise path (52 cells)
///   52 – 56     → Red's home column   (5 cells toward centre)
///   57 – 61     → Green's home column
///   62 – 66     → Yellow's home column
///   67 – 71     → Blue's home column
///   72          → centre home cell
class BoardLogic {
  static const int boardSize = 15;

  // ---------------------------------------------------------------------------
  // Shared path (positions 0-51), ordered clockwise starting from Red's exit.
  // Each Offset is (row, col).
  // ---------------------------------------------------------------------------
  static const List<Offset> _boardPath = [
    // Red exit column going up-left → top boundary (0-5)
    Offset(6, 1),
    Offset(5, 1),
    Offset(4, 1),
    Offset(3, 1),
    Offset(2, 1),
    Offset(1, 1),
    // top-left corner row going right (6-7)
    Offset(0, 1),
    Offset(0, 2),
    // top boundary going right until Green exit (8-12)
    Offset(0, 3),
    Offset(0, 4),
    Offset(0, 5),
    Offset(0, 6),
    Offset(1, 6),
    // Green entry column going down (13 = Green start)
    Offset(1, 8),
    Offset(2, 8),
    Offset(3, 8),
    Offset(4, 8),
    Offset(5, 8),
    Offset(6, 8),
    // right section top row going right (19-24)
    Offset(6, 9),
    Offset(6, 10),
    Offset(6, 11),
    Offset(6, 12),
    Offset(6, 13),
    Offset(6, 14),
    // top-right corner cell (25)
    Offset(8, 14),
    // Yellow exit (26 = Yellow start)
    Offset(8, 13),
    Offset(8, 12),
    Offset(8, 11),
    Offset(8, 10),
    Offset(8, 9),
    // bottom-right section going down (30-32)
    Offset(9, 8),
    Offset(10, 8),
    Offset(11, 8),
    // bottom-right corner (33-38)
    Offset(12, 8),
    Offset(13, 8),
    Offset(14, 8),
    Offset(14, 7),
    Offset(14, 6),
    // Blue entry column going up (39 = Blue start)
    Offset(13, 6),
    Offset(12, 6),
    Offset(11, 6),
    Offset(10, 6),
    Offset(9, 6),
    // bottom section going left (43-45)
    Offset(8, 6),
    Offset(8, 5),
    Offset(8, 4),
    Offset(8, 3),
    Offset(8, 2),
    // bottom-left corner going up (48-51)
    Offset(8, 1),
    Offset(7, 0),
    Offset(6, 0),
  ];

  // ---------------------------------------------------------------------------
  // Home columns (5 cells each, ordered from entry toward centre)
  // ---------------------------------------------------------------------------
  static const Map<String, List<Offset>> _homeColumns = {
    'red': [
      Offset(6, 2),
      Offset(6, 3),
      Offset(6, 4),
      Offset(6, 5),
      Offset(6, 6),
    ],
    'green': [
      Offset(1, 7),
      Offset(2, 7),
      Offset(3, 7),
      Offset(4, 7),
      Offset(5, 7),
    ],
    'yellow': [
      Offset(7, 13),
      Offset(7, 12),
      Offset(7, 11),
      Offset(7, 10),
      Offset(7, 9),
    ],
    'blue': [
      Offset(13, 7),
      Offset(12, 7),
      Offset(11, 7),
      Offset(10, 7),
      Offset(9, 7),
    ],
  };

  // Starting cell on the shared path when leaving home base.
  static const Map<String, Offset> _homeBaseStarts = {
    'red': Offset(6, 1),    // position 0
    'green': Offset(1, 8),  // position 13
    'yellow': Offset(8, 13), // position 26
    'blue': Offset(13, 6),  // position 39
  };

  // 4 home base piece positions (the coloured quadrant cells).
  static const Map<String, List<Offset>> _homeBasePositions = {
    'red': [
      Offset(1, 1), Offset(1, 3),
      Offset(3, 1), Offset(3, 3),
    ],
    'green': [
      Offset(1, 11), Offset(1, 13),
      Offset(3, 11), Offset(3, 13),
    ],
    'yellow': [
      Offset(11, 11), Offset(11, 13),
      Offset(13, 11), Offset(13, 13),
    ],
    'blue': [
      Offset(11, 1), Offset(11, 3),
      Offset(13, 1), Offset(13, 3),
    ],
  };

  // Shared path index where each colour enters the board.
  static const Map<String, int> _startingPositions = {
    'red': 0,
    'green': 13,
    'yellow': 26,
    'blue': 39,
  };

  // Shared path positions that are safe zones (stars + colour starts).
  static const Set<int> _safeZones = {0, 8, 13, 21, 26, 34, 39, 47};

  // Home column logical position offsets per colour.
  static const Map<String, int> _homeColOffset = {
    'red': 52,
    'green': 57,
    'yellow': 62,
    'blue': 67,
  };

  static const int _centrePosition = 72;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the 52 ordered (row, col) positions of the shared path.
  List<Offset> getBoardPath() => List.unmodifiable(_boardPath);

  /// Returns the 5 (row, col) positions of [color]'s home column.
  List<Offset> getHomeColumn(String color) =>
      List.unmodifiable(_homeColumns[color.toLowerCase()]!);

  /// Returns the starting cell (row, col) on the shared path when a piece
  /// of [color] leaves its home base.
  Offset getHomeBaseStart(String color) =>
      _homeBaseStarts[color.toLowerCase()]!;

  /// Returns the 4 home-base (row, col) positions for [color]'s pieces.
  List<Offset> getHomeBasePositions(String color) =>
      List.unmodifiable(_homeBasePositions[color.toLowerCase()]!);

  /// Returns the shared path index (0-51) where [color] enters the path.
  int getStartingPosition(String color) =>
      _startingPositions[color.toLowerCase()]!;

  /// Returns true if [position] (0-51) is a safe zone on the shared path.
  bool isSafeZone(int position) => _safeZones.contains(position);

  /// Converts a logical piece position to a grid (row, col) Offset.
  ///
  /// [position] follows the LudoPlayer.pieces scheme:
  ///   -1        → first unoccupied home base slot (col 0)
  ///   0–51      → shared path
  ///   52–71     → home column (colour-dependent)
  ///   72        → centre home
  Offset logicalToGrid(int position, String color) {
    final c = color.toLowerCase();

    if (position == -1) {
      return _homeBasePositions[c]![0];
    }

    if (position >= 0 && position <= 51) {
      return _boardPath[position];
    }

    final offset = _homeColOffset[c]!;
    if (position >= offset && position < offset + 5) {
      return _homeColumns[c]![position - offset];
    }

    if (position == _centrePosition) {
      return const Offset(7, 7);
    }

    throw ArgumentError('Unknown logical position $position for color $color');
  }
}
