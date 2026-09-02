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
  }) =>
      apiService.updateCurrentUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        registeredTerritoryId: registeredTerritoryId,
      );

  @override
  Future<PublicUserModel> getPublicUserProfile(int userId) => apiService.getPublicUserProfile(userId);

  @override
  Future<List<PublicUserModel>> searchUsers(String query) => apiService.searchUsers(query);
}
