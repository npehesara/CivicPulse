import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../issues/presentation/screens/create_issue_screen.dart';
import '../../../issues/presentation/screens/issue_detail_screen.dart';
import '../../../issues/presentation/widgets/issue_card.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_screen.dart';
import 'user_search_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final authController = context.watch<AuthController>();
    final profile = profileController.profile;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Civic Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined, color: AppColors.textPrimary),
            tooltip: 'Search Users',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileController.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : profileController.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(profileController.errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => profileController.loadProfile(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : profile == null
                  ? const Center(child: Text('Profile not available'))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => profileController.loadProfile(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Facebook-style Profile Header Card
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  // Cover Banner
                                  Container(
                                    height: 90,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                      gradient: LinearGradient(
                                        colors: [AppColors.primaryDark, AppColors.primaryHover],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),

                                  // Avatar & Main Info
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Transform.translate(
                                      offset: const Offset(0, -36),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundColor: AppColors.background,
                                            child: CircleAvatar(
                                              radius: 36,
                                              backgroundColor: AppColors.primaryLight,
                                              child: Text(
                                                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'C',
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            profile.fullName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              profile.role,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Stats Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildStat(
                                                count: '${profile.reportedIssuesCount}',
                                                label: 'Reported Issues',
                                                icon: Icons.campaign_outlined,
                                              ),
                                              Container(width: 1, height: 36, color: AppColors.border),
                                              _buildStat(
                                                count: '${profile.upvotesGivenCount}',
                                                label: 'Upvotes',
                                                icon: Icons.thumb_up_alt_outlined,
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),
                                          const Divider(color: AppColors.divider),
                                          const SizedBox(height: 12),

                                          // Contact & Territory Info
                                          _buildInfoRow(Icons.email_outlined, profile.email),
                                          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.phone_outlined, profile.phoneNumber!),
                                          ],
                                          if (profile.registeredTerritoryName != null) ...[
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.location_on_outlined, profile.registeredTerritoryName!),
                                          ],

                                          const SizedBox(height: 16),

                                          // Edit Profile Button
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    final updated = await Navigator.of(context).push<bool>(
                                                      MaterialPageRoute(
                                                        builder: (_) => EditProfileScreen(profile: profile),
                                                      ),
                                                    );
                                                    if (updated == true) {
                                                      profileController.loadProfile();
                                                    }
                                                  },
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                                  label: const Text('Edit Profile', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    side: const BorderSide(color: AppColors.primary),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                                                  label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // My Issue Posts Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'My Reported Issues',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${profileController.myIssues.length} posts',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (profileController.myIssues.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 42, color: AppColors.textMuted),
                                      SizedBox(height: 8),
                                      Text(
                                        'You have not submitted any civic issues yet.',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: profileController.myIssues.length,
                                itemBuilder: (context, index) {
                                  final issue = profileController.myIssues[index];
                                  return IssueCard(
                                    issue: issue,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => IssueDetailScreen(issueId: issue.issueId),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStat({required String count, required String label, required IconData icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
