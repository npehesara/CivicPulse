import 'dart:async';
import 'dart:io';
import 'package:civicpulse_frontend/core/constants/app_strings.dart';
import 'package:civicpulse_frontend/core/network/api_exception.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/screens/register_screen.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/repositories/issue_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MockRegisterAuthRepo implements AuthRepository {
  bool shouldFail = false;
  RegisterRequestModel? lastRequest;

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async => throw UnimplementedError();

  @override
  Future<UserModel> loginWithOAuth() async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    lastRequest = request;
    if (shouldFail) {
      throw ApiException(statusCode: 400, message: 'Registration failed on server');
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
        registeredTerritoryId: request.registeredTerritoryId,
      ),
    );
  }
}

class MockIssueRepo extends Fake implements IssueRepository {
  List<TerritoryModel> territories = [
    const TerritoryModel(
      territoryId: 1,
      territoryName: 'Colombo Municipal Council',
      regionType: 'MUNICIPAL_COUNCIL',
      parentTerritoryName: 'Western Province',
    ),
    const TerritoryModel(
      territoryId: 2,
      territoryName: 'Balapitiya Pradeshiya Sabha',
      regionType: 'PRADESHIYA_SABHA',
      parentTerritoryName: 'Southern Province',
    ),
    const TerritoryModel(
      territoryId: 3,
      territoryName: 'Kandy Municipal Council',
      regionType: 'MUNICIPAL_COUNCIL',
      parentTerritoryName: 'Central Province',
    ),
  ];

  @override
  Future<List<TerritoryModel>> getTerritories() async => territories;
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = MockHttpOverrides();
  });

  Widget createTestWidget({
    required AuthController authController,
    required IssueRepository issueRepository,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<IssueRepository>.value(value: issueRepository),
      ],
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Multi-Step Flow Tests', () {
    testWidgets('Step 1: renders personal details and triggers validation on empty submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo();
      final issueRepo = MockIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: issueRepo,
      ));
      await tester.pumpAndSettle();

      // Step 1 UI checks
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('1 of 5'), findsOneWidget);
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text(AppStrings.emailLabel), findsOneWidget);
      expect(find.text(AppStrings.phoneLabel), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next with empty fields
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email address is required'), findsOneWidget);
    });

    testWidgets('Complete 5-step registration flow with search territory and skip photo', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo();
      final issueRepo = MockIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: issueRepo,
      ));
      await tester.pumpAndSettle();

      // --- STEP 1: Fill details ---
      await tester.enterText(find.widgetWithText(TextFormField, '').first, 'Kasun Perera');
      await tester.enterText(find.byType(TextFormField).at(1), 'kasun@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '0771234567');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // --- STEP 2: Location Selection ---
      expect(find.text('Select your location'), findsOneWidget);
      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);

      // Search and select Balapitiya
      final searchField = find.widgetWithText(TextField, 'Search location or council...');
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Balapitiya');
      await tester.pumpAndSettle();

      expect(find.text('Balapitiya Pradeshiya Sabha'), findsWidgets);
      await tester.tap(find.text('Balapitiya Pradeshiya Sabha').first);
      await tester.pumpAndSettle();

      expect(find.text('Selected Location'), findsOneWidget);

      // Tap Next to proceed to Step 3
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // --- STEP 3: Password ---
      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('3 of 5'), findsOneWidget);

      // Fill matching passwords
      await tester.enterText(find.byType(TextFormField).first, 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // --- STEP 4: Profile Photo ---
      expect(find.text('Add a profile photo'), findsOneWidget);
      expect(find.text('4 of 5'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Tap Skip for now to complete registration
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      // Verify request sent to auth repo
      expect(authRepo.lastRequest, isNotNull);
      expect(authRepo.lastRequest!.fullName, 'Kasun Perera');
      expect(authRepo.lastRequest!.email, 'kasun@example.com');
      expect(authRepo.lastRequest!.registeredTerritoryId, 2);
      expect(authRepo.lastRequest!.password, 'Password123!');

      // --- STEP 5: Registration Complete ---
      expect(find.text("You're all set! 🎉"), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Kasun Perera'), findsOneWidget);
      expect(find.text('kasun@example.com'), findsOneWidget);
      expect(find.text('Balapitiya Pradeshiya Sabha'), findsOneWidget);
    });

    testWidgets('Step 3: Password mismatch validation prevents moving to Step 4', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo();
      final issueRepo = MockIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: issueRepo,
      ));
      await tester.pumpAndSettle();

      // Fill Step 1
      await tester.enterText(find.byType(TextFormField).first, 'Jane Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'jane@example.com');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Select territory in Step 2
      await tester.enterText(find.widgetWithText(TextField, 'Search location or council...'), 'Colombo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colombo Municipal Council').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 3 Password
      expect(find.text('Create a password'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'MismatchPass!');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      // Ensure still on Step 3
      expect(find.text('3 of 5'), findsOneWidget);
    });

    testWidgets('Back button preserves data across steps', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo();
      final issueRepo = MockIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: issueRepo,
      ));
      await tester.pumpAndSettle();

      // Fill Step 1
      await tester.enterText(find.byType(TextFormField).first, 'Preserved Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'preserved@example.com');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Now on Step 2
      expect(find.text('2 of 5'), findsOneWidget);

      // Tap Back button in AppBar
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      // Back on Step 1: verify data preserved
      expect(find.text('1 of 5'), findsOneWidget);
      expect(find.text('Preserved Name'), findsOneWidget);
      expect(find.text('preserved@example.com'), findsOneWidget);
    });

    testWidgets('Step 4: Registration failure displays error banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo()..shouldFail = true;
      final issueRepo = MockIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: issueRepo,
      ));
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextFormField).first, 'Fail User');
      await tester.enterText(find.byType(TextFormField).at(1), 'fail@example.com');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.enterText(find.widgetWithText(TextField, 'Search location or council...'), 'Kandy');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kandy Municipal Council').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Step 3
      await tester.enterText(find.byType(TextFormField).first, 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Stays on Step 4 and displays error
      expect(find.text('4 of 5'), findsOneWidget);
      expect(find.text('Registration failed on server'), findsOneWidget);
    });
  });
}
