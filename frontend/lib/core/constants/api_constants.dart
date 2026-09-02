import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String _customBaseUrl = '';

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:8080';
    }
  }

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  // Auth Endpoints
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';

  // User & Profile Endpoints
  static const String userMeEndpoint = '/api/users/me';
  static String userProfileEndpoint(int id) => '/api/users/$id';
  static const String userSearchEndpoint = '/api/users/search';

  // Issue Endpoints
  static const String issuesEndpoint = '/api/issues';
  static String issueDetailEndpoint(int id) => '/api/issues/$id';

  // Category, Territory, Department, Status
  static const String categoriesEndpoint = '/api/categories';
  static const String statusesEndpoint = '/api/statuses';
  static const String territoriesEndpoint = '/api/territories';
  static const String departmentsEndpoint = '/api/departments';

  // Comments
  static String issueCommentsEndpoint(int issueId) => '/api/issues/$issueId/comments';
  static String deleteCommentEndpoint(int commentId) => '/api/comments/$commentId';

  // Upvotes
  static String issueUpvotesEndpoint(int issueId) => '/api/issues/$issueId/upvotes';
  static String issueUpvoteCountEndpoint(int issueId) => '/api/issues/$issueId/upvotes/count';
  static String issueUpvoteStatusEndpoint(int issueId) => '/api/issues/$issueId/upvotes/me';

  // Images
  static String issueImagesEndpoint(int issueId) => '/api/issues/$issueId/images';
  static String deleteIssueImageEndpoint(int issueId, int imageId) => '/api/issues/$issueId/images/$imageId';

  // Notifications
  static const String notificationsEndpoint = '/api/notifications';
  static const String unreadNotificationsEndpoint = '/api/notifications/unread';
  static String readNotificationEndpoint(int id) => '/api/notifications/$id/read';
  static const String readAllNotificationsEndpoint = '/api/notifications/read-all';

  // Conversations & Messaging
  static const String conversationsEndpoint = '/api/conversations';
  static String conversationMessagesEndpoint(int id) => '/api/conversations/$id/messages';
  static String markConversationReadEndpoint(int id) => '/api/conversations/$id/read';

  // Official & Admin Endpoints
  static String issueModerationEndpoint(int issueId) => '/api/issues/$issueId/moderation';
  static String issueAssignmentsEndpoint(int issueId) => '/api/issues/$issueId/assignments';
  static String issueResolutionEndpoint(int issueId) => '/api/issues/$issueId/resolution';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
