import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/public_user_model.dart';
import '../models/user_profile_model.dart';

class UserApiService {
  final ApiClient apiClient;

  UserApiService({required this.apiClient});

  Future<UserProfileModel> getCurrentUserProfile() async {
    final response = await apiClient.get(ApiConstants.userMeEndpoint);
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (profileImage != null) body['profileImage'] = profileImage;
    if (registeredTerritoryId != null) body['registeredTerritoryId'] = registeredTerritoryId;

    final response = await apiClient.put(ApiConstants.userMeEndpoint, body: body);
    return UserProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<PublicUserModel> getPublicUserProfile(int userId) async {
    final response = await apiClient.get(ApiConstants.userProfileEndpoint(userId));
    return PublicUserModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<PublicUserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await apiClient.get(
      ApiConstants.userSearchEndpoint,
      queryParameters: {'query': query.trim()},
    );
    if (response is List) {
      return response.map((e) => PublicUserModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
