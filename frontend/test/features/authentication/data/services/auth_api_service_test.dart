import 'dart:convert';
import 'package:civicpulse_frontend/core/network/api_client.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/services/auth_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSessionManager extends Fake implements SessionManager {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<bool> hasValidAccessToken({Duration safetyWindow = const Duration(seconds: 60)}) async => false;

  @override
  Future<bool> hasRefreshToken() async => false;
}

void main() {
  group('AuthApiService Multipart Registration Tests', () {
    test('register sends correct multipart fields and profileImage file', () async {
      late http.Request capturedRequest;

      final mockHttpClient = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'token': 'mock_jwt_token_12345',
            'message': 'User registered successfully',
            'user': {
              'userId': 42,
              'fullName': 'Kasun Perera',
              'email': 'kasun@example.com',
              'phoneNumber': '+94771234567',
              'profileImage': 'https://res.cloudinary.com/demo/image/upload/v1/civicpulse/profiles/xyz.jpg',
              'role': 'CITIZEN',
              'accountStatus': 'ACTIVE',
              'registeredTerritoryId': 3,
              'registeredTerritoryName': 'Kandy Municipal Council',
              'createdAt': '2026-09-09T10:00:00',
            },
          }),
          201,
        );
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: FakeSessionManager(),
      );

      final authApiService = AuthApiService(apiClient: apiClient);

      final requestModel = RegisterRequestModel(
        fullName: 'Kasun Perera',
        email: 'kasun@example.com',
        phoneNumber: '+94771234567',
        password: 'Password123!',
        registeredTerritoryId: 3,
        profileImageBytes: [1, 2, 3, 4],
        profileImageFilename: 'avatar.jpg',
      );

      final response = await authApiService.register(requestModel);

      // Verify multipart endpoint and method
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/api/auth/register');
      expect(capturedRequest.headers['content-type'], contains('multipart/form-data'));

      // Verify exact field names required by backend
      expect(capturedRequest.body, contains('name="fullName"'));
      expect(capturedRequest.body, contains('Kasun Perera'));
      expect(capturedRequest.body, contains('name="email"'));
      expect(capturedRequest.body, contains('kasun@example.com'));
      expect(capturedRequest.body, contains('name="phoneNumber"'));
      expect(capturedRequest.body, contains('+94771234567'));
      expect(capturedRequest.body, contains('name="password"'));
      expect(capturedRequest.body, contains('Password123!'));
      expect(capturedRequest.body, contains('name="registeredTerritoryId"'));
      expect(capturedRequest.body, contains('3'));

      // Verify profileImage file part
      expect(capturedRequest.body, contains('name="profileImage"'));
      expect(capturedRequest.body, contains('filename="avatar.jpg"'));

      // Verify AuthResponseModel parsing
      expect(response.token, 'mock_jwt_token_12345');
      expect(response.message, 'User registered successfully');
      expect(response.user.userId, 42);
      expect(response.user.fullName, 'Kasun Perera');
      expect(response.user.email, 'kasun@example.com');
      expect(response.user.phoneNumber, '+94771234567');
      expect(response.user.registeredTerritoryId, 3);
      expect(response.user.registeredTerritoryName, 'Kandy Municipal Council');
      expect(response.user.profileImage, contains('cloudinary.com'));
    });
  });
}
