import 'package:civicpulse_frontend/features/users/data/models/public_user_model.dart';
import 'package:civicpulse_frontend/features/users/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Profile Models Tests', () {
    test('UserProfileModel should parse from JSON and serialize correctly', () {
      final json = {
        'userId': 12,
        'fullName': 'Anura Silva',
        'email': 'anura@example.com',
        'phoneNumber': '0779988776',
        'profileImage': 'https://example.com/avatar.png',
        'role': 'OFFICIAL',
        'accountStatus': 'ACTIVE',
        'registeredTerritoryId': 3,
        'registeredTerritoryName': 'Galle Municipal Council',
        'createdAt': '2026-09-02T02:00:00',
        'reportedIssuesCount': 8,
        'upvotesGivenCount': 19,
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.userId, 12);
      expect(profile.fullName, 'Anura Silva');
      expect(profile.role, 'OFFICIAL');
      expect(profile.reportedIssuesCount, 8);
      expect(profile.upvotesGivenCount, 19);

      final map = profile.toJson();
      expect(map['email'], 'anura@example.com');
      expect(map['registeredTerritoryId'], 3);
    });

    test('PublicUserModel should parse from JSON and not include private contact info', () {
      final json = {
        'userId': 12,
        'fullName': 'Anura Silva',
        'profileImage': 'https://example.com/avatar.png',
        'role': 'OFFICIAL',
        'registeredTerritoryId': 3,
        'registeredTerritoryName': 'Galle Municipal Council',
        'createdAt': '2026-09-02T02:00:00',
        'publicIssuesCount': 8,
      };

      final publicUser = PublicUserModel.fromJson(json);

      expect(publicUser.userId, 12);
      expect(publicUser.fullName, 'Anura Silva');
      expect(publicUser.publicIssuesCount, 8);

      final map = publicUser.toJson();
      expect(map.containsKey('email'), false);
      expect(map.containsKey('phoneNumber'), false);
    });
  });
}
