import 'package:civicpulse_frontend/core/auth/oauth_service.dart';
import 'package:civicpulse_frontend/core/auth/oauth_session.dart';
import 'package:civicpulse_frontend/core/network/api_client.dart';
import 'package:civicpulse_frontend/core/network/api_exception.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/data/services/auth_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthApiService implements AuthApiService {
  bool shouldFail = false;
  int failureCode = 401;
  String failureMessage = 'Invalid email or password';

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    if (shouldFail) {
      throw ApiException(statusCode: failureCode, message: failureMessage);
    }
    return AuthResponseModel(
      token: 'fake_jwt_token_123',
      message: 'Login successful',
      user: UserModel(
        userId: 1,
        fullName: 'John Doe',
        email: request.email,
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      ),
    );
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    if (shouldFail) {
      throw ApiException(statusCode: failureCode, message: failureMessage);
    }
    return AuthResponseModel(
      token: 'fake_jwt_token_123',
      message: 'User registered successfully',
      user: UserModel(
        userId: 1,
        fullName: request.fullName,
        email: request.email,
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      ),
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    if (shouldFail) {
      throw ApiException(statusCode: failureCode, message: failureMessage);
    }
    return const UserModel(
      userId: 1,
      fullName: 'OAuth Citizen',
      email: 'citizen@example.com',
      role: 'CITIZEN',
      accountStatus: 'ACTIVE',
    );
  }
}

class FakeSessionManager extends SessionManager {
  String? token;
  UserModel? user;

  @override
  Future<void> saveSession({required String token, required UserModel user}) async {
    this.token = token;
    this.user = user;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    this.user = user;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<bool> isLoggedIn() async => token != null && token!.isNotEmpty;

  @override
  Future<void> clearSession() async {
    token = null;
    user = null;
  }
}

class FakeOAuthService extends Fake implements OAuthService {
  bool shouldFail = false;

  @override
  Future<OAuthSession> authorize({
    List<String>? promptValues,
    Map<String, String>? additionalParameters,
  }) async {
    if (shouldFail) {
      throw Exception('OAuth failed');
    }
    return const OAuthSession(
      accessToken: 'oauth_access_token_123',
      refreshToken: 'oauth_refresh_token_456',
    );
  }
}

void main() {
  late FakeAuthApiService apiService;
  late FakeSessionManager sessionManager;
  late FakeOAuthService oauthService;
  late AuthRepositoryImpl authRepository;

  setUp(() {
    apiService = FakeAuthApiService();
    sessionManager = FakeSessionManager();
    oauthService = FakeOAuthService();
    authRepository = AuthRepositoryImpl(
      apiService: apiService,
      sessionManager: sessionManager,
      oauthService: oauthService,
    );
  });

  group('AuthRepository Test', () {
    test('loginWithOAuth should authorize, fetch current user, save profile, and return UserModel', () async {
      final user = await authRepository.loginWithOAuth();

      expect(user.email, 'citizen@example.com');
      expect(user.fullName, 'OAuth Citizen');
      expect((await sessionManager.getUser())?.email, 'citizen@example.com');
    });

    test('successful login should save session and return AuthResponseModel', () async {
      final request = LoginRequestModel(email: 'john@example.com', password: 'Password123!');
      final response = await authRepository.login(request);

      expect(response.token, 'fake_jwt_token_123');
      expect(response.user.email, 'john@example.com');
      expect(await sessionManager.isLoggedIn(), isTrue);
      expect(await sessionManager.getToken(), 'fake_jwt_token_123');
    });

    test('failed login should propagate ApiException and not save token', () async {
      apiService.shouldFail = true;
      apiService.failureCode = 401;
      apiService.failureMessage = 'Invalid email or password';

      final request = LoginRequestModel(email: 'wrong@example.com', password: 'bad');

      expect(
        () => authRepository.login(request),
        throwsA(isA<ApiException>()),
      );
      expect(await sessionManager.isLoggedIn(), isFalse);
    });

    test('successful register should call apiService', () async {
      final request = RegisterRequestModel(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'Password123!',
      );

      final response = await authRepository.register(request);
      expect(response.message, 'User registered successfully');
      expect(response.user.fullName, 'Jane Doe');
    });

    test('logout should clear token and user from session', () async {
      await sessionManager.saveSession(
        token: 'token123',
        user: const UserModel(
          userId: 1,
          fullName: 'John',
          email: 'john@example.com',
          role: 'CITIZEN',
          accountStatus: 'ACTIVE',
        ),
      );

      expect(await sessionManager.isLoggedIn(), isTrue);
      await authRepository.logout();
      expect(await sessionManager.isLoggedIn(), isFalse);
    });
  });
}
