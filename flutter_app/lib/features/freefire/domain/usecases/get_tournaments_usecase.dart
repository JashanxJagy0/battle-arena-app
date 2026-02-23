import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class GetTournamentsUseCase {
  final TournamentRepository repository;

  GetTournamentsUseCase(this.repository);

  Future<List<Tournament>> call({String? status, String? gameMode}) =>
      repository.getTournaments(status: status, gameMode: gameMode);
}
