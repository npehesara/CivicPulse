import 'package:civicpulse_frontend/core/constants/app_strings.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MockAuthRepo implements AuthRepository {
  bool oauthCalled = false;
  bool shouldSucceed = true;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    return AuthResponseModel(
      token: 'token',
      message: 'success',
      user: UserModel(
        userId: 1,
        fullName: 'Test',
        email: request.email,
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      ),
    );
  }

  @override
  Future<UserModel> loginWithOAuth() async {
    oauthCalled = true;
    if (!shouldSucceed) {
      throw Exception('OAuth cancelled');
    }
    return const UserModel(
      userId: 1,
      fullName: 'OAuth User',
      email: 'oauth@example.com',
      role: 'CITIZEN',
      accountStatus: 'ACTIVE',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    return AuthResponseModel(
      token: 'token',
      message: 'success',
      user: UserModel(
        userId: 1,
        fullName: request.fullName,
        email: request.email,
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      ),
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('LoginScreen should display email, password, and sign in button', (tester) async {
    final mockRepo = MockAuthRepo();
    final authController = AuthController(authRepository: mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthController>.value(
          value: authController,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.emailLabel), findsOneWidget);
    expect(find.text(AppStrings.passwordLabel), findsOneWidget);
    expect(find.text(AppStrings.signInButton), findsOneWidget);
    expect(find.text(AppStrings.registerLink), findsOneWidget);
  });

  testWidgets('Tapping sign in button should trigger OAuth login flow and handle cancellation/failure cleanly', (tester) async {
    final mockRepo = MockAuthRepo();
    mockRepo.shouldSucceed = false; // Stay on screen to verify UI state
    final authController = AuthController(authRepository: mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthController>.value(
          value: authController,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Tap sign in button to trigger OAuth flow
    await tester.tap(find.text(AppStrings.signInButton));
    await tester.pumpAndSettle();

    expect(mockRepo.oauthCalled, isTrue);
    expect(authController.status, AuthStatus.error);
    expect(find.text('Unable to sign in with OAuth. Please try again.'), findsOneWidget);
  });
}
