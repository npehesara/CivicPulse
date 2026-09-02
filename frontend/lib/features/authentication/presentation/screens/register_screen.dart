import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authController = context.read<AuthController>();
    authController.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await authController.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.registrationSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AuthController>(
                builder: (context, authController, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthHeader(
                          title: AppStrings.registerTitle,
                          subtitle: AppStrings.registerSubtitle,
                        ),
                        ErrorBanner(
                          message: authController.errorMessage,
                          onDismiss: authController.clearError,
                        ),
                        CustomTextField(
                          controller: _fullNameController,
                          label: AppStrings.fullNameLabel,
                          hint: AppStrings.fullNameHint,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          enabled: !authController.isLoading,
                          validator: Validators.validateFullName,
                          errorText: authController.validationErrors?['fullName'],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          hint: AppStrings.emailHint,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !authController.isLoading,
                          validator: Validators.validateEmail,
                          errorText: authController.validationErrors?['email'],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneController,
                          label: AppStrings.phoneLabel,
                          hint: AppStrings.phoneHint,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !authController.isLoading,
                          validator: Validators.validatePhoneNumber,
                          errorText: authController.validationErrors?['phoneNumber'],
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          hint: AppStrings.passwordHint,
                          textInputAction: TextInputAction.next,
                          enabled: !authController.isLoading,
                          validator: Validators.validatePassword,
                          errorText: authController.validationErrors?['password'],
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _confirmPasswordController,
                          label: AppStrings.confirmPasswordLabel,
                          hint: AppStrings.confirmPasswordHint,
                          textInputAction: TextInputAction.done,
                          enabled: !authController.isLoading,
                          validator: (value) => Validators.validateConfirmPassword(
                            _passwordController.text,
                            value,
                          ),
                          onFieldSubmitted: (_) => _handleRegister(),
                        ),
                        const SizedBox(height: 28),
                        CustomButton(
                          text: AppStrings.registerButton,
                          onPressed: _handleRegister,
                          isLoading: authController.isLoading,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: AppStrings.hasAccountPrompt,
                              style: const TextStyle(
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
                                            Navigator.of(context).pop();
                                          },
                                    child: const Text(
                                      AppStrings.loginLink,
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
                        const SizedBox(height: 16),
                      ],
                    ),
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
