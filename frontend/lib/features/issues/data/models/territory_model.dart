class TerritoryModel {
  final int territoryId;
  final String territoryName;
  final String? regionType;
  final String? parentTerritoryName;

  const TerritoryModel({
    required this.territoryId,
    required this.territoryName,
    this.regionType,
    this.parentTerritoryName,
  });

  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      territoryId: json['territoryId'] is int ? json['territoryId'] : int.tryParse('${json['territoryId']}') ?? 0,
      territoryName: json['territoryName']?.toString() ?? '',
      regionType: json['regionType']?.toString(),
      parentTerritoryName: json['parentTerritoryName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'territoryId': territoryId,
      'territoryName': territoryName,
      'regionType': regionType,
      'parentTerritoryName': parentTerritoryName,
    };
  }
}
