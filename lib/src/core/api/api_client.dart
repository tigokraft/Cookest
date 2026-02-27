import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../errors/app_error.dart';
import '../storage/secure_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Try refresh
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) throw AppError('Session expired');

        final resp = await Dio().post(
          '${AppConfig.apiUrl}/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final newAccess = resp.data['access_token'] as String;
        final newRefresh = resp.data['refresh_token'] as String;
        await SecureStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        // Retry original request with new token
        error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(error.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        await SecureStorage.clearTokens();
        return handler.reject(error);
      }
    }
    handler.next(error);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.get(path, queryParameters: queryParams);
      return fromJson != null ? fromJson(resp.data) : resp.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.post(path, data: data);
      return fromJson != null ? fromJson(resp.data) : resp.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.put(path, data: data);
      return fromJson != null ? fromJson(resp.data) : resp.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppError _handleError(DioException e) {
    final data = e.response?.data;
    final message = data is Map ? data['error'] ?? data['message'] ?? 'Something went wrong' : 'Network error';
    return AppError(message.toString(), statusCode: e.response?.statusCode);
  }
}
