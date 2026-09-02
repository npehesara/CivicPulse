class IssueImageModel {
  final int imageId;
  final String imageUrl;
  final String? originalFilename;
  final double? aiSafetyScore;
  final double? aiRelevanceScore;
  final bool isAnonymized;
  final String? uploadedAt;

  const IssueImageModel({
    required this.imageId,
    required this.imageUrl,
    this.originalFilename,
    this.aiSafetyScore,
    this.aiRelevanceScore,
    this.isAnonymized = false,
    this.uploadedAt,
  });

  factory IssueImageModel.fromJson(Map<String, dynamic> json) {
    return IssueImageModel(
      imageId: json['imageId'] is int ? json['imageId'] : int.tryParse('${json['imageId']}') ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      originalFilename: json['originalFilename']?.toString(),
      aiSafetyScore: (json['aiSafetyScore'] is num) ? (json['aiSafetyScore'] as num).toDouble() : null,
      aiRelevanceScore: (json['aiRelevanceScore'] is num) ? (json['aiRelevanceScore'] as num).toDouble() : null,
      isAnonymized: json['isAnonymized'] == true,
      uploadedAt: json['uploadedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'imageUrl': imageUrl,
      'originalFilename': originalFilename,
      'aiSafetyScore': aiSafetyScore,
      'aiRelevanceScore': aiRelevanceScore,
      'isAnonymized': isAnonymized,
      'uploadedAt': uploadedAt,
    };
  }
}
