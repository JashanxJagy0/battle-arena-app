enum TournamentStatus {
  upcoming('upcoming', 'Upcoming'),
  registrationOpen('registration_open', 'Registration Open'),
  registrationClosed('registration_closed', 'Registration Closed'),
  ongoing('ongoing', 'Ongoing'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const TournamentStatus(this.value, this.displayName);

  factory TournamentStatus.fromString(String value) {
    return TournamentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TournamentStatus.upcoming,
    );
  }
}
