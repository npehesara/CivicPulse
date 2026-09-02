import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../issues/presentation/screens/issue_detail_screen.dart';
import '../controllers/notification_controller.dart';

class NotificationsTabScreen extends StatefulWidget {
  const NotificationsTabScreen({super.key});

  @override
  State<NotificationsTabScreen> createState() => _NotificationsTabScreenState();
}

class _NotificationsTabScreenState extends State<NotificationsTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().loadNotifications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'ISSUE_CREATED':
        return Icons.add_task;
      case 'STATUS_UPDATED':
        return Icons.published_with_changes;
      case 'ASSIGNMENT_CREATED':
        return Icons.assignment_ind_outlined;
      case 'ISSUE_RESOLVED':
        return Icons.check_circle_outline;
      case 'COMMENT_ADDED':
        return Icons.comment_outlined;
      case 'MESSAGE_RECEIVED':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'ISSUE_RESOLVED':
        return AppColors.success;
      case 'STATUS_UPDATED':
        return AppColors.info;
      case 'ASSIGNMENT_CREATED':
        return AppColors.warning;
      case 'MESSAGE_RECEIVED':
      case 'ISSUE_CREATED':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifController = context.watch<NotificationController>();
    final notifications = notifController.notifications;

    if (notifController.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (notifController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(notifController.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifController.loadNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No notifications yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'You will receive updates about your reported issues and replies here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => notifController.loadNotifications(),
      child: Column(
        children: [
          // Top Mark All As Read Bar
          if (notifController.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notifController.unreadCount} unread',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => notifController.markAllAsRead(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final icon = _getIconForType(notif.type);
                final color = _getColorForType(notif.type);

                return Container(
                  decoration: BoxDecoration(
                    color: notif.isRead ? AppColors.background : const Color(0xFFF0FDFA), // Light teal background for unread
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: notif.isRead ? AppColors.border : AppColors.primaryLight,
                      width: notif.isRead ? 1.0 : 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 3),
                        Text(
                          notif.message,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.timeAgo(notif.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    onTap: () {
                      notifController.markAsRead(notif.notificationId);
                      if (notif.issueId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IssueDetailScreen(issueId: notif.issueId!),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
