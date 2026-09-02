class StatusModel {
  final int statusId;
  final String statusName;
  final String? description;

  const StatusModel({
    required this.statusId,
    required this.statusName,
    this.description,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      statusId: json['statusId'] is int ? json['statusId'] : int.tryParse('${json['statusId']}') ?? 0,
      statusName: json['statusName']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusId': statusId,
      'statusName': statusName,
      'description': description,
    };
  }
}
