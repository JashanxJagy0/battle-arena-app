import '../entities/tournament.dart';
import '../entities/custom_room.dart';

abstract class TournamentRepository {
  Future<List<Tournament>> getTournaments({String? status, String? gameMode});
  Future<Tournament> getTournamentDetails(String tournamentId);
  Future<Tournament> joinTournament(String tournamentId);
  Future<Tournament> checkIn(String tournamentId);
  Future<CustomRoom> getRoomDetails(String tournamentId);
  Future<void> submitResult({
    required String tournamentId,
    required int placement,
    required int kills,
  });
}
