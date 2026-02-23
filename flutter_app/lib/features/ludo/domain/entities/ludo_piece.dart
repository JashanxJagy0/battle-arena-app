class LudoPiece {
  /// Piece index within a player's set: 0–3
  final int id;

  /// -1 = home base, 0–56 = board position, 57 = finished
  final int position;

  final bool isHome;
  final bool isFinished;

  const LudoPiece({
    required this.id,
    required this.position,
    required this.isHome,
    required this.isFinished,
  });
}
