import 'package:civicpulse_frontend/core/network/api_exception.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;
  UserModel? storedUser;
  bool isUserLoggedIn = false;
  ApiException? errorToThrow;

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    if (!shouldSucceed) {
      throw errorToThrow ?? ApiException(statusCode: 401, message: 'Invalid email or password.');
    }
    final user = UserModel(
      userId: 1,
      fullName: 'John Doe',
      email: request.email,
      role: 'CITIZEN',
      accountStatus: 'ACTIVE',
    );
    storedUser = user;
    isUserLoggedIn = true;
    return AuthResponseModel(token: 'valid_jwt_token', message: 'Login successful', user: user);
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    if (!shouldSucceed) {
      throw errorToThrow ?? ApiException(statusCode: 409, message: 'An account with this email already exists.');
    }
    final user = UserModel(
      userId: 1,
      fullName: request.fullName,
      email: request.email,
      role: 'CITIZEN',
      accountStatus: 'ACTIVE',
    );
    return AuthResponseModel(token: 'valid_jwt_token', message: 'User registered successfully', user: user);
  }

  @override
  Future<void> logout() async {
    storedUser = null;
    isUserLoggedIn = false;
  }

  @override
  Future<UserModel?> getCurrentUser() async => storedUser;

  @override
  Future<bool> isLoggedIn() async => isUserLoggedIn;
}

void main() {
  late MockAuthRepository mockRepository;
  late AuthController authController;

  setUp(() {
    mockRepository = MockAuthRepository();
    authController = AuthController(authRepository: mockRepository);
  });

  group('AuthController Test', () {
    test('initial status should be AuthStatus.initial', () {
      expect(authController.status, AuthStatus.initial);
      expect(authController.isLoading, isFalse);
      expect(authController.isAuthenticated, isFalse);
    });

    test('login success should update status to authenticated and store user', () async {
      final success = await authController.login('john@example.com', 'Password123!');

      expect(success, isTrue);
      expect(authController.status, AuthStatus.authenticated);
      expect(authController.isAuthenticated, isTrue);
      expect(authController.currentUser?.email, 'john@example.com');
      expect(authController.errorMessage, isNull);
    });

    test('login failure should update status to error and set message', () async {
      mockRepository.shouldSucceed = false;
      mockRepository.errorToThrow = ApiException(
        statusCode: 401,
        message: 'Invalid email or password.',
      );

      final success = await authController.login('wrong@example.com', 'badpass');

      expect(success, isFalse);
      expect(authController.status, AuthStatus.error);
      expect(authController.isAuthenticated, isFalse);
      expect(authController.errorMessage, 'Invalid email or password.');
    });

    test('register success should transition to unauthenticated and clear error', () async {
      final success = await authController.register(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'Password123!',
      );

      expect(success, isTrue);
      expect(authController.status, AuthStatus.unauthenticated);
      expect(authController.errorMessage, isNull);
    });

    test('register failure with duplicate email should set conflict error message', () async {
      mockRepository.shouldSucceed = false;
      mockRepository.errorToThrow = ApiException(
        statusCode: 409,
        message: 'An account with this email already exists.',
      );

      final success = await authController.register(
        fullName: 'Jane Doe',
        email: 'duplicate@example.com',
        password: 'Password123!',
      );

      expect(success, isFalse);
      expect(authController.status, AuthStatus.error);
      expect(authController.errorMessage, 'An account with this email already exists.');
    });

    test('logout should clear currentUser and set unauthenticated', () async {
      await authController.login('john@example.com', 'Password123!');
      expect(authController.isAuthenticated, isTrue);

      await authController.logout();
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
      expect(authController.status, AuthStatus.unauthenticated);
    });
  });
}
