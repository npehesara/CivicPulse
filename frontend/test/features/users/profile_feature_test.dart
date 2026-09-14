import 'dart:typed_data';
import 'package:civicpulse_frontend/core/network/api_exception.dart';
import 'package:civicpulse_frontend/features/authentication/data/models/user_model.dart';
import 'package:civicpulse_frontend/features/authentication/data/repositories/auth_repository.dart';
import 'package:civicpulse_frontend/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:civicpulse_frontend/features/issues/data/models/issue_model.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/repositories/issue_repository.dart';
import 'package:civicpulse_frontend/features/users/data/models/public_user_model.dart';
import 'package:civicpulse_frontend/features/users/data/models/user_profile_model.dart';
import 'package:civicpulse_frontend/features/users/data/repositories/user_repository.dart';
import 'package:civicpulse_frontend/features/users/presentation/controllers/profile_controller.dart';
import 'package:civicpulse_frontend/features/users/presentation/screens/edit_profile_screen.dart';
import 'package:civicpulse_frontend/features/users/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Mocks
class FakeUserRepository implements UserRepository {
  UserProfileModel profile;
  bool shouldFailUpdate = false;
  bool shouldFailUpload = false;

  FakeUserRepository({required this.profile});

  @override
  Future<UserProfileModel> getCurrentUserProfile() async => profile;

  @override
  Future<UserProfileModel> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImage,
    int? registeredTerritoryId,
    int? territoryId,
    double? homeLatitude,
    double? homeLongitude,
  }) async {
    if (shouldFailUpdate) {
      throw ApiException(message: 'Database update failed');
    }
    profile = profile.copyWith(
      fullName: fullName ?? profile.fullName,
      phoneNumber: phoneNumber ?? profile.phoneNumber,
      profileImage: profileImage ?? profile.profileImage,
      territoryId: territoryId ?? registeredTerritoryId ?? profile.territoryId,
      homeLatitude: homeLatitude ?? profile.homeLatitude,
      homeLongitude: homeLongitude ?? profile.homeLongitude,
    );
    return profile;
  }

  @override
  Future<UserProfileModel> uploadProfileImage({
    List<int>? bytes,
    String? filePath,
    required String filename,
  }) async {
    if (shouldFailUpload) {
      throw ApiException(message: 'Upload to Cloudinary rejected');
    }
    profile = profile.copyWith(
      profileImage: 'https://res.cloudinary.com/test/image/upload/v1/civicpulse/profiles/$filename',
    );
    return profile;
  }

  @override
  Future<UserProfileModel> deleteProfileImage() async {
    profile = profile.copyWith(clearProfileImage: true);
    return profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (currentPassword == 'wrong') {
      throw ApiException(message: 'Current password is incorrect');
    }
  }

  @override
  Future<PublicUserModel> getPublicUserProfile(int userId) async => PublicUserModel(
        userId: userId,
        fullName: profile.fullName,
        role: profile.role,
      );

  @override
  Future<List<PublicUserModel>> searchUsers(String query) async => [];
}

class FakeIssueRepository implements IssueRepository {
  final List<IssueModel> issues;
  final List<TerritoryModel> territories;

  FakeIssueRepository({this.issues = const [], this.territories = const []});

  @override
  Future<List<IssueModel>> getIssues({
    int? categoryId,
    int? statusId,
    int? territoryId,
    String? severity,
    String? visibility,
    int? departmentId,
    int? userId,
    String? keyword,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
    String sortDir = 'desc',
  }) async =>
      issues;

  @override
  Future<List<TerritoryModel>> getTerritories() async => territories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  UserModel? user;

  FakeAuthRepository({this.user});

  @override
  Future<bool> isLoggedIn() async => user != null;

  @override
  Future<UserModel> getCurrentUser() async => user!;

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUserRepository fakeUserRepo;
  late FakeIssueRepository fakeIssueRepo;
  late FakeAuthRepository fakeAuthRepo;
  late ProfileController profileController;
  late AuthController authController;

  final sampleProfileWithImage = const UserProfileModel(
    userId: 101,
    fullName: 'Kamal Perera',
    email: 'kamal@civicpulse.org',
    phoneNumber: '0771234567',
    profileImage: 'https://res.cloudinary.com/test/image/upload/v1/civicpulse/profiles/avatar.jpg',
    role: 'CITIZEN',
    accountStatus: 'ACTIVE',
    territoryId: 1,
    territoryName: 'Colombo Municipal Council',
    homeLatitude: 6.9271,
    homeLongitude: 79.8612,
    reportedIssuesCount: 4,
    upvotesGivenCount: 15,
  );

  final sampleProfileNoImage = const UserProfileModel(
    userId: 102,
    fullName: 'Nimal Silva',
    email: 'nimal@civicpulse.org',
    role: 'CITIZEN',
    accountStatus: 'ACTIVE',
    territoryId: 2,
    territoryName: 'Gampaha',
    homeLatitude: 7.0840,
    homeLongitude: 79.9930,
  );

