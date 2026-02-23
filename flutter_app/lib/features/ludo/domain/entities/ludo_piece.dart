class LudoPiece {
  /// Piece index within a player's set: 0–3
  final int id;

  /// -1 = home base, 0-51 = shared path, 52-71 = home columns (per color),
  /// 72 = finished/center home
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
