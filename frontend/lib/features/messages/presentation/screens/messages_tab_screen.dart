import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../users/presentation/screens/user_search_screen.dart';
import '../controllers/message_controller.dart';
import 'chat_screen.dart';

class MessagesTabScreen extends StatefulWidget {
  const MessagesTabScreen({super.key});

  @override
  State<MessagesTabScreen> createState() => _MessagesTabScreenState();
}

class _MessagesTabScreenState extends State<MessagesTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageController>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageController = context.watch<MessageController>();
    final conversations = messageController.conversations;

    if (messageController.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (messageController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(messageController.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => messageController.loadConversations(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No conversations yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connect directly with officials and citizens regarding civic issues.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                label: const Text('Start New Conversation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => messageController.loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final title = conv.title;
          final hasUnread = conv.unreadCount > 0;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasUnread ? AppColors.primaryLight : AppColors.border,
                width: hasUnread ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: hasUnread ? AppColors.primary : AppColors.primaryLight,
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: hasUnread ? Colors.white : AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (conv.lastMessageAt != null)
                    Text(
                      DateFormatter.timeAgo(conv.lastMessageAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread ? AppColors.primary : AppColors.textMuted,
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      conv.lastMessageText ?? 'Conversation started',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conv.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
