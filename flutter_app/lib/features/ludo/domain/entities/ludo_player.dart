class LudoPlayer {
  final String userId;
  final String username;
  final String? avatar;

  /// Color token: 'red' | 'green' | 'yellow' | 'blue'
  final String color;

  /// Positions for each piece: -1 = home base, 0-51 = shared path,
  /// 52-71 = home columns (per color), 72 = finished/center home
  final List<int> pieces;

  /// Number of pieces that have reached the final home cell
  final int piecesHome;

  final bool isEliminated;

  const LudoPlayer({
    required this.userId,
    required this.username,
    this.avatar,
    required this.color,
    required this.pieces,
    required this.piecesHome,
    required this.isEliminated,
  });
}
