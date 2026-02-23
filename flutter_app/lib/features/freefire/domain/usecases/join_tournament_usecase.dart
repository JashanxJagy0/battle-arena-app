import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class JoinTournamentUseCase {
  final TournamentRepository repository;

  JoinTournamentUseCase(this.repository);

  Future<Tournament> call(String tournamentId) =>
      repository.joinTournament(tournamentId);
}
