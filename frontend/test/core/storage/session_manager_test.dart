import 'package:civicpulse_frontend/core/auth/oauth_session.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFlutterSecureStorage secureStorage;
  late SessionManager sessionManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureStorage = FakeFlutterSecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    await sessionManager.init();
  });

  group('SessionManager OAuth Storage Tests', () {
    test('saveOAuthSession should store tokens in secure storage and not in SharedPreferences', () async {
      final expiry = DateTime.now().add(const Duration(minutes: 15));
      final session = OAuthSession(
        accessToken: 'access_jwt_123',
        refreshToken: 'refresh_token_456',
        idToken: 'id_token_789',
        accessTokenExpiration: expiry,
        scopes: ['openid', 'profile'],
      );

      await sessionManager.saveOAuthSession(session);

      // Verify secure storage has tokens
      expect(await sessionManager.getAccessToken(), 'access_jwt_123');
      expect(await sessionManager.getRefreshToken(), 'refresh_token_456');
      expect(await sessionManager.getIdToken(), 'id_token_789');
      expect(await sessionManager.hasValidAccessToken(), isTrue);
      expect(await sessionManager.hasRefreshToken(), isTrue);
      expect(await sessionManager.isLoggedIn(), isTrue);

      // Verify SharedPreferences does NOT contain tokens
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('civicpulse_access_token'), isNull);
      expect(prefs.getString('civicpulse_refresh_token'), isNull);
      expect(prefs.getString('civicpulse_jwt_token'), isNull);
    });

    test('getAccessTokenExpiration should return valid DateTime', () async {
      final expiry = DateTime.now().add(const Duration(minutes: 15));
      final session = OAuthSession(
        accessToken: 'token_123',
        accessTokenExpiration: expiry,
      );

      await sessionManager.saveOAuthSession(session);
      final storedExpiry = await sessionManager.getAccessTokenExpiration();

      expect(storedExpiry, isNotNull);
      expect(storedExpiry!.difference(expiry).inSeconds.abs(), lessThan(2));
    });

    test('hasValidAccessToken should detect expired tokens with safety window', () async {
      final expiringSoon = DateTime.now().add(const Duration(seconds: 45));
      final session = OAuthSession(
        accessToken: 'expiring_token',
        accessTokenExpiration: expiringSoon,
      );

      await sessionManager.saveOAuthSession(session);

      // With default 60s safety window, token expiring in 45s should be considered expired
      expect(await sessionManager.hasValidAccessToken(), isFalse);

      // With 10s safety window, it is still valid
      expect(
        await sessionManager.hasValidAccessToken(safetyWindow: const Duration(seconds: 10)),
        isTrue,
      );
    });

    test('clearSession should remove all stored OAuth and legacy tokens and user profile', () async {
      final session = OAuthSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_123',
        idToken: 'id_123',
        accessTokenExpiration: DateTime.now().add(const Duration(hours: 1)),
      );

      await sessionManager.saveOAuthSession(session);
      await sessionManager.saveUser(
        UserModel(
          userId: 1,
          fullName: 'John Doe',
          email: 'john@example.com',
          role: 'CITIZEN',
          accountStatus: 'ACTIVE',
        ),
      );

      expect(await sessionManager.isLoggedIn(), isTrue);
      expect(await sessionManager.getUser(), isNotNull);

      await sessionManager.clearSession();

      expect(await sessionManager.getAccessToken(), isNull);
      expect(await sessionManager.getRefreshToken(), isNull);
      expect(await sessionManager.getIdToken(), isNull);
      expect(await sessionManager.getOAuthSession(), isNull);
      expect(await sessionManager.getUser(), isNull);
      expect(await sessionManager.isLoggedIn(), isFalse);
    });

    test('legacy saveSession and getToken fallback should work for backward compatibility', () async {
      final user = UserModel(
        userId: 2,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      );

      await sessionManager.saveSession(token: 'legacy_jwt_abc', user: user);

      expect(await sessionManager.getToken(), 'legacy_jwt_abc');
      expect(await sessionManager.getAccessToken(), 'legacy_jwt_abc');
      expect(await sessionManager.isLoggedIn(), isTrue);
      expect((await sessionManager.getUser())?.email, 'jane@example.com');
    });
  });
}
