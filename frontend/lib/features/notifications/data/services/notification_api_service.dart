import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  final ApiClient apiClient;

  NotificationApiService({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(ApiConstants.notificationsEndpoint);
    if (response is List) {
      return response.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<NotificationModel>> getUnreadNotifications() async {
    final response = await apiClient.get(ApiConstants.unreadNotificationsEndpoint);
    if (response is List) {
      return response.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<NotificationModel> markAsRead(int id) async {
    final response = await apiClient.put(ApiConstants.readNotificationEndpoint(id));
    return NotificationModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> markAllAsRead() async {
    await apiClient.put(ApiConstants.readAllNotificationsEndpoint);
  }
}
