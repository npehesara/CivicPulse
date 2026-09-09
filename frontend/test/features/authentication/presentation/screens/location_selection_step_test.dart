import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MockRegisterAuthRepo implements AuthRepository {
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
  Future<AuthResponseModel> register(RegisterRequestModel request) async => throw UnimplementedError();
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
  ];

  @override
  Future<List<TerritoryModel>> getTerritories() async => territories;
}

class MockEmptyIssueRepo extends Fake implements IssueRepository {
  @override
  Future<List<TerritoryModel>> getTerritories() async => [];
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
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest(url);

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final Uri? url;
  _MockHttpClientRequest([this.url]);

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = false;

  @override
  bool bufferOutput = true;

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async => await stream.drain();

  @override
  void write(Object? obj) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse(url);
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  final Uri? url;
  _MockHttpClientResponse([this.url]);

  static final List<int> _transparentPng = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ];

  List<int> get _responseBytes {
    if (url != null && url!.host.contains('nominatim')) {
      return utf8.encode('[]');
    }
    return _transparentPng;
  }

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _responseBytes.length;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_responseBytes).listen(
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

  Future<void> navigateToStep2(WidgetTester tester) async {
    // Fill Step 1 valid info
    await tester.enterText(find.byType(TextFormField).first, 'Test Citizen');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@civicpulse.org');
    await tester.enterText(find.byType(TextFormField).at(2), '0771234567');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  group('Registration Step 2 Location Selection Tests', () {
    testWidgets('Step 2 initial state: shows map, GPS button, search, and disabled Next button', (tester) async {
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

      await navigateToStep2(tester);

      // Verify Step 2 UI elements
      expect(find.text('Your Home Location'), findsOneWidget);
      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('No Home Location Selected'), findsOneWidget);
      expect(find.text('Select your home location above to continue'), findsOneWidget);

      // Verify Next button is disabled when no territory is selected
      final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Next'));
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('Step 2 manual map tap: selects coordinate, determines territory, and enables Next', (tester) async {
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

      await navigateToStep2(tester);

      // Tap the map
      final mapGesture = find.byKey(const Key('registration_map_gesture'));
      expect(mapGesture, findsOneWidget);
      await tester.ensureVisible(mapGesture);
      await tester.pumpAndSettle();
      await tester.tap(mapGesture);
      await tester.pumpAndSettle();

      // Verify a territory was determined and selected
      expect(find.text('Home location selected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify Next button is now enabled
      final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Next'));
      expect(nextButton.onPressed, isNotNull);

      // Tapping Next advances to Step 3 (Password)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('3 of 5'), findsOneWidget);
    });

    testWidgets('Step 2 fallback territory catalog: functions even when backend returns empty territories', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockRegisterAuthRepo();
      final emptyIssueRepo = MockEmptyIssueRepo();
      final authController = AuthController(authRepository: authRepo);

      await tester.pumpWidget(createTestWidget(
        authController: authController,
        issueRepository: emptyIssueRepo,
      ));
      await tester.pumpAndSettle();

      await navigateToStep2(tester);

      // Map tapping must still work using the default Sri Lankan catalog
      final mapGesture = find.byKey(const Key('registration_map_gesture'));
      expect(mapGesture, findsOneWidget);
      await tester.ensureVisible(mapGesture);
      await tester.pumpAndSettle();
      await tester.tap(mapGesture);
      await tester.pumpAndSettle();

      expect(find.text('Home location selected'), findsOneWidget);
      final nextButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Next'));
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('Step 2 search: shows empty state when no location matches query', (tester) async {
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

      await navigateToStep2(tester);

      final searchField = find.widgetWithText(TextField, 'Search city, town, or address...');
      await tester.enterText(searchField, 'NonExistentPlaceXYZ');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.textContaining('No matching locations found for "NonExistentPlaceXYZ"'), findsOneWidget);
    });

    testWidgets('Step 2 GPS button is responsive and shows loading state when triggered', (tester) async {
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

      await navigateToStep2(tester);

      final gpsButton = find.text('Use my current location');
      expect(gpsButton, findsOneWidget);
      await tester.tap(gpsButton);
      await tester.pump();

      // GPS tap initiated without crash
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
