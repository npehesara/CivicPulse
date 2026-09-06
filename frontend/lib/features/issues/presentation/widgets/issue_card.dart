import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/issue_model.dart';
import 'severity_badge.dart';
import 'status_badge.dart';

/// Modern social-media-style civic issue feed card inspired by Facebook usability.
/// High performance, clean visual hierarchy, one-hand friendly interactions.
class IssueCard extends StatefulWidget {
  final IssueModel issue;
  final VoidCallback onTap;
  final VoidCallback? onUpvoteToggle;
  final VoidCallback? onReporterTap;

  const IssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    this.onUpvoteToggle,
    this.onReporterTap,
  });

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final reporterName = issue.userFullName?.trim().isNotEmpty == true
        ? issue.userFullName!.trim()
        : 'Citizen';
    final initial = reporterName.isNotEmpty ? reporterName[0].toUpperCase() : 'C';
    final hasImage = issue.images.isNotEmpty && issue.images.first.imageUrl.trim().isNotEmpty;
    final isLongDescription = issue.description.length > 130;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primaryLight.withValues(alpha: 0.3),
          highlightColor: AppColors.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Post Header: Avatar, Name, Location/Time, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reporter Avatar
                    GestureDetector(
                      onTap: widget.onReporterTap,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Reporter Name & Subtitle Info
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onReporterTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reporterName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (issue.territoryName != null && issue.territoryName!.isNotEmpty) ...[
                                  const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      issue.territoryName!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Text(
                                    ' · ',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                                Text(
                                  DateFormatter.timeAgo(issue.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top-right badges (Status & Private lock)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (issue.visibility == 'PRIVATE') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 11, color: AppColors.textSecondary),
                                SizedBox(width: 2),
                                Text(
                                  'Private',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        StatusBadge(status: issue.statusName ?? 'REPORTED'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Issue Title
                Text(
                  issue.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 5),

                // 3. Description with "See more" expansion
                if (issue.description.isNotEmpty) ...[
                  Text(
                    issue.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  if (isLongDescription) ...[
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Text(
                          _isExpanded ? 'See less' : 'See more...',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],

                // 4. Tags / Category / Transit
                if ((issue.categoryName != null && issue.categoryName!.isNotEmpty) ||
                    issue.isTransitReport ||
                    issue.severity.toUpperCase() == 'HIGH' ||
                    issue.severity.toUpperCase() == 'CRITICAL') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (issue.categoryName != null && issue.categoryName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            issue.categoryName!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (issue.isTransitReport)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_bus_outlined, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Transit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (issue.severity.toUpperCase() == 'HIGH' || issue.severity.toUpperCase() == 'CRITICAL')
                        SeverityBadge(severity: issue.severity),
                    ],
                  ),
                ],

                // 5. Image Preview Container
                if (hasImage) ...[
                  const SizedBox(height: 10),
                  _buildImagePreview(issue.images.first.imageUrl),
                ],

                const SizedBox(height: 10),

                // 6. Social Metrics Row (Likes & Comments counts)
                Row(
                  children: [
                    if (issue.upvoteCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${issue.upvoteCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Be first to upvote',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (issue.commentCount > 0)
                      Text(
                        '${issue.commentCount} ${issue.commentCount == 1 ? "comment" : "comments"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 4),

                // 7. Action Bar: Upvote · Comment · Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Upvote Button
                    Expanded(
                      child: InkWell(
                        onTap: widget.onUpvoteToggle,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                issue.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 18,
                                color: issue.hasUpvoted ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Upvote',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: issue.hasUpvoted ? FontWeight.w700 : FontWeight.w600,
                                  color: issue.hasUpvoted ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Comment Button
                    Expanded(
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Comment',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Details Button
                    Expanded(
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_outward,
                                size: 17,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 220),
            width: double.infinity,
            color: AppColors.surfaceVariant,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackImage(),
            ),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        width: double.infinity,
        color: AppColors.surfaceVariant,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 160,
              alignment: Alignment.center,
              color: AppColors.surfaceVariant,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            );
          },
          errorBuilder: (_, _, _) => _buildFallbackImage(),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 100,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 20),
          SizedBox(width: 6),
          Text(
            'Photo unavailable',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Alias for IssueCard to support clean social feed naming.
typedef IssueFeedCard = IssueCard;
