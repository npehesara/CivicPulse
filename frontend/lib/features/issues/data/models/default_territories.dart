import 'package:latlong2/latlong.dart';
import 'territory_model.dart';

/// Predefined territory entry containing territory metadata, geographic centroid, and bounding box.
class DefaultDistrictInfo {
  final int territoryId;
  final String districtName;
  final String parentProvince;
  final LatLng centroid;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  final List<String> keywords;

  const DefaultDistrictInfo({
    required this.territoryId,
    required this.districtName,
    required this.parentProvince,
    required this.centroid,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
    required this.keywords,
  });

  TerritoryModel toModel() {
    return TerritoryModel(
      territoryId: territoryId,
      territoryName: districtName,
      regionType: 'DISTRICT',
      parentTerritoryName: parentProvince,
    );
  }

  bool containsPoint(LatLng point) {
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLon &&
        point.longitude <= maxLon;
  }
}

/// Fallback catalog of the 25 official Sri Lankan administrative districts.
const List<DefaultDistrictInfo> kSriLankanDistricts = [
  // Western Province
  DefaultDistrictInfo(
    territoryId: 1,
    districtName: 'Colombo',
    parentProvince: 'Western Province',
    centroid: LatLng(6.9271, 79.8612),
    minLat: 6.74,
    maxLat: 7.02,
    minLon: 79.80,
    maxLon: 80.20,
    keywords: ['colombo', 'kotte', 'dehiwala', 'mount lavinia', 'moratuwa', 'homagama', 'maharagama', 'kolonnawa'],
  ),
  DefaultDistrictInfo(
    territoryId: 2,
    districtName: 'Gampaha',
    parentProvince: 'Western Province',
    centroid: LatLng(7.0840, 79.9939),
    minLat: 6.98,
    maxLat: 7.33,
    minLon: 79.82,
    maxLon: 80.25,
    keywords: ['gampaha', 'negombo', 'kelaniya', 'wattala', 'ja-ela', 'kadawatha', 'mirigama', 'minuwangoda'],
  ),
  DefaultDistrictInfo(
    territoryId: 3,
    districtName: 'Kalutara',
    parentProvince: 'Western Province',
    centroid: LatLng(6.5854, 79.9607),
    minLat: 6.36,
    maxLat: 6.78,
    minLon: 79.90,
    maxLon: 80.35,
    keywords: ['kalutara', 'panadura', 'horana', 'beruwala', 'aluthgama', 'matugama', 'bandaragama'],
  ),

  // Central Province
  DefaultDistrictInfo(
    territoryId: 4,
    districtName: 'Kandy',
    parentProvince: 'Central Province',
    centroid: LatLng(7.2906, 80.6337),
    minLat: 7.08,
    maxLat: 7.50,
    minLon: 80.42,
    maxLon: 80.95,
    keywords: ['kandy', 'peradeniya', 'gampola', 'katugastota', 'kundasale', 'nawalapitiya', 'ak浏览'],
  ),
  DefaultDistrictInfo(
    territoryId: 5,
    districtName: 'Matale',
    parentProvince: 'Central Province',
    centroid: LatLng(7.4675, 80.6234),
    minLat: 7.33,
    maxLat: 8.00,
    minLon: 80.45,
    maxLon: 81.00,
    keywords: ['matale', 'dambulla', 'sigiriya', 'galewela', 'rattota', 'urukku'],
  ),
  DefaultDistrictInfo(
    territoryId: 6,
    districtName: 'Nuwara Eliya',
    parentProvince: 'Central Province',
    centroid: LatLng(6.9497, 80.7891),
    minLat: 6.78,
    maxLat: 7.15,
    minLon: 80.50,
    maxLon: 80.95,
    keywords: ['nuwara eliya', 'hatton', 'talawakelle', 'gregory', 'ragala', 'maskeliya'],
  ),

  // Southern Province
  DefaultDistrictInfo(
    territoryId: 7,
    districtName: 'Galle',
    parentProvince: 'Southern Province',
    centroid: LatLng(6.0535, 80.2210),
    minLat: 5.95,
    maxLat: 6.45,
    minLon: 80.05,
    maxLon: 80.50,
    keywords: ['galle', 'hikkaduwa', 'unawatuna', 'ambalangoda', 'karapitiya', 'baddegama', 'elpitiya', 'balapitiya'],
  ),
  DefaultDistrictInfo(
    territoryId: 8,
    districtName: 'Matara',
    parentProvince: 'Southern Province',
    centroid: LatLng(5.9549, 80.5550),
    minLat: 5.90,
    maxLat: 6.40,
    minLon: 80.40,
    maxLon: 80.75,
    keywords: ['matara', 'weligama', 'mirissa', 'dikwella', 'akuressa', 'hakmana', 'deniyaya'],
  ),
  DefaultDistrictInfo(
    territoryId: 9,
    districtName: 'Hambantota',
    parentProvince: 'Southern Province',
    centroid: LatLng(6.1246, 81.1185),
    minLat: 6.05,
    maxLat: 6.55,
    minLon: 80.68,
    maxLon: 81.70,
    keywords: ['hambantota', 'tangalle', 'amabalantota', 'beliatta', 'tissamaharama', 'katagarama'],
  ),

  // Northern Province
  DefaultDistrictInfo(
    territoryId: 10,
    districtName: 'Jaffna',
    parentProvince: 'Northern Province',
    centroid: LatLng(9.6615, 80.0255),
    minLat: 9.45,
    maxLat: 9.85,
    minLon: 79.65,
    maxLon: 80.35,
    keywords: ['jaffna', 'chavakachcheri', 'point pedro', 'nallur', 'karainagar'],
  ),
  DefaultDistrictInfo(
    territoryId: 11,
    districtName: 'Kilinochchi',
    parentProvince: 'Northern Province',
    centroid: LatLng(9.3803, 80.3770),
    minLat: 9.15,
    maxLat: 9.60,
    minLon: 80.05,
    maxLon: 80.65,
    keywords: ['kilinochchi', 'paranthan', 'pallai', 'poonakary'],
  ),
  DefaultDistrictInfo(
    territoryId: 12,
    districtName: 'Mannar',
    parentProvince: 'Northern Province',
    centroid: LatLng(8.9810, 79.9042),
    minLat: 8.70,
    maxLat: 9.15,
    minLon: 79.70,
    maxLon: 80.30,
    keywords: ['mannar', 'pesalai', 'murunkan', 'talaimannar'],
  ),
  DefaultDistrictInfo(
    territoryId: 13,
    districtName: 'Vavuniya',
    parentProvince: 'Northern Province',
    centroid: LatLng(8.7514, 80.4971),
    minLat: 8.55,
    maxLat: 9.05,
    minLon: 80.25,
    maxLon: 80.75,
    keywords: ['vavuniya', 'cheddekulam', 'nedunkeni'],
  ),
  DefaultDistrictInfo(
    territoryId: 14,
    districtName: 'Mullaitivu',
    parentProvince: 'Northern Province',
    centroid: LatLng(9.2671, 80.8142),
    minLat: 9.00,
    maxLat: 9.45,
    minLon: 80.45,
    maxLon: 80.95,
    keywords: ['mullaitivu', 'puthukkudiyiruppu', 'mankulam'],
  ),

  // Eastern Province
  DefaultDistrictInfo(
    territoryId: 15,
    districtName: 'Batticaloa',
    parentProvince: 'Eastern Province',
    centroid: LatLng(7.7170, 81.7000),
    minLat: 7.35,
    maxLat: 8.00,
    minLon: 81.30,
    maxLon: 81.85,
    keywords: ['batticaloa', 'kattankudy', 'eravur', 'valachchenai'],
  ),
  DefaultDistrictInfo(
    territoryId: 16,
    districtName: 'Ampara',
    parentProvince: 'Eastern Province',
    centroid: LatLng(7.2975, 81.6747),
    minLat: 6.80,
    maxLat: 7.60,
    minLon: 81.40,
    maxLon: 81.90,
    keywords: ['ampara', 'kalmunai', 'sainthamaruthu', 'akkaraipattu', 'pottuvil', 'arugam bay'],
  ),
  DefaultDistrictInfo(
    territoryId: 17,
    districtName: 'Trincomalee',
    parentProvince: 'Eastern Province',
    centroid: LatLng(8.5874, 81.2152),
    minLat: 8.20,
    maxLat: 8.95,
    minLon: 80.90,
    maxLon: 81.45,
    keywords: ['trincomalee', 'kinniya', 'muttur', 'kantale', 'nilaveli'],
  ),

  // North Western Province
  DefaultDistrictInfo(
    territoryId: 18,
    districtName: 'Kurunegala',
    parentProvince: 'North Western Province',
    centroid: LatLng(7.4863, 80.3623),
    minLat: 7.25,
    maxLat: 7.95,
    minLon: 79.95,
    maxLon: 80.60,
    keywords: ['kurunegala', 'kuliyapitiya', 'narammala', 'pannala', 'wariyapola', 'polgahawela'],
  ),
  DefaultDistrictInfo(
    territoryId: 19,
    districtName: 'Puttalam',
    parentProvince: 'North Western Province',
    centroid: LatLng(8.0362, 79.8283),
    minLat: 7.30,
    maxLat: 8.45,
    minLon: 79.70,
    maxLon: 80.20,
    keywords: ['puttalam', 'chilaw', 'marawila', 'dankotuwa', 'anuradhapura road', 'kalpitiya', 'wennappuwa'],
  ),

  // North Central Province
  DefaultDistrictInfo(
    territoryId: 20,
    districtName: 'Anuradhapura',
    parentProvince: 'North Central Province',
    centroid: LatLng(8.3114, 80.4037),
    minLat: 8.00,
    maxLat: 8.85,
    minLon: 80.00,
    maxLon: 80.90,
    keywords: ['anuradhapura', 'kekirawa', 'medawachchiya', 'tambuttegama', 'mihintale', 'galenbindunuwewa'],
  ),
  DefaultDistrictInfo(
    territoryId: 21,
    districtName: 'Polonnaruwa',
    parentProvince: 'North Central Province',
    centroid: LatLng(7.9403, 81.0188),
    minLat: 7.70,
    maxLat: 8.35,
    minLon: 80.80,
    maxLon: 81.35,
    keywords: ['polonnaruwa', 'kaduruwela', 'hingurakgoda', 'medirigiriya', 'bakamoona'],
  ),

  // Uva Province
  DefaultDistrictInfo(
    territoryId: 22,
    districtName: 'Badulla',
    parentProvince: 'Uva Province',
    centroid: LatLng(6.9934, 81.0550),
    minLat: 6.75,
    maxLat: 7.30,
    minLon: 80.85,
    maxLon: 81.30,
    keywords: ['badulla', 'bandarawela', 'ella', 'haputale', 'diyatalawa', 'mahiyanganaya', 'welimada'],
  ),
  DefaultDistrictInfo(
    territoryId: 23,
    districtName: 'Monaragala',
    parentProvince: 'Uva Province',
    centroid: LatLng(6.8728, 81.3507),
    minLat: 6.35,
    maxLat: 7.25,
    minLon: 81.05,
    maxLon: 81.75,
    keywords: ['monaragala', 'wellawaya', 'buttala', 'bibile', 'kataragama'],
  ),

  // Sabaragamuwa Province
  DefaultDistrictInfo(
    territoryId: 24,
    districtName: 'Ratnapura',
    parentProvince: 'Sabaragamuwa Province',
    centroid: LatLng(6.6828, 80.4034),
    minLat: 6.30,
    maxLat: 6.95,
    minLon: 80.15,
    maxLon: 80.90,
    keywords: ['ratnapura', 'balangoda', 'pelmadulla', 'emibilipitiya', 'kuruwita'],
  ),
  DefaultDistrictInfo(
    territoryId: 25,
    districtName: 'Kegalle',
    parentProvince: 'Sabaragamuwa Province',
    centroid: LatLng(7.2513, 80.3464),
    minLat: 6.95,
    maxLat: 7.40,
    minLon: 80.10,
    maxLon: 80.55,
    keywords: ['kegalle', 'mawanella', 'warakapola', 'ruwanwella', 'deraniyagala', 'yatiyantota'],
  ),
];

