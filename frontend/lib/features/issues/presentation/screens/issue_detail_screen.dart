import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../users/presentation/screens/public_profile_screen.dart';
import '../../data/repositories/issue_repository.dart';
import '../controllers/issue_controller.dart';
import '../controllers/issue_detail_controller.dart';
import '../widgets/severity_badge.dart';
import '../widgets/status_badge.dart';

class IssueDetailScreen extends StatefulWidget {
  final int issueId;

  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late IssueDetailController _controller;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = IssueDetailController(
      issueRepository: context.read<IssueRepository>(),
      issueId: widget.issueId,
    );
    _controller.loadDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await _controller.addComment(text);
    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Issue?'),
        content: const Text('Are you sure you want to delete this issue? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await _controller.deleteIssue();
              if (success && mounted) {
                context.read<IssueController>().loadFeed(isRefresh: true);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Issue deleted successfully.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthController>().currentUser?.userId;
    final currentUserRole = context.watch<AuthController>().currentUser?.role ?? 'CITIZEN';

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<IssueDetailController>(
        builder: (context, controller, _) {
          final issue = controller.issue;

          return Scaffold(
            backgroundColor: AppColors.surfaceVariant,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: const Text(
                'Issue Details',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (issue != null && (currentUserId == issue.userId || currentUserRole == 'ADMIN'))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Issue',
                    onPressed: _confirmDelete,
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : controller.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(controller.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: () => controller.loadDetails(), child: const Text('Retry')),
                          ],
                        ),
                      )
                    : issue == null
                        ? const Center(child: Text('Issue not found'))
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Main Issue Card
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Reporter Info
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    if (issue.userId != null) {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) => PublicProfileScreen(userId: issue.userId!),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor: AppColors.primaryLight,
                                                    child: Text(
                                                      issue.userFullName?.isNotEmpty == true
                                                          ? issue.userFullName![0].toUpperCase()
                                                          : 'C',
                                                      style: const TextStyle(
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (issue.userId != null) {
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) => PublicProfileScreen(userId: issue.userId!),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          issue.userFullName ?? 'Citizen',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 15,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          DateFormatter.fullDateTime(issue.createdAt),
                                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (issue.visibility == 'PRIVATE')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(Icons.lock, size: 12, color: AppColors.textSecondary),
                                                        SizedBox(width: 4),
                                                        Text('Private', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            const SizedBox(height: 16),

                                            // Title
                                            Text(
                                              issue.title,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            // Description
                                            Text(
                                              issue.description,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.textSecondary,
                                                height: 1.5,
                                              ),
                                            ),

                                            // Image Gallery (if any)
                                            if (issue.images.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              ...issue.images.map((img) => Container(
                                                    margin: const EdgeInsets.only(bottom: 10),
                                                    child: _buildDetailImage(img.imageUrl),
                                                  )),
                                            ],

                                            const SizedBox(height: 16),

                                            // Badges and Meta
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                if (issue.categoryName != null)
                                                  Chip(
                                                    label: Text(issue.categoryName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                    backgroundColor: AppColors.surfaceVariant,
                                                    side: const BorderSide(color: AppColors.border),
                                                  ),
                                                SeverityBadge(severity: issue.severity),
                                                StatusBadge(status: issue.statusName ?? 'REPORTED'),
                                                if (issue.territoryName != null)
                                                  Chip(
                                                    avatar: const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                                    label: Text(issue.territoryName!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                                    backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                                                    side: BorderSide.none,
                                                  ),
                                                if (issue.departmentName != null)
                                                  Chip(
                                                    avatar: const Icon(Icons.business_outlined, size: 14, color: AppColors.textSecondary),
                                                    label: Text(issue.departmentName!, style: const TextStyle(fontSize: 12)),
                                                    backgroundColor: AppColors.surfaceVariant,
                                                    side: const BorderSide(color: AppColors.border),
                                                  ),
                                              ],
                                            ),

                                            if (issue.latitude != null && issue.longitude != null) ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.gps_fixed, size: 14, color: AppColors.textMuted),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${issue.latitude!.toStringAsFixed(4)}, ${issue.longitude!.toStringAsFixed(4)}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                  ),
                                                ],
                                              ),
                                            ],

                                            const SizedBox(height: 16),
                                            const Divider(color: AppColors.divider),
                                            const SizedBox(height: 8),

                                            // Upvote Action Row
                                            Row(
                                              children: [
                                                InkWell(
                                                  onTap: () => controller.toggleUpvote(),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: issue.hasUpvoted ? AppColors.primaryLight : AppColors.surfaceVariant,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: issue.hasUpvoted ? AppColors.primary : AppColors.border),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          issue.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                          size: 18,
                                                          color: issue.hasUpvoted ? AppColors.primary : AppColors.textSecondary,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '${issue.upvoteCount} Upvotes',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                            color: issue.hasUpvoted ? AppColors.primary : AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '${issue.commentCount} Comments',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Discussion / Comments Section
                                      const Text(
                                        'Civic Discussion',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      if (controller.comments.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'No comments yet. Be the first to join the conversation!',
                                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                            ),
                                          ),
                                        )
                                      else
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: controller.comments.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final comment = controller.comments[index];
                                            final isMyComment = currentUserId != null && currentUserId == comment.userId;

                                            return Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: comment.isOfficial ? AppColors.primaryHover.withOpacity(0.5) : AppColors.border,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 14,
                                                        backgroundColor: comment.isOfficial ? AppColors.primary : AppColors.primaryLight,
                                                        child: Text(
                                                          comment.userFullName.isNotEmpty ? comment.userFullName[0].toUpperCase() : 'C',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: comment.isOfficial ? Colors.white : AppColors.primary,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        comment.userFullName,
                                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                                      ),
                                                      if (comment.isOfficial) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primaryLight,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: const Text('Official', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                                        ),
                                                      ],
                                                      const Spacer(),
                                                      Text(
                                                        DateFormatter.timeAgo(comment.createdAt),
                                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                      ),
                                                      if (isMyComment)
                                                        IconButton(
                                                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                          onPressed: () => controller.deleteComment(comment.commentId),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    comment.commentText,
                                                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Bottom Comment Input Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: AppColors.background,
                                  border: Border(top: BorderSide(color: AppColors.border)),
                                ),
                                child: SafeArea(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Write a civic comment or update...',
                                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                            filled: true,
                                            fillColor: AppColors.surfaceVariant,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                          ),
                                          maxLines: null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      controller.isSubmittingComment
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                          : IconButton(
                                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                                              onPressed: _submitComment,
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
          );
        },
      ),
    );
  }

  Widget _buildDetailImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
