import '../../domain/entities/wager.dart';
import '../../domain/repositories/wager_repository.dart';
import '../datasources/wager_remote_datasource.dart';

class WagerRepositoryImpl implements WagerRepository {
  final WagerRemoteDataSource _remoteDataSource;

  WagerRepositoryImpl({required WagerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Wager>> getWagers({String? period, int page = 1}) =>
      _remoteDataSource.getWagers(period: period, page: page);

  @override
  Future<WagerStats> getWagerStats({String? period}) =>
      _remoteDataSource.getWagerStats(period: period);

  @override
  Future<Wager> getWagerDetail(String wagerId) =>
      _remoteDataSource.getWagerDetail(wagerId);

  @override
  Future<List<Map<String, dynamic>>> getChartData({String period = 'daily'}) =>
      _remoteDataSource.getChartData(period: period);
}
