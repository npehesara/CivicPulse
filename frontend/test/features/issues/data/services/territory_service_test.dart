import 'dart:convert';
import 'package:civicpulse_frontend/core/network/api_client.dart';
import 'package:civicpulse_frontend/core/storage/session_manager.dart';
import 'package:civicpulse_frontend/features/issues/data/models/territory_model.dart';
import 'package:civicpulse_frontend/features/issues/data/services/issue_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSessionManager extends Fake implements SessionManager {
  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<bool> hasValidAccessToken({Duration safetyWindow = const Duration(seconds: 60)}) async => false;

  @override
  Future<bool> hasRefreshToken() async => false;
}

void main() {
  group('Territory API & Model Parsing Tests', () {
    test('getTerritories sends unauthenticated GET request and parses territory list', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/territories');
        // Unauthenticated public request should NOT attach Authorization header
        expect(request.headers['Authorization'], isNull);

        return http.Response(
          jsonEncode([
            {
              'territoryId': 1,
              'territoryName': 'Colombo Municipal Council',
              'regionType': 'MUNICIPAL_COUNCIL',
              'parentTerritoryName': 'Western Province',
            },
            {
              'territoryId': 2,
              'territoryName': 'Dehiwala-Mount Lavinia',
              'regionType': 'URBAN_COUNCIL',
              'parentTerritoryName': 'Colombo District',
            },
            {
              'territoryId': 3,
              'territoryName': 'Kandy Municipal Council',
              'regionType': 'MUNICIPAL_COUNCIL',
              'parentTerritoryName': 'Central Province',
            },
          ]),
          200,
        );
      });

      final apiClient = ApiClient(
        client: mockHttpClient,
        sessionManager: FakeSessionManager(),
      );

      final issueApiService = IssueApiService(apiClient: apiClient);
      final territories = await issueApiService.getTerritories();

      expect(territories.length, 3);
      expect(territories[0].territoryId, 1);
      expect(territories[0].territoryName, 'Colombo Municipal Council');
      expect(territories[0].regionType, 'MUNICIPAL_COUNCIL');
      expect(territories[0].parentTerritoryName, 'Western Province');

      expect(territories[2].territoryId, 3);
      expect(territories[2].territoryName, 'Kandy Municipal Council');
    });

    test('TerritoryModel toJson and fromJson round-trip', () {
      const model = TerritoryModel(
        territoryId: 10,
        territoryName: 'Galle Municipal Council',
        regionType: 'MUNICIPAL_COUNCIL',
        parentTerritoryName: 'Southern Province',
      );

      final json = model.toJson();
      final fromJson = TerritoryModel.fromJson(json);

      expect(fromJson.territoryId, 10);
      expect(fromJson.territoryName, 'Galle Municipal Council');
      expect(fromJson.regionType, 'MUNICIPAL_COUNCIL');
      expect(fromJson.parentTerritoryName, 'Southern Province');
    });
  });
}
