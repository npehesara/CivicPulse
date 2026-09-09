import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Structured result from OpenStreetMap Nominatim API.
class NominatimPlace {
  final int placeId;
  final String displayName;
  final String title;
  final String subtitle;
  final LatLng location;
  final String? town;
  final String? city;
  final String? municipality;
  final String? district;
  final String? state;

  const NominatimPlace({
    required this.placeId,
    required this.displayName,
    required this.title,
    required this.subtitle,
    required this.location,
    this.town,
    this.city,
    this.municipality,
    this.district,
    this.state,
  });

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    final rawLat = double.tryParse('${json['lat']}') ?? 0.0;
    final rawLon = double.tryParse('${json['lon']}') ?? 0.0;
    final address = json['address'] as Map<String, dynamic>? ?? {};

    final town = address['town']?.toString() ?? address['suburb']?.toString() ?? address['village']?.toString();
    final city = address['city']?.toString() ?? address['municipality']?.toString();
    final district = address['state_district']?.toString() ??
        address['county']?.toString() ??
        address['district']?.toString();
    final state = address['state']?.toString() ?? address['province']?.toString();

    // Determine primary title
    String title = json['name']?.toString() ?? '';
    if (title.isEmpty) {
      title = town ?? city ?? municipality ?? (json['display_name']?.toString().split(',').first ?? 'Unknown Place');
    }

    // Determine subtitle
    final parts = <String>[];
    if (district != null && district.isNotEmpty && !title.toLowerCase().contains(district.toLowerCase())) {
      parts.add(district);
    }
    if (state != null && state.isNotEmpty && !title.toLowerCase().contains(state.toLowerCase())) {
      parts.add(state);
    }
    final subtitle = parts.isNotEmpty ? parts.join(', ') : (json['display_name']?.toString() ?? '');

    return NominatimPlace(
      placeId: json['place_id'] is int ? json['place_id'] : int.tryParse('${json['place_id']}') ?? 0,
      displayName: json['display_name']?.toString() ?? title,
      title: title,
      subtitle: subtitle,
      location: LatLng(rawLat, rawLon),
      town: town,
      city: city,
      municipality: municipality,
      district: district,
      state: state,
    );
  }
}

/// Service to interact with OpenStreetMap Nominatim for geocoding & reverse geocoding.
/// Respects OSM usage policy with custom User-Agent, Sri Lanka boundary filter, and timeout.
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'CivicPulse-Mobile-App/1.0 (contact@civicpulse.org)';

  final http.Client _client;

  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for places matching the query, restricted to Sri Lanka (`countrycodes=lk`).
  Future<List<NominatimPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final uri = Uri.parse(
      '$_baseUrl/search?q=${Uri.encodeQueryComponent(trimmed)}&format=json&addressdetails=1&limit=5&countrycodes=lk',
    );

    try {
      debugPrint('[Nominatim] Searching: $uri');
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return [];
        final dynamic data = jsonDecode(body);
        if (data is! List) return [];
        final results = data.map((e) => NominatimPlace.fromJson(e as Map<String, dynamic>)).toList();
        debugPrint('[Nominatim] Found ${results.length} results for "$query"');
        return results;
      } else {
        debugPrint('[Nominatim] Search HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[Nominatim] Search exception: $e');
      return [];
    }
  }

  /// Reverse geocode coordinates to retrieve address details.
  Future<NominatimPlace?> reverseGeocode(LatLng location) async {
    final uri = Uri.parse(
      '$_baseUrl/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&addressdetails=1',
    );

    try {
      debugPrint('[Nominatim] Reverse geocoding: $uri');
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) return null;
        final dynamic data = jsonDecode(body);
        if (data is! Map<String, dynamic>) return null;
        return NominatimPlace.fromJson(data);
      } else {
        debugPrint('[Nominatim] Reverse HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[Nominatim] Reverse geocode exception: $e');
      return null;
    }
  }
}
