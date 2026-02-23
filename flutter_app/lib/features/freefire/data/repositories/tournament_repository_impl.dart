import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/custom_room.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../models/tournament_model.dart';
import '../models/custom_room_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final ApiClient _apiClient;

  TournamentRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<Tournament>> getTournaments({
    String? status,
    String? gameMode,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (gameMode != null) queryParams['gameMode'] = gameMode;

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.freefireTournaments,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Tournament> getTournamentDetails(String tournamentId) async {
    final path = ApiEndpoints.freefireTournamentDetails
        .replaceFirst(':id', tournamentId);
    final response = await _apiClient.get<dynamic>(path);
    return TournamentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Tournament> joinTournament(String tournamentId) async {
    final path =
        ApiEndpoints.freefireJoinTournament.replaceFirst(':id', tournamentId);
    final response = await _apiClient.post<dynamic>(path);
    return TournamentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Tournament> checkIn(String tournamentId) async {
    final path =
        ApiEndpoints.freefireCheckIn.replaceFirst(':id', tournamentId);
    final response = await _apiClient.post<dynamic>(path);
    return TournamentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CustomRoom> getRoomDetails(String tournamentId) async {
    final path =
        ApiEndpoints.freefireRoomDetails.replaceFirst(':id', tournamentId);
    final response = await _apiClient.get<dynamic>(path);
    return CustomRoomModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> submitResult({
    required String tournamentId,
    required int placement,
    required int kills,
  }) async {
    final path =
        ApiEndpoints.freefireSubmitResult.replaceFirst(':id', tournamentId);
    await _apiClient.post<dynamic>(path, data: {
      'placement': placement,
      'kills': kills,
    });
  }
}
