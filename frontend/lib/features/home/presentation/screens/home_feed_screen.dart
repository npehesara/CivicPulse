import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../issues/presentation/controllers/issue_controller.dart';
import '../../../issues/presentation/screens/create_issue_screen.dart';
import '../../../issues/presentation/screens/issue_detail_screen.dart';
import '../../../issues/presentation/screens/issue_search_screen.dart';
import '../../../issues/presentation/widgets/issue_card.dart';
import '../../../users/presentation/screens/public_profile_screen.dart';
import '../../../users/presentation/screens/user_search_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<IssueController>().init(auth.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final issueController = context.watch<IssueController>();
    final currentUser = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined, color: AppColors.textPrimary),
            tooltip: 'Search Citizens',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            tooltip: 'Search Issues',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IssueSearchScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => issueController.loadFeed(currentUser: currentUser, isRefresh: true),
        child: CustomScrollView(
          slivers: [
            // Feed Filter & Location Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feed Tabs (All / My Territory / Nearby)
                    Row(
                      children: [
                        _buildTabButton(
                          title: 'All Public Feed',
                          tab: FeedTab.all,
                          currentTab: issueController.selectedTab,
                          onTap: () => issueController.setTab(FeedTab.all, currentUser: currentUser),
                        ),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          title: 'My Territory',
                          tab: FeedTab.territory,
                          currentTab: issueController.selectedTab,
                          onTap: () => issueController.setTab(FeedTab.territory, currentUser: currentUser),
                        ),
                        const SizedBox(width: 8),
                        _buildTabButton(
                          title: 'Nearby',
                          tab: FeedTab.nearby,
                          currentTab: issueController.selectedTab,
                          onTap: () => issueController.setTab(FeedTab.nearby, currentUser: currentUser),
                        ),
                      ],
                    ),

                    if (issueController.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // Category Filter Horizontal Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip(
                              title: 'All Categories',
                              isSelected: issueController.selectedCategoryId == null,
                              onTap: () => issueController.setCategoryFilter(null, currentUser: currentUser),
                            ),
                            ...issueController.categories.map((c) {
                              final isSelected = issueController.selectedCategoryId == c.categoryId;
                              return _buildCategoryChip(
                                title: c.categoryName,
                                isSelected: isSelected,
                                onTap: () => issueController.setCategoryFilter(
                                  isSelected ? null : c.categoryId,
                                  currentUser: currentUser,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 1, color: AppColors.border),
            ),

            // Issues Feed List
            if (issueController.isLoading && !issueController.isRefreshing)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (issueController.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          issueController.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => issueController.loadFeed(currentUser: currentUser),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (issueController.issues.isEmpty)
              SliverFillRemaining(
                child: Center(
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
                          child: const Icon(Icons.campaign_outlined, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No civic issues found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Be the first to report an issue in this area and improve your community!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final issue = issueController.issues[index];
                      return IssueCard(
                        issue: issue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IssueDetailScreen(issueId: issue.issueId),
                            ),
                          );
                        },
                        onUpvoteToggle: () => issueController.toggleUpvote(issue),
                        onReporterTap: () {
                          if (issue.userId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: issue.userId!),
                              ),
                            );
                          }
                        },
                      );
                    },
                    childCount: issueController.issues.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required FeedTab tab,
    required FeedTab currentTab,
    required VoidCallback onTap,
  }) {
    final isSelected = tab == currentTab;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
