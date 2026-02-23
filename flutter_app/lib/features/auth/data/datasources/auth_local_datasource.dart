import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService _storageService;

  AuthLocalDataSourceImpl({required StorageService storageService})
      : _storageService = storageService;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _storageService.setUserId(user.id);
    } catch (e) {
      throw CacheException(message: 'Failed to cache user: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userId = _storageService.userId;
    if (userId == null) return null;
    // In a full implementation, retrieve from local DB/secure storage.
    return null;
  }

  @override
  Future<void> clearUser() async {
    await _storageService.clearTokens();
  }
}
