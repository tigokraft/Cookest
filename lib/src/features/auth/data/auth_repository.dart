import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(Dio()));

class AuthRepository {
  final Dio _dio;
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Desktop/Web where api is on 8080
  // Since user is on Windows, localhost:8080 is likely correct if running windows app.
  static const String baseUrl = 'http://127.0.0.1:3000/api/auth';

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('AuthRepository: Attempting login with $email to $baseUrl/login');
    try {
      final response = await _dio.post(
        '$baseUrl/login',
        data: {'email': email, 'password': password},
      );
      print('AuthRepository: Login success: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('AuthRepository: Login DioError: ${e.message} ${e.response?.data}');
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error occurred: ${e.message}');
    } catch (e) {
      print('AuthRepository: Login Unknown Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/register',
        data: {'email': email, 'password': password},
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Network error occurred');
    }
  }
}
