class DepartmentModel {
  final int departmentId;
  final String departmentName;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final int? territoryId;
  final String? territoryName;

  const DepartmentModel({
    required this.departmentId,
    required this.departmentName,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.territoryId,
    this.territoryName,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      departmentId: json['departmentId'] is int ? json['departmentId'] : int.tryParse('${json['departmentId']}') ?? 0,
      departmentName: json['departmentName']?.toString() ?? '',
      description: json['description']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      territoryId: json['territoryId'] is int ? json['territoryId'] : int.tryParse('${json['territoryId']}'),
      territoryName: json['territoryName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentName': departmentName,
      'description': description,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'territoryId': territoryId,
      'territoryName': territoryName,
    };
  }
}
