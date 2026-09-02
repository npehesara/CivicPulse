import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<List<NotificationModel>> getUnreadNotifications();
  Future<NotificationModel> markAsRead(int id);
  Future<void> markAllAsRead();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService apiService;

  NotificationRepositoryImpl({required this.apiService});

  @override
  Future<List<NotificationModel>> getNotifications() => apiService.getNotifications();

  @override
  Future<List<NotificationModel>> getUnreadNotifications() => apiService.getUnreadNotifications();

  @override
  Future<NotificationModel> markAsRead(int id) => apiService.markAsRead(id);

  @override
  Future<void> markAllAsRead() => apiService.markAllAsRead();
}
