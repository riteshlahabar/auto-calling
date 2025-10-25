// lib/data/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_request.dart';
import 'api_service.dart';

class AuthService {
  AuthService(this._api);

  final ApiService _api;

  String? _token;
  int? _userId;

  bool _logoutSuppressed = false;
  DateTime? _suppressUntil;

  // Expose the shared Dio from ApiService
  Dio get http => _api.http;
  int? get currentUserId => _userId;
  String? get token => _token;

  bool get logoutSuppressed =>
      _logoutSuppressed &&
      (_suppressUntil == null || DateTime.now().isBefore(_suppressUntil!));

  void suppressLogout({Duration? grace}) {
    _logoutSuppressed = true;
    _suppressUntil = grace == null ? null : DateTime.now().add(grace);
  }

  void resumeLogout() {
    _logoutSuppressed = false;
    _suppressUntil = null;
  }

  Future<void> signOutSafely() async {
    if (logoutSuppressed) return;
    await signOut();
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('user_id');
    _token = null;
    _userId = null;
    _api.setToken(null); // clear Authorization on the shared Dio
  }

  Future<void> _saveSession(String token, int userId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', token);
    await sp.setInt('user_id', userId);
  }

  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('token');
    _userId = sp.getInt('user_id');
    _api.setToken(_token); // apply persisted token to shared Dio
  }

  Future<bool> login(LoginRequest req) async {
    try {
      final res = await http.post('/v1/auth/login', data: req.toJson());
      if (res.statusCode == 200 && res.data != null) {
        final token = res.data['token'] as String;
        final user = res.data['user'] as Map<String, dynamic>;
        _token = token;
        _userId = (user['id'] as num).toInt();
        _api.setToken(token); // update Authorization on the shared Dio
        await _saveSession(token, _userId!);
        return true;
      }
      throw Exception('HTTP ${res.statusCode}');
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMsg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : null;
      throw Exception(serverMsg ?? e.message ?? 'Network error');
    }
  }

  // Optional refresh (return false if not implemented)
  Future<bool> tryRefresh() async {
    // If your backend supports refresh, implement here and then call:
    // _token = newToken; _api.setToken(newToken); await _saveSession(newToken, _userId!);
    return false;
  }
}
