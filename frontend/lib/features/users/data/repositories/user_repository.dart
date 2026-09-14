import '../models/public_user_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_api_service.dart';

abstract class UserRepository {
  Future<UserProfileModel> getCurrentUserProfile();
  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
    int? territoryId,
    double? homeLatitude,
    double? homeLongitude,
  });
  Future<UserProfileModel> uploadProfileImage({
    List<int>? bytes,
    String? filePath,
    required String filename,
  });
  Future<UserProfileModel> deleteProfileImage();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  });
  Future<PublicUserModel> getPublicUserProfile(int userId);
  Future<List<PublicUserModel>> searchUsers(String query);
}

class UserRepositoryImpl implements UserRepository {
  final UserApiService apiService;

  UserRepositoryImpl({required this.apiService});

  @override
  Future<UserProfileModel> getCurrentUserProfile() => apiService.getCurrentUserProfile();

  @override
  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
    int? territoryId,
    double? homeLatitude,
    double? homeLongitude,
  }) =>
      apiService.updateCurrentUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        registeredTerritoryId: registeredTerritoryId,
        territoryId: territoryId,
        homeLatitude: homeLatitude,
        homeLongitude: homeLongitude,
      );

  @override
  Future<UserProfileModel> uploadProfileImage({
    List<int>? bytes,
    String? filePath,
    required String filename,
  }) =>
      apiService.uploadProfileImage(
        bytes: bytes,
        filePath: filePath,
        filename: filename,
      );

  @override
  Future<UserProfileModel> deleteProfileImage() => apiService.deleteProfileImage();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) =>
      apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  @override
  Future<PublicUserModel> getPublicUserProfile(int userId) => apiService.getPublicUserProfile(userId);

  @override
  Future<List<PublicUserModel>> searchUsers(String query) => apiService.searchUsers(query);
}
