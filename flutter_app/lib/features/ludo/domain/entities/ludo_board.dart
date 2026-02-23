class LudoBoard {
  /// Raw board state keyed by cell identifier or player colour.
  final Map<String, dynamic> state;

  const LudoBoard({required this.state});
}
