import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/data/repositories/auth_repository.dart';
import 'features/authentication/data/services/auth_api_service.dart';
import 'features/authentication/presentation/controllers/auth_controller.dart';
import 'features/issues/data/repositories/issue_repository.dart';
import 'features/issues/data/services/issue_api_service.dart';
import 'features/issues/presentation/controllers/issue_controller.dart';
import 'features/messages/data/repositories/message_repository.dart';
import 'features/messages/data/services/message_api_service.dart';
import 'features/messages/presentation/controllers/message_controller.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/data/services/notification_api_service.dart';
import 'features/notifications/presentation/controllers/notification_controller.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/users/data/repositories/user_repository.dart';
import 'features/users/data/services/user_api_service.dart';
import 'features/users/presentation/controllers/profile_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionManager = SessionManager();
  await sessionManager.init();

  final apiClient = ApiClient(sessionManager: sessionManager);

  // Auth
  final authApiService = AuthApiService(apiClient: apiClient);
  final authRepository = AuthRepositoryImpl(
    apiService: authApiService,
    sessionManager: sessionManager,
  );

  // Issues
  final issueApiService = IssueApiService(apiClient: apiClient);
  final issueRepository = IssueRepositoryImpl(apiService: issueApiService);

  // Users
  final userApiService = UserApiService(apiClient: apiClient);
  final userRepository = UserRepositoryImpl(apiService: userApiService);

  // Messages
  final messageApiService = MessageApiService(apiClient: apiClient);
  final messageRepository = MessageRepositoryImpl(apiService: messageApiService);

  // Notifications
  final notificationApiService = NotificationApiService(apiClient: apiClient);
  final notificationRepository = NotificationRepositoryImpl(apiService: notificationApiService);

  runApp(
    CivicPulseApp(
      authRepository: authRepository,
      issueRepository: issueRepository,
      userRepository: userRepository,
      messageRepository: messageRepository,
      notificationRepository: notificationRepository,
      apiClient: apiClient,
      sessionManager: sessionManager,
    ),
  );
}

class CivicPulseApp extends StatelessWidget {
  final AuthRepository authRepository;
  final IssueRepository issueRepository;
  final UserRepository userRepository;
  final MessageRepository messageRepository;
  final NotificationRepository notificationRepository;
  final ApiClient apiClient;
  final SessionManager sessionManager;

  const CivicPulseApp({
    super.key,
    required this.authRepository,
    required this.issueRepository,
    required this.userRepository,
    required this.messageRepository,
    required this.notificationRepository,
    required this.apiClient,
    required this.sessionManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SessionManager>.value(value: sessionManager),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IssueRepository>.value(value: issueRepository),
        Provider<UserRepository>.value(value: userRepository),
        Provider<MessageRepository>.value(value: messageRepository),
        Provider<NotificationRepository>.value(value: notificationRepository),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(authRepository: authRepository),
        ),
        ChangeNotifierProvider<IssueController>(
          create: (_) => IssueController(issueRepository: issueRepository),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (_) => ProfileController(
            userRepository: userRepository,
            issueRepository: issueRepository,
          ),
        ),
        ChangeNotifierProvider<MessageController>(
          create: (_) => MessageController(messageRepository: messageRepository),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(notificationRepository: notificationRepository),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
