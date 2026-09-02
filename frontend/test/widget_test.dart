import 'package:civicpulse_frontend/core/network/api_client.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/auth_response_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/login_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/register_request_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/issues/data/models/category_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/comment_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/department_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_image_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/status_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/repositories/issue_repository.dart';
import 'package:civicpulse_frontend/features/messages/data/models/conversation_model.dart';
import 'package:civicpulse_frontend/features/messages/data/models/message_model.dart';
import 'package:civicpulse_frontend/features/messages/data/repositories/message_repository.dart';
import 'package:civicpulse_frontend/features/notifications/data/models/notification_model.dart';
import 'package:civicpulse_frontend/features/notifications/data/repositories/notification_repository.dart';
import 'package:civicpulse_frontend/features/users/data/models/public_user_model.dart';
import 'package:civicpulse_frontend/features/users/data/models/user_profile_model.dart';
import 'package:civicpulse_frontend/features/users/data/repositories/user_repository.dart';
import 'package:civicpulse_frontend/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class MockAuthRepository implements AuthRepository {
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

class MockIssueRepository implements IssueRepository {
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
  }) async => [];

  @override
  Future<IssueModel> getIssueById(int id) async => const IssueModel(
        issueId: 1,
        title: 'Mock Issue',
        description: 'Mock Description',
        createdAt: '2026-09-02T00:00:00',
        updatedAt: '2026-09-02T00:00:00',
      );

  @override
  Future<IssueModel> createIssue(Map<String, dynamic> body) async => const IssueModel(
        issueId: 1,
        title: 'Mock Issue',
        description: 'Mock Description',
        createdAt: '2026-09-02T00:00:00',
        updatedAt: '2026-09-02T00:00:00',
      );

  @override
  Future<IssueModel> updateIssue(int id, Map<String, dynamic> body) async => const IssueModel(
        issueId: 1,
        title: 'Mock Issue',
        description: 'Mock Description',
        createdAt: '2026-09-02T00:00:00',
        updatedAt: '2026-09-02T00:00:00',
      );

  @override
  Future<void> deleteIssue(int id) async {}
  @override
  Future<List<CategoryModel>> getCategories() async => [];
  @override
  Future<List<TerritoryModel>> getTerritories() async => [];
  @override
  Future<List<DepartmentModel>> getDepartments({int? territoryId}) async => [];
  @override
  Future<List<StatusModel>> getStatuses() async => [];
  @override
  Future<List<CommentModel>> getComments(int issueId) async => [];
  @override
  Future<CommentModel> addComment(int issueId, String text) async => CommentModel(
        commentId: 1,
        issueId: issueId,
        userId: 1,
        userFullName: 'Test',
        commentText: text,
        createdAt: '2026-09-02T00:00:00',
      );
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
  Future<IssueImageModel> addImageToIssue(int issueId, String imageUrl, {String? filename}) async => IssueImageModel(
        imageId: 1,
        imageUrl: imageUrl,
      );
  @override
  Future<void> deleteIssueImage(int issueId, int imageId) async {}
}

class MockUserRepository implements UserRepository {
  @override
  Future<UserProfileModel> getCurrentUserProfile() async => const UserProfileModel(
        userId: 1,
        fullName: 'Test Citizen',
        email: 'test@example.com',
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      );

  @override
  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
  }) async =>
      const UserProfileModel(
        userId: 1,
        fullName: 'Test Citizen',
        email: 'test@example.com',
        role: 'CITIZEN',
        accountStatus: 'ACTIVE',
      );

  @override
  Future<PublicUserModel> getPublicUserProfile(int userId) async => const PublicUserModel(
        userId: 1,
        fullName: 'Test Citizen',
        role: 'CITIZEN',
      );

  @override
  Future<List<PublicUserModel>> searchUsers(String query) async => [];
}

class MockMessageRepository implements MessageRepository {
  @override
  Future<List<ConversationModel>> getUserConversations() async => [];
  @override
  Future<ConversationModel> createOrGetConversation(int recipientUserId, {String? initialMessage}) async => const ConversationModel(
        conversationId: 1,
        title: 'Chat',
      );
  @override
  Future<List<MessageModel>> getConversationMessages(int conversationId) async => [];
  @override
  Future<MessageModel> sendMessage(int conversationId, String content) async => MessageModel(
        messageId: 1,
        conversationId: conversationId,
        senderId: 1,
        senderName: 'Test',
        content: content,
        sentAt: '2026-09-02T00:00:00',
      );
  @override
  Future<void> markConversationAsRead(int conversationId) async {}
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications() async => [];
  @override
  Future<List<NotificationModel>> getUnreadNotifications() async => [];
  @override
  Future<NotificationModel> markAsRead(int id) async => NotificationModel(
        notificationId: id,
        userId: 1,
        title: 'Title',
        message: 'Msg',
        type: 'ISSUE_CREATED',
        createdAt: '2026-09-02T00:00:00',
      );
  @override
  Future<void> markAllAsRead() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App should build and render SplashScreen initially', (WidgetTester tester) async {
    final sessionManager = SessionManager();
    final apiClient = ApiClient(sessionManager: sessionManager);
    final authRepo = MockAuthRepository();
    final issueRepo = MockIssueRepository();
    final userRepo = MockUserRepository();
    final messageRepo = MockMessageRepository();
    final notifRepo = MockNotificationRepository();

    await tester.pumpWidget(
      CivicPulseApp(
        authRepository: authRepo,
        issueRepository: issueRepo,
        userRepository: userRepo,
        messageRepository: messageRepo,
        notificationRepository: notifRepo,
        apiClient: apiClient,
        sessionManager: sessionManager,
      ),
    );

    expect(find.byType(CivicPulseApp), findsOneWidget);

    // Complete splash screen delay and timers
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });
}
