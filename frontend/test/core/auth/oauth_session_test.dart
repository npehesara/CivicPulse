import 'package:civicpulse_frontend/core/auth/oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthSession Model Tests', () {
    test('valid token detection without expiry should return true', () {
      const session = OAuthSession(
        accessToken: 'access_token_123',
      );

      expect(session.hasValidAccessToken(), isTrue);
      expect(session.isExpired, isFalse);
      expect(session.hasRefreshToken, isFalse);
    });

    test('valid token with future expiration should return true', () {
      final futureExpiry = DateTime.now().add(const Duration(minutes: 15));
      final session = OAuthSession(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_abc',
        accessTokenExpiration: futureExpiry,
      );

      expect(session.hasValidAccessToken(), isTrue);
      expect(session.isExpired, isFalse);
      expect(session.hasRefreshToken, isTrue);
    });

    test('token expiring within safety window (60s) should be detected as expired', () {
      final expiringSoon = DateTime.now().add(const Duration(seconds: 30));
      final session = OAuthSession(
        accessToken: 'access_token_123',
        accessTokenExpiration: expiringSoon,
      );

      // Default safety window is 60s
      expect(session.hasValidAccessToken(), isFalse);
      expect(session.isExpired, isTrue);

      // With 10s safety window, 30s remaining is still valid
      expect(
        session.hasValidAccessToken(safetyWindow: const Duration(seconds: 10)),
        isTrue,
      );
    });

    test('past expiration should be detected as expired', () {
      final pastExpiry = DateTime.now().subtract(const Duration(minutes: 5));
      final session = OAuthSession(
        accessToken: 'access_token_123',
        accessTokenExpiration: pastExpiry,
      );

      expect(session.hasValidAccessToken(), isFalse);
      expect(session.isExpired, isTrue);
    });

    test('empty access token should not be valid', () {
      const session = OAuthSession(
        accessToken: '',
      );

      expect(session.hasValidAccessToken(), isFalse);
    });

    test('JSON serialization and deserialization should preserve fields', () {
      final expiry = DateTime(2026, 9, 5, 21, 0, 0);
      final session = OAuthSession(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        idToken: 'id_789',
        accessTokenExpiration: expiry,
        tokenType: 'Bearer',
        scopes: ['openid', 'profile', 'civicpulse.read'],
      );

      final json = session.toJson();
      expect(json['access_token'], 'access_123');
      expect(json['refresh_token'], 'refresh_456');
      expect(json['id_token'], 'id_789');
      expect(json['expires_at'], expiry.toIso8601String());
      expect(json['token_type'], 'Bearer');
      expect(json['scopes'], contains('civicpulse.read'));

      final restored = OAuthSession.fromJson(json);
      expect(restored.accessToken, 'access_123');
      expect(restored.refreshToken, 'refresh_456');
      expect(restored.idToken, 'id_789');
      expect(restored.accessTokenExpiration, expiry);
      expect(restored.scopes, contains('profile'));
    });

    test('toString should not leak raw access or refresh tokens', () {
      const session = OAuthSession(
        accessToken: 'SUPER_SECRET_ACCESS_TOKEN',
        refreshToken: 'SUPER_SECRET_REFRESH_TOKEN',
      );

      final str = session.toString();
      expect(str.contains('SUPER_SECRET_ACCESS_TOKEN'), isFalse);
      expect(str.contains('SUPER_SECRET_REFRESH_TOKEN'), isFalse);
      expect(str.contains('hasRefreshToken: true'), isTrue);
    });
  });
}
