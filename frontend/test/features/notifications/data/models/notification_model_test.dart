import 'package:civicpulse_frontend/features/notifications/data/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification Model Tests', () {
    test('NotificationModel should parse from JSON and serialize correctly', () {
      final json = {
        'notificationId': 20,
        'userId': 1,
        'issueId': 101,
        'title': 'Status Updated',
        'message': 'Your issue was marked as IN_PROGRESS.',
        'type': 'STATUS_UPDATED',
        'isRead': false,
        'createdAt': '2026-09-02T04:15:00',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.notificationId, 20);
      expect(notif.issueId, 101);
      expect(notif.type, 'STATUS_UPDATED');
      expect(notif.isRead, false);

      final updated = notif.copyWith(isRead: true);
      expect(updated.isRead, true);
    });
  });
}