/// Helper to get centroid for a territory/district.
LatLng getCentroidForDistrict(String districtName) {
  final cleanName = cleanDistrictName(districtName).toLowerCase();
  for (final info in kSriLankanDistricts) {
    if (info.districtName.toLowerCase() == cleanName) {
      return info.centroid;
    }
  }
  return const LatLng(6.9271, 79.8612); // Colombo default
}

/// Cleans raw district strings (e.g. "Colombo District" -> "Colombo").
String cleanDistrictName(String raw) {
  return raw
      .replaceAll(RegExp(r'\s+district$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+distric$', caseSensitive: false), '')
      .trim();
}

/// Helper to find matching territory for coordinates or district name.
TerritoryModel findDistrictForCoordinates(
  LatLng point,
  List<TerritoryModel> availableTerritories, {
  String? hintDistrictName,
}) {
  final targetList = availableTerritories.isNotEmpty
      ? availableTerritories
      : kSriLankanDistricts.map((t) => t.toModel()).toList();

  // 1. If explicit hintDistrictName is provided (e.g. from Nominatim)
  if (hintDistrictName != null && hintDistrictName.trim().isNotEmpty) {
    final cleanHint = cleanDistrictName(hintDistrictName).toLowerCase();
    for (final territory in targetList) {
      final cleanTName = cleanDistrictName(territory.territoryName).toLowerCase();
      if (cleanTName == cleanHint ||
          cleanTName.contains(cleanHint) ||
          cleanHint.contains(cleanTName)) {
        return territory;
      }
    }
  }

  // 2. Try bounding-box containment from catalog
  for (final info in kSriLankanDistricts) {
    if (info.containsPoint(point)) {
      final cleanName = info.districtName.toLowerCase();
      final match = targetList.where((t) {
        final cleanT = cleanDistrictName(t.territoryName).toLowerCase();
        return cleanT == cleanName || cleanT.contains(cleanName) || cleanName.contains(cleanT);
      }).firstOrNull;
      if (match != null) return match;
    }
  }

  // 3. Fallback: closest district centroid
  const distance = Distance();
  DefaultDistrictInfo closestInfo = kSriLankanDistricts.first;
  double minDistance = double.infinity;

  for (final info in kSriLankanDistricts) {
    final dist = distance.as(LengthUnit.Kilometer, point, info.centroid);
    if (dist < minDistance) {
      minDistance = dist;
      closestInfo = info;
    }
  }

  final cleanClosest = closestInfo.districtName.toLowerCase();
  final matched = targetList.where((t) {
    final cleanT = cleanDistrictName(t.territoryName).toLowerCase();
    return cleanT == cleanClosest || cleanT.contains(cleanClosest) || cleanClosest.contains(cleanT);
  }).firstOrNull;

  return matched ?? closestInfo.toModel();
}
