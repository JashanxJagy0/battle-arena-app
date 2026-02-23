import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class GetTournamentDetailsUseCase {
  final TournamentRepository repository;

  GetTournamentDetailsUseCase(this.repository);

  Future<Tournament> call(String tournamentId) =>
      repository.getTournamentDetails(tournamentId);
}
