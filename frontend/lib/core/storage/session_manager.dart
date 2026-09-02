import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/authentication/data/models/user_model.dart';

class SessionManager {
  static const String _tokenKey = 'civicpulse_jwt_token';
  static const String _userKey = 'civicpulse_user_profile';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  String? _inMemoryToken;
  UserModel? _inMemoryUser;

  SessionManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Gracefully continue with secure storage or memory
    }
    _inMemoryToken = await getToken();
    _inMemoryUser = await getUser();
  }

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    _inMemoryToken = token;
    _inMemoryUser = user;

    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      await _prefs?.setString(_tokenKey, token);
    }

    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs?.setString(_userKey, userJson);
    } catch (_) {
      // Ignored
    }
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }

    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _inMemoryToken = token;
        return token;
      }
    } catch (_) {
      // Fallback
    }

    final fallbackToken = _prefs?.getString(_tokenKey);
    _inMemoryToken = fallbackToken;
    return fallbackToken;
  }

  Future<UserModel?> getUser() async {
    if (_inMemoryUser != null) {
      return _inMemoryUser;
    }

    final userJson = _prefs?.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> map = jsonDecode(userJson);
        _inMemoryUser = UserModel.fromJson(map);
        return _inMemoryUser;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    _inMemoryToken = null;
    _inMemoryUser = null;

    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}

    try {
      await _prefs?.remove(_tokenKey);
      await _prefs?.remove(_userKey);
    } catch (_) {}
  }
}
