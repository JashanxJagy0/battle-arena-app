import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserProfile> getProfile() => _remoteDataSource.getProfile();

  @override
  Future<UserProfile> updateProfile({
    String? username,
    String? email,
    String? freefireUid,
    String? freefireIgn,
    String? avatarUrl,
  }) => _remoteDataSource.updateProfile(
    username: username,
    email: email,
    freefireUid: freefireUid,
    freefireIgn: freefireIgn,
    avatarUrl: avatarUrl,
  );

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) =>
      _remoteDataSource.changePassword(currentPassword: currentPassword, newPassword: newPassword);

  @override
  Future<void> deleteAccount() => _remoteDataSource.deleteAccount();
}
