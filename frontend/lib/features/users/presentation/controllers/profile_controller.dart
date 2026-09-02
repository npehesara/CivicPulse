import 'package:flutter/material.dart';
import '../../../issues/data/models/issue_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_repository.dart';

class ProfileController extends ChangeNotifier {
  final UserRepository userRepository;
  final IssueRepository issueRepository;

  ProfileController({
    required this.userRepository,
    required this.issueRepository,
  });

  UserProfileModel? _profile;
  List<IssueModel> _myIssues = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  List<IssueModel> get myIssues => _myIssues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProfile = await userRepository.getCurrentUserProfile();
      _profile = userProfile;

      final issues = await issueRepository.getIssues(
        userId: userProfile.userId,
        size: 50,
      );
      _myIssues = issues;
    } catch (e) {
      _errorMessage = 'Failed to load profile details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
  }) async {
    try {
      final updated = await userRepository.updateCurrentUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        registeredTerritoryId: registeredTerritoryId,
      );
      _profile = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
