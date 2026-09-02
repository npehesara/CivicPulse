import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/category_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/comment_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/department_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_image_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/status_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/repositories/issue_repository.dart';
import 'package:civicpulse_frontend/features/issues/presentation/controllers/issue_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class StubIssueRepository implements IssueRepository {
  final List<IssueModel> stubIssues;
  StubIssueRepository({this.stubIssues = const []});

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
  }) async {
    return stubIssues;
  }

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

void main() {
  group('IssueController Tests', () {
    test('loadFeed should populate issues list successfully', () async {
      final sampleIssues = [
        const IssueModel(
          issueId: 1,
          title: 'Streetlight out',
          description: 'Dark corner at night',
          createdAt: '2026-09-02T01:00:00',
          updatedAt: '2026-09-02T01:00:00',
        ),
      ];

      final repo = StubIssueRepository(stubIssues: sampleIssues);
      final controller = IssueController(issueRepository: repo);

      expect(controller.issues, isEmpty);
      await controller.loadFeed(
        currentUser: const UserModel(
          userId: 1,
          fullName: 'Test Citizen',
          email: 'citizen@example.com',
          role: 'CITIZEN',
          accountStatus: 'ACTIVE',
        ),
      );

      expect(controller.issues.length, 1);
      expect(controller.issues.first.title, 'Streetlight out');
      expect(controller.errorMessage, isNull);
    });

    test('toggleUpvote should update local upvote count and status', () async {
      const issue = IssueModel(
        issueId: 1,
        title: 'Water leak',
        description: 'Pipe leaking',
        upvoteCount: 5,
        hasUpvoted: false,
        createdAt: '2026-09-02T01:00:00',
        updatedAt: '2026-09-02T01:00:00',
      );

      final repo = StubIssueRepository(stubIssues: [issue]);
      final controller = IssueController(issueRepository: repo);
      await controller.loadFeed();

      expect(controller.issues.first.upvoteCount, 5);
      expect(controller.issues.first.hasUpvoted, false);

      await controller.toggleUpvote(controller.issues.first);

      expect(controller.issues.first.upvoteCount, 6);
      expect(controller.issues.first.hasUpvoted, true);
    });
  });
}
