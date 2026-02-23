import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  });

  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? referralCode,
  });

  Future<void> sendOtp({required String phone});

  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'identifier': identifier, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data!);
    } on UnauthorisedException {
      throw const AuthException(message: 'Invalid credentials');
    }
  }

  @override
  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? referralCode,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (referralCode != null) 'referralCode': referralCode,
      },
    );
    return UserModel.fromJson(response.data!['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    await _apiClient.post<void>(
      ApiEndpoints.sendOtp,
      data: {'phone': phone},
    );
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {'phone': phone, 'otp': otp},
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post<void>(ApiEndpoints.logout);
  }
}
