import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:civicpulse_frontend/features/home/presentation/screens/home_feed_screen.dart';
import 'package:civicpulse_frontend/features/issues/data/models/category_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/comment_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/department_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_image_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/status_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/repositories/issue_repository.dart';
import 'package:civicpulse_frontend/features/issues/presentation/controllers/issue_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class StubAuthRepo implements AuthRepository {
  final UserModel? user;
  StubAuthRepo({this.user});

  @override
  Future<UserModel?> getCurrentUser() async => user;
  @override
  Future<bool> isLoggedIn() async => user != null;
  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async => AuthResponseModel(
        token: 'token',
        message: 'success',
        user: user ?? UserModel(userId: 1, fullName: 'Test', email: request.email, role: 'CITIZEN', accountStatus: 'ACTIVE'),
      );
  @override
  Future<UserModel> loginWithOAuth() async =>
      user ??
      const UserModel(
        userId: 1,
        fullName: 'Test Citizen',
        email: 'test@example.com',
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      );
  @override
  Future<void> logout() async {}
  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async => AuthResponseModel(
        token: 'token',
        message: 'success',
        user: UserModel(userId: 1, fullName: request.fullName, email: request.email, role: 'CITIZEN', accountStatus: 'ACTIVE'),
      );
}

class StubIssueRepo implements IssueRepository {
  final List<IssueModel> issues;
  final List<CategoryModel> categories;
  StubIssueRepo({this.issues = const [], this.categories = const []});

  @override
  Future<List<IssueModel>> getIssues({
    int? categoryId,
    int? statusId,
    int? territoryId,
    String? severity,
    String? visibility,
    int? departmentId,
    int? userId,
    String? keyword,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async =>
      issues;

  @override
  Future<List<CategoryModel>> getCategories() async => categories;
  @override
  Future<List<TerritoryModel>> getTerritories() async => [];
  @override
  Future<List<DepartmentModel>> getDepartments({int? territoryId}) async => [];
  @override
  Future<List<StatusModel>> getStatuses() async => [];
  @override
  Future<IssueModel> getIssueById(int id) async => issues.firstWhere((i) => i.issueId == id);
  @override
  Future<IssueModel> createIssue(Map<String, dynamic> body) async => throw UnimplementedError();
  @override
  Future<IssueModel> updateIssue(int id, Map<String, dynamic> body) async => throw UnimplementedError();
  @override
  Future<void> deleteIssue(int id) async {}
  @override
  Future<List<CommentModel>> getComments(int issueId) async => [];
  @override
  Future<CommentModel> addComment(int issueId, String text) async => throw UnimplementedError();
  @override
  Future<void> deleteComment(int commentId) async {}
  @override
  Future<void> addUpvote(int issueId) async {}
  @override
  Future<void> removeUpvote(int issueId) async {}
  @override
  Future<bool> getUpvoteStatus(int issueId) async => false;
  @override
  Future<List<IssueImageModel>> getIssueImages(int issueId) async => [];
  @override
  Future<IssueImageModel> addImageToIssue(int issueId, String imageUrl, {String? filename}) async => throw UnimplementedError();
  @override
  Future<void> deleteIssueImage(int issueId, int imageId) async {}
}

Widget buildTestWidget({
  required Widget child,
  UserModel? user,
  List<IssueModel> issues = const [],
  List<CategoryModel> categories = const [],
}) {
  final authRepo = StubAuthRepo(user: user);
  final issueRepo = StubIssueRepo(issues: issues, categories: categories);

  final authController = AuthController(
    authRepository: authRepo,
  );

  final issueController = IssueController(issueRepository: issueRepo);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider<IssueController>.value(value: issueController),
      Provider<IssueRepository>.value(value: issueRepo),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('HomeFeedScreen renders personalized greeting, search, CTA, and filter tabs', (WidgetTester tester) async {
    const user = UserModel(
      userId: 1,
      fullName: 'Navod Pehesara',
      email: 'navod@example.com',
      role: 'CITIZEN',
      accountStatus: 'ACTIVE',
    );

    final authRepo = StubAuthRepo(user: user);
    final issueRepo = StubIssueRepo();
    final authController = AuthController(authRepository: authRepo);
    await authController.checkAuthStatus();
    final issueController = IssueController(issueRepository: issueRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<IssueController>.value(value: issueController),
          Provider<IssueRepository>.value(value: issueRepo),
        ],
        child: const MaterialApp(
          home: HomeFeedScreen(),
        ),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // Verify greeting contains user's first name
    expect(find.textContaining('Navod'), findsOneWidget);
    expect(find.text('What\'s happening in your community?'), findsOneWidget);

    // Verify search issues input
    expect(find.text('Search issues...'), findsOneWidget);

    // Verify Report an Issue button
    expect(find.text('Report an Issue'), findsWidgets);

    // Verify Feed filter tabs
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('My Territory'), findsOneWidget);
  });

  testWidgets('HomeFeedScreen renders empty state when no issues exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: const HomeFeedScreen(),
        issues: const [],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No issues nearby yet.'), findsOneWidget);
    expect(find.textContaining('Be the first to report something'), findsOneWidget);
  });

  testWidgets('HomeFeedScreen renders IssueCard with Facebook style interactions', (WidgetTester tester) async {
    const testIssue = IssueModel(
      issueId: 101,
      title: 'Broken Streetlight',
      description: 'Streetlight near the central bus stand has stopped working.',
      userFullName: 'Kasun Perera',
      territoryName: 'Galle',
      categoryName: 'Electricity',
      createdAt: '2026-09-02T10:00:00',
      updatedAt: '2026-09-02T10:00:00',
      upvoteCount: 14,
      commentCount: 3,
      hasUpvoted: false,
    );

    await tester.pumpWidget(
      buildTestWidget(
        child: const HomeFeedScreen(),
        issues: [testIssue],
      ),
    );

    await tester.pumpAndSettle();

    // Verify issue card elements
    expect(find.text('Broken Streetlight'), findsOneWidget);
    expect(find.text('Kasun Perera'), findsOneWidget);
    expect(find.text('Galle'), findsOneWidget);
    expect(find.text('Upvote'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('3 comments'), findsOneWidget);
  });
}
