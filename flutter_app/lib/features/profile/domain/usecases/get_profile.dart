import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repository;
  GetProfile(this._repository);
  Future<UserProfile> call() => _repository.getProfile();
}
