import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../issues/data/models/issue_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../../../issues/presentation/screens/issue_detail_screen.dart';
import '../../../issues/presentation/widgets/issue_card.dart';
import '../../../messages/data/repositories/message_repository.dart';
import '../../../messages/presentation/screens/chat_screen.dart';
import '../../data/models/public_user_model.dart';
import '../../data/repositories/user_repository.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  PublicUserModel? _user;
  List<IssueModel> _publicIssues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userRepo = context.read<UserRepository>();
      final issueRepo = context.read<IssueRepository>();

      final u = await userRepo.getPublicUserProfile(widget.userId);
      final issues = await issueRepo.getIssues(userId: widget.userId, visibility: 'PUBLIC', size: 50);

      if (mounted) {
        setState(() {
          _user = u;
          _publicIssues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load citizen profile.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    if (_user == null) return;
    try {
      final msgRepo = context.read<MessageRepository>();
      final conv = await msgRepo.createOrGetConversation(widget.userId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conv),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _user?.fullName ?? 'Citizen Profile',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(child: Text('User not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Public Profile Card
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDark,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                    gradient: LinearGradient(
                                      colors: [AppColors.primaryDark, AppColors.primaryHover],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Transform.translate(
                                    offset: const Offset(0, -32),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: AppColors.background,
                                          child: CircleAvatar(
                                            radius: 32,
                                            backgroundColor: AppColors.primaryLight,
                                            child: Text(
                                              _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'C',
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _user!.fullName,
                                          style: const TextStyle(
                                            fontSize: 18,
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
                                            _user!.role,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        if (_user!.registeredTerritoryName != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                _user!.registeredTerritoryName!,
                                                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 16),

                                        // Start Message button
                                        ElevatedButton.icon(
                                          onPressed: _startChat,
                                          icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                                          label: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Public Issues Section
                          Text(
                            'Public Issues Reported (${_publicIssues.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_publicIssues.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Text('No public issues reported yet.', style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _publicIssues.length,
                              itemBuilder: (context, index) {
                                final issue = _publicIssues[index];
                                return IssueCard(
                                  issue: issue,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => IssueDetailScreen(issueId: issue.issueId)),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
    );
  }
}
