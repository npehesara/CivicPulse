import 'package:civicpulse_frontend/features/issues/data/models/category_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/comment_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/status_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue Model Tests', () {
    test('IssueModel should correctly parse from JSON and serialize to JSON', () {
      final json = {
        'issueId': 101,
        'title': 'Damaged bridge railing',
        'description': 'Bridge railing near town hall is collapsed.',
        'latitude': 6.9271,
        'longitude': 79.8612,
        'locationPoint': 'POINT(79.8612 6.9271)',
        'visibility': 'PUBLIC',
        'severity': 'HIGH',
        'isTransitReport': true,
        'createdAt': '2026-09-02T04:00:00',
        'updatedAt': '2026-09-02T04:30:00',
        'userId': 5,
        'userFullName': 'Kamal Perera',
        'userEmail': 'kamal@example.com',
        'categoryId': 2,
        'categoryName': 'Bridges & Roads',
        'territoryId': 1,
        'territoryName': 'Colombo Municipal Council',
        'departmentId': 3,
        'departmentName': 'Civil Works Department',
        'statusId': 1,
        'statusName': 'REPORTED',
        'upvoteCount': 12,
        'commentCount': 3,
        'hasUpvoted': true,
        'images': [
          {
            'imageId': 1,
            'imageUrl': 'https://example.com/bridge.jpg',
            'originalFilename': 'bridge.jpg',
            'aiSafetyScore': 0.99,
            'aiRelevanceScore': 0.95,
            'isAnonymized': false,
            'uploadedAt': '2026-09-02T04:05:00',
          }
        ],
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.issueId, 101);
      expect(issue.title, 'Damaged bridge railing');
      expect(issue.severity, 'HIGH');
      expect(issue.visibility, 'PUBLIC');
      expect(issue.isTransitReport, true);
      expect(issue.upvoteCount, 12);
      expect(issue.commentCount, 3);
      expect(issue.hasUpvoted, true);
      expect(issue.images.length, 1);
      expect(issue.images.first.imageUrl, 'https://example.com/bridge.jpg');

      final serialized = issue.toJson();
      expect(serialized['issueId'], 101);
      expect(serialized['title'], 'Damaged bridge railing');
    });

    test('CategoryModel, TerritoryModel, StatusModel, CommentModel parsing', () {
      final cat = CategoryModel.fromJson({'categoryId': 1, 'categoryName': 'Water'});
      expect(cat.categoryId, 1);
      expect(cat.categoryName, 'Water');

      final terr = TerritoryModel.fromJson({'territoryId': 2, 'territoryName': 'Kandy'});
      expect(terr.territoryId, 2);
      expect(terr.territoryName, 'Kandy');

      final status = StatusModel.fromJson({'statusId': 3, 'statusName': 'IN_PROGRESS'});
      expect(status.statusId, 3);
      expect(status.statusName, 'IN_PROGRESS');

      final comment = CommentModel.fromJson({
        'commentId': 10,
        'issueId': 101,
        'userId': 2,
        'userFullName': 'Officer John',
        'commentText': 'Inspection scheduled for tomorrow.',
        'createdAt': '2026-09-02T05:00:00',
        'isOfficial': true,
      });
      expect(comment.commentId, 10);
      expect(comment.isOfficial, true);
      expect(comment.commentText, 'Inspection scheduled for tomorrow.');
    });
  });
}
