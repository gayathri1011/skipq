import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResult> registerStudent({
    required String name,
    required String mobile,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/student-register',
      data: {'name': name, 'mobile': mobile},
    );
    return _parseAuth(response.data);
  }

  Future<AuthResult> loginStudent({required String mobile}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/student-login',
      data: {'mobile': mobile},
    );
    return _parseAuth(response.data);
  }

  Future<AuthResult> loginManager({
    required String managerId,
    required String password,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/auth/manager-login',
      data: {'managerId': managerId, 'password': password},
    );
    return _parseAuth(response.data);
  }

  Future<AppUser> me() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/auth/me');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw DioException(requestOptions: response.requestOptions);
    }
    return AppUser.fromJson(user);
  }

  Future<StudentUser> updateStudentProfile({
    required String name,
    required String registerNumber,
    required String department,
    required String academicStream,
  }) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/auth/student-profile',
      data: {
        'name': name,
        'registerNumber': registerNumber,
        'department': department,
        'academicStream': academicStream,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw DioException(requestOptions: response.requestOptions);
    }
    return AppUser.fromJson(user) as StudentUser;
  }

  AuthResult _parseAuth(Map<String, dynamic>? json) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message'] ?? 'Authentication failed');
    }
    final data = json['data'] as Map<String, dynamic>;
    return AuthResult(
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
