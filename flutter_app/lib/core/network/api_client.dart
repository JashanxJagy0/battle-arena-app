import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../services/storage_service.dart';

class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient({required StorageService storageService})
      : _storageService = storageService {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(storageService: _storageService, dio: _dio),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Response<T>> delete<T>(String path, {Options? options}) async {
    try {
      return await _dio.delete<T>(path, options: options);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(message: 'Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractErrorMessage(e.response);
        if (statusCode == 401) {
          return const UnauthorisedException();
        }
        if (statusCode == 422) {
          return ValidationException(message: message);
        }
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ServerException(message: e.message ?? 'An unexpected error occurred.');
    }
  }

  String _extractErrorMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'An error occurred';
      }
    } catch (_) {}
    return 'An error occurred';
  }
}

class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final Dio _dio;
  Future<bool>? _refreshFuture;

  _AuthInterceptor({required StorageService storageService, required Dio dio})
      : _storageService = storageService,
        _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If a refresh is already in progress, wait for it
      _refreshFuture ??= _attemptTokenRefresh();
      final refreshed = await _refreshFuture;
      _refreshFuture = null;

      if (refreshed) {
        final newToken = await _storageService.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (e) {
          // Fall through to next(err)
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final newAccessToken = response.data['accessToken'] as String?;
      if (newAccessToken != null) {
        await _storageService.saveAccessToken(newAccessToken);
        return true;
      }
      return false;
    } catch (_) {
      await _storageService.clearTokens();
      return false;
    }
  }
}
