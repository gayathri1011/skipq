import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient apiClient,
    required AuthService authService,
    required SocketService socketService,
  })  : _api = apiClient,
        _auth = authService,
        _socket = socketService {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final AuthService _auth;
  final SocketService _socket;

  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isStudent => _user?.role == UserRole.student;
  bool get isManager => _user?.role == UserRole.manager;

  Future<void> bootstrap() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _api.getToken();
      if (token != null && token.isNotEmpty) {
        _user = await _auth.me();
        await _socket.connect();
      }
    } catch (_) {
      await _api.clearToken();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerStudent(String name, String mobile) async {
    final result = await _auth.registerStudent(name: name, mobile: mobile);
    await _completeLogin(result);
  }

  Future<void> loginStudent(String mobile) async {
    final result = await _auth.loginStudent(mobile: mobile);
    await _completeLogin(result);
  }

  Future<void> loginManager(String managerId, String password) async {
    final result = await _auth.loginManager(
      managerId: managerId,
      password: password,
    );
    await _completeLogin(result);
  }

  Future<void> updateStudentProfile({
    required String name,
    required String registerNumber,
    required String department,
    required String academicStream,
  }) async {
    _user = await _auth.updateStudentProfile(
      name: name,
      registerNumber: registerNumber,
      department: department,
      academicStream: academicStream,
    );
    notifyListeners();
  }

  Future<void> _completeLogin(AuthResult result) async {
    await _api.setToken(result.token);
    _user = result.user;
    await _socket.connect();
    notifyListeners();
  }

  Future<void> logout() async {
    _socket.disconnect();
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }

  void _handleUnauthorized() {
    _user = null;
    _socket.disconnect();
    notifyListeners();
  }

  String messageFromError(Object error,
      {String fallback = 'Something went wrong'}) {
    if (error is DioException) {
      return _api.messageFromError(error, fallback: fallback);
    }
    return fallback;
  }
}
