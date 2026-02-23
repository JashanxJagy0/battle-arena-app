import '../../../../core/services/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final StorageService _storageService;

  User? _currentUser;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _storageService = storageService;

  @override
  Future<({String accessToken, String refreshToken, User user})> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      identifier: identifier,
      password: password,
    );
    await _storageService.saveAccessToken(response.accessToken);
    await _storageService.saveRefreshToken(response.refreshToken);
    await _localDataSource.cacheUser(response.user);
    _currentUser = response.user;
    return (
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: response.user as User,
    );
  }

  @override
  Future<User> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? referralCode,
  }) async {
    final user = await _remoteDataSource.register(
      username: username,
      password: password,
      email: email,
      phone: phone,
      referralCode: referralCode,
    );
    return user;
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    await _remoteDataSource.sendOtp(phone: phone);
  }

  @override
  Future<({String accessToken, String refreshToken, User user})> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _remoteDataSource.verifyOtp(phone: phone, otp: otp);
    await _storageService.saveAccessToken(response.accessToken);
    await _storageService.saveRefreshToken(response.refreshToken);
    await _localDataSource.cacheUser(response.user);
    _currentUser = response.user;
    return (
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: response.user as User,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Proceed with local logout even if server call fails
    }
    await _localDataSource.clearUser();
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    return _localDataSource.getCachedUser();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    return token != null;
  }
}
