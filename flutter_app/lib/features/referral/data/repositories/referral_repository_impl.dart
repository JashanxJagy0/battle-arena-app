import '../../domain/entities/referral.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_remote_datasource.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDataSource _remoteDataSource;

  ReferralRepositoryImpl({required ReferralRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<ReferralStats> getReferralStats() => _remoteDataSource.getReferralStats();
}
