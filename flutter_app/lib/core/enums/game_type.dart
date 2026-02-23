enum GameType {
  ludo('ludo', 'Ludo'),
  freeFire('free_fire', 'Free Fire');

  final String value;
  final String displayName;

  const GameType(this.value, this.displayName);

  factory GameType.fromString(String value) {
    return GameType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GameType.ludo,
    );
  }
}
