import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../issues/presentation/controllers/issue_controller.dart';
import '../../../issues/presentation/screens/create_issue_screen.dart';
import '../../../issues/presentation/screens/issue_detail_screen.dart';
import '../../../issues/presentation/screens/issue_search_screen.dart';
import '../../../issues/presentation/widgets/issue_card.dart';
import '../../../users/presentation/screens/public_profile_screen.dart';
import '../../../users/presentation/screens/user_search_screen.dart';

/// Redesigned CivicPulse Home/Dashboard Screen.
/// Facebook-style social civic feed, optimized for mobile performance, fast scrolling, and 1-hand reachability.
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

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getFirstName(UserModel? user) {
    if (user?.fullName == null || user!.fullName.trim().isEmpty) {
      return 'Citizen';
    }
    return user.fullName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final issueController = context.watch<IssueController>();
    final currentUser = authController.currentUser;
    final firstName = _getFirstName(currentUser);
    final greeting = _getTimeGreeting();

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: _buildTopAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => issueController.loadFeed(currentUser: currentUser, isRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Personalized Greeting & Quick Search
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $firstName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'What\'s happening in your community?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Modern Tap-to-Search Field
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IssueSearchScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, size: 20, color: AppColors.textMuted),
                            SizedBox(width: 10),
                            Text(
                              'Search issues...',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // + Report an Issue CTA Card
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Report an Issue',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 1, color: AppColors.border),
            ),

            // 2. Feed Filter Navigation Bar (Nearby | Latest | My Territory) + Category Chips
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feed Tabs (Nearby | Latest | My Territory)
                    Row(
                      children: [
                        _buildFilterTab(
                          label: 'Nearby',
                          icon: Icons.near_me_outlined,
                          isSelected: issueController.selectedTab == FeedTab.nearby,
                          onTap: () => _onNearbyTabTapped(context, issueController, currentUser),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'Latest',
                          icon: Icons.access_time,
                          isSelected: issueController.selectedTab == FeedTab.all,
                          onTap: () => issueController.setTab(FeedTab.all, currentUser: currentUser),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'My Territory',
                          icon: Icons.location_city_outlined,
                          isSelected: issueController.selectedTab == FeedTab.territory,
                          onTap: () => issueController.setTab(FeedTab.territory, currentUser: currentUser),
                        ),
                      ],
                    ),

                    // Horizontal Category Chips
                    if (issueController.categories.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip(
                              title: 'All Categories',
                              isSelected: issueController.selectedCategoryId == null,
                              onTap: () => issueController.setCategoryFilter(null, currentUser: currentUser),
                            ),
                            ...issueController.categories.map((cat) {
                              final isSelected = issueController.selectedCategoryId == cat.categoryId;
                              return _buildCategoryChip(
                                title: cat.categoryName,
                                isSelected: isSelected,
                                onTap: () => issueController.setCategoryFilter(
                                  isSelected ? null : cat.categoryId,
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
              child: SizedBox(height: 8),
            ),

            // 3. Feed Body (Loading Skeleton / Error State / Empty State / Issue Cards)
            if (issueController.isLoading && !issueController.isRefreshing)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSkeletonCard(),
                    childCount: 4,
                  ),
                ),
              )
            else if (issueController.errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(context, issueController, currentUser),
              )
            else if (issueController.issues.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final issue = issueController.issues[index];
                      return IssueCard(
                        key: ValueKey(issue.issueId),
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

            // Bottom safe padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 16,
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
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_search_outlined, color: AppColors.textPrimary, size: 22),
          tooltip: 'Search Citizens',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textPrimary, size: 22),
          tooltip: 'Search Issues',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IssueSearchScreen()),
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
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
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nature_people_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No issues nearby yet.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Be the first to report something that needs attention in your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Report an Issue',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    IssueController issueController,
    UserModel? currentUser,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Couldn\'t load issues',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              issueController.errorMessage ?? 'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => issueController.loadFeed(currentUser: currentUser),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNearbyTabTapped(BuildContext context, IssueController issueController, UserModel? currentUser) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services on your device to view nearby issues.'),
              action: SnackBarAction(label: 'Settings', onPressed: Geolocator.openLocationSettings),
            ),
          );
        }
        await issueController.setTab(FeedTab.nearby, currentUser: currentUser);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is needed to show issues near your current location.')),
          );
        }
        await issueController.setTab(FeedTab.nearby, currentUser: currentUser);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 6)),
      );
      issueController.setNearbyCoordinates(position.latitude, position.longitude);
      await issueController.setTab(FeedTab.nearby, currentUser: currentUser);
    } catch (_) {
      await issueController.setTab(FeedTab.nearby, currentUser: currentUser);
    }
  }
}
