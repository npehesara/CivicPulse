import 'package:flutter/material.dart';
import '../../../../core/network/api_exception.dart';
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

  void setProfile(UserProfileModel profile) {
    _profile = profile;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Failed to load profile details.';
      }
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
    int? territoryId,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    _errorMessage = null;
    try {
      final updated = await userRepository.updateCurrentUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        registeredTerritoryId: registeredTerritoryId,
        territoryId: territoryId,
        homeLatitude: homeLatitude,
        homeLongitude: homeLongitude,
      );
      _profile = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage({
    List<int>? bytes,
    String? filePath,
    required String filename,
  }) async {
    _errorMessage = null;
    try {
      final updated = await userRepository.uploadProfileImage(
        bytes: bytes,
        filePath: filePath,
        filename: filename,
      );
      _profile = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload profile image: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfileImage() async {
    _errorMessage = null;
    try {
      final updated = await userRepository.deleteProfileImage();
      _profile = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to remove profile picture: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    _errorMessage = null;
    try {
      await userRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to change password: $e';
      notifyListeners();
      return false;
    }
  }
}
