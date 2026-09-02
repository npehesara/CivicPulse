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
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    return AuthResponseModel(
      token: 'token',
      message: 'success',
      user: UserModel(userId: 1, fullName: 'Test', email: request.email, role: 'CITIZEN', accountStatus: 'ACTIVE'),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    return AuthResponseModel(
      token: 'token',
      message: 'success',
      user: UserModel(userId: 1, fullName: request.fullName, email: request.email, role: 'CITIZEN', accountStatus: 'ACTIVE'),
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

  testWidgets('Submitting empty form should trigger validation error messages', (tester) async {
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

    // Tap sign in without filling form
    await tester.tap(find.text(AppStrings.signInButton));
    await tester.pumpAndSettle();

    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