  setUp(() {
    fakeUserRepo = FakeUserRepository(profile: sampleProfileWithImage);
    fakeIssueRepo = FakeIssueRepository(territories: [
      const TerritoryModel(territoryId: 1, territoryName: 'Colombo', regionType: 'DISTRICT'),
      const TerritoryModel(territoryId: 2, territoryName: 'Gampaha', regionType: 'DISTRICT'),
    ]);
    fakeAuthRepo = FakeAuthRepository(
      user: UserModel.fromJson(sampleProfileWithImage.toJson()),
    );
    profileController = ProfileController(
      userRepository: fakeUserRepo,
      issueRepository: fakeIssueRepo,
    );
    authController = AuthController(authRepository: fakeAuthRepo);
  });

  group('Profile Feature Unit & Controller Tests', () {
    test('Profile loads current user and issues', () async {
      await profileController.loadProfile();

      expect(profileController.isLoading, false);
      expect(profileController.errorMessage, null);
      expect(profileController.profile?.userId, 101);
      expect(profileController.profile?.fullName, 'Kamal Perera');
      expect(profileController.profile?.profileImage, contains('cloudinary.com'));
      expect(profileController.profile?.homeLatitude, 6.9271);
      expect(profileController.profile?.homeLongitude, 79.8612);
    });

    test('Successful profile update modifies local state', () async {
      await profileController.loadProfile();

      final success = await profileController.updateProfile(
        fullName: 'Kamal Updated',
        phoneNumber: '0779998888',
        homeLatitude: 6.9300,
        homeLongitude: 79.8600,
        territoryId: 1,
      );

      expect(success, true);
      expect(profileController.profile?.fullName, 'Kamal Updated');
      expect(profileController.profile?.phoneNumber, '0779998888');
      expect(profileController.profile?.homeLatitude, 6.9300);
      expect(profileController.profile?.homeLongitude, 79.8600);
    });

    test('Failed profile update sets error message and preserves profile', () async {
      await profileController.loadProfile();
      fakeUserRepo.shouldFailUpdate = true;

      final success = await profileController.updateProfile(fullName: 'Should Fail');

      expect(success, false);
      expect(profileController.errorMessage, 'Database update failed');
      expect(profileController.profile?.fullName, 'Kamal Perera');
    });

    test('Profile image upload updates Cloudinary URL', () async {
      await profileController.loadProfile();

      final success = await profileController.uploadProfileImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'new_avatar.jpg',
      );

      expect(success, true);
      expect(profileController.profile?.profileImage, contains('new_avatar.jpg'));
    });

    test('Profile image removal clears URL', () async {
      await profileController.loadProfile();

      final success = await profileController.deleteProfileImage();

      expect(success, true);
      expect(profileController.profile?.profileImage, null);
    });

    test('Password change succeeds on valid current password', () async {
      final success = await profileController.changePassword(
        currentPassword: 'correct',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      );

      expect(success, true);
      expect(profileController.errorMessage, null);
    });

    test('Password change captures error on incorrect current password', () async {
      final success = await profileController.changePassword(
        currentPassword: 'wrong',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      );

      expect(success, false);
      expect(profileController.errorMessage, 'Current password is incorrect');
    });
  });

  group('Profile & Edit Profile Widget Tests', () {
    Widget buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ProfileController>.value(value: profileController),
          ChangeNotifierProvider<AuthController>.value(value: authController),
          Provider<IssueRepository>.value(value: fakeIssueRepo),
          Provider<UserRepository>.value(value: fakeUserRepo),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('ProfileScreen renders user details and displays network avatar or placeholder', (tester) async {
      await profileController.loadProfile();

      await tester.pumpWidget(buildTestApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Civic Profile'), findsOneWidget);
      expect(find.text('Kamal Perera'), findsOneWidget);
      expect(find.text('kamal@civicpulse.org'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ProfileScreen renders fallback initials when profileImage is null', (tester) async {
      fakeUserRepo.profile = sampleProfileNoImage;
      await profileController.loadProfile();

      await tester.pumpWidget(buildTestApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nimal Silva'), findsOneWidget);
      // First letter initial 'N'
      expect(find.text('N'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('EditProfileScreen displays read-only email, detected district, and inputs', (tester) async {
      await tester.pumpWidget(buildTestApp(EditProfileScreen(profile: sampleProfileWithImage)));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('kamal@civicpulse.org'), findsOneWidget);
      expect(find.text('Account login email cannot be changed.'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Detected District:'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('EditProfileScreen shows validation error on empty full name', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(EditProfileScreen(profile: sampleProfileWithImage)));
      await tester.pumpAndSettle();

      // Clear full name
      final nameFinder = find.widgetWithText(TextFormField, 'Kamal Perera');
      await tester.enterText(nameFinder, '');

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
    });
  });
}
