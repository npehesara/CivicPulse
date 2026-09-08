import 'package:civicpulse_frontend/core/auth/oauth_exception.dart';
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
  bool shouldCancelOAuth = false;

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
    if (shouldCancelOAuth) {
      throw OAuthException.userCancelled();
    }
    if (!shouldSucceed) {
      throw OAuthException.authorizationFailed('OAuth failed');
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

  Widget buildLoginScreen(AuthController controller) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthController>.value(
        value: controller,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen should display Sign In button without email/password fields', (tester) async {
    final mockRepo = MockAuthRepo();
    final authController = AuthController(authRepository: mockRepo);

    await tester.pumpWidget(buildLoginScreen(authController));
    await tester.pump();

    // OAuth-only screen: Sign In button must be present
    expect(find.text('Sign In'), findsOneWidget);

    // Register link must still be present
    expect(find.text('Register'), findsOneWidget);

    // Email and password fields must NOT be present — they are never used
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Tapping Sign In triggers loginWithOAuth and not legacy email/password login', (tester) async {
    final mockRepo = MockAuthRepo();
    mockRepo.shouldCancelOAuth = true; // User cancels — stay on screen
    final authController = AuthController(authRepository: mockRepo);

    await tester.pumpWidget(buildLoginScreen(authController));
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // OAuth flow must have been called
    expect(mockRepo.oauthCalled, isTrue);

    // After user cancellation, status is unauthenticated (no error message shown)
    expect(authController.status, AuthStatus.unauthenticated);
    expect(authController.errorMessage, isNull);
  });

  testWidgets('OAuth failure shows error banner on LoginScreen', (tester) async {
    final mockRepo = MockAuthRepo();
    mockRepo.shouldSucceed = false;
    final authController = AuthController(authRepository: mockRepo);

    await tester.pumpWidget(buildLoginScreen(authController));
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(mockRepo.oauthCalled, isTrue);
    expect(authController.status, AuthStatus.error);
    expect(find.text('Authorization failed. Please try again.'), findsOneWidget);
  });
}
