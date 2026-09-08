import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import 'register_screen.dart';

/// OAuth-only login screen.
///
/// Credentials are entered exactly once — on the Spring Security login page
/// opened by FlutterAppAuth inside a Chrome Custom Tab. This screen never
/// collects or transmits the user's password directly.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final authController = context.read<AuthController>();
    authController.clearError();

    final success = await authController.loginWithOAuth();

    if (success && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AuthController>(
                builder: (context, authController, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Welcome to CivicPulse',
                        subtitle:
                            'Sign in securely to track and report civic issues in your area.',
                      ),

                      // Error banner — shown when OAuth fails or is unexpectedly cancelled
                      ErrorBanner(
                        message: authController.errorMessage,
                        onDismiss: authController.clearError,
                      ),

                      const SizedBox(height: 8),

                      // Primary OAuth Sign In button.
                      // Tapping opens the Spring Security login page inside a
                      // Chrome Custom Tab via FlutterAppAuth (Authorization Code
                      // + PKCE). The user enters their credentials there — once,
                      // not here. After successful authentication the auth code
                      // is exchanged for tokens and the app navigates to HomeScreen.
                      CustomButton(
                        text: 'Sign In',
                        icon: Icons.lock_outline_rounded,
                        onPressed: authController.isLoading
                            ? null
                            : () => _handleLogin(context),
                        isLoading: authController.isLoading,
                      ),

                      const SizedBox(height: 32),

                      // Privacy note so users understand credentials are handled
                      // by the secure OAuth server, not stored in the app.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Secured by OAuth 2.1 · PKCE enabled',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Register link — navigates to the account-creation screen
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: authController.isLoading
                                      ? null
                                      : () {
                                          authController.clearError();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterScreen(),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
