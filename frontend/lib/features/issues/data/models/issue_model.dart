import 'issue_image_model.dart';

class IssueModel {
  final int issueId;
  final String title;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? locationPoint;
  final String visibility; // PUBLIC, PRIVATE
  final String severity; // LOW, MEDIUM, HIGH, CRITICAL
  final bool isTransitReport;
  final String createdAt;
  final String updatedAt;
  final int? userId;
  final String? userFullName;
  final String? userEmail;
  final int? categoryId;
  final String? categoryName;
  final int? territoryId;
  final String? territoryName;
  final int? departmentId;
  final String? departmentName;
  final int? statusId;
  final String? statusName;
  final int upvoteCount;
  final int commentCount;
  final bool hasUpvoted;
  final List<IssueImageModel> images;

  const IssueModel({
    required this.issueId,
    required this.title,
    required this.description,
    this.latitude,
    this.longitude,
    this.locationPoint,
    this.visibility = 'PUBLIC',
    this.severity = 'MEDIUM',
    this.isTransitReport = false,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.userFullName,
    this.userEmail,
    this.categoryId,
    this.categoryName,
    this.territoryId,
    this.territoryName,
    this.departmentId,
    this.departmentName,
    this.statusId,
    this.statusName,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.hasUpvoted = false,
    this.images = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      issueId: json['issueId'] is int ? json['issueId'] : int.tryParse('${json['issueId']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : null,
      locationPoint: json['locationPoint']?.toString(),
      visibility: json['visibility']?.toString() ?? 'PUBLIC',
      severity: json['severity']?.toString() ?? 'MEDIUM',
      isTransitReport: json['isTransitReport'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}'),
      userFullName: json['userFullName']?.toString() ?? 'Citizen',
      userEmail: json['userEmail']?.toString(),
      categoryId: json['categoryId'] is int ? json['categoryId'] : int.tryParse('${json['categoryId']}'),
      categoryName: json['categoryName']?.toString(),
      territoryId: json['territoryId'] is int ? json['territoryId'] : int.tryParse('${json['territoryId']}'),
      territoryName: json['territoryName']?.toString(),
      departmentId: json['departmentId'] is int ? json['departmentId'] : int.tryParse('${json['departmentId']}'),
      departmentName: json['departmentName']?.toString(),
      statusId: json['statusId'] is int ? json['statusId'] : int.tryParse('${json['statusId']}'),
      statusName: json['statusName']?.toString() ?? 'REPORTED',
      upvoteCount: json['upvoteCount'] is int ? json['upvoteCount'] : int.tryParse('${json['upvoteCount']}') ?? 0,
      commentCount: json['commentCount'] is int ? json['commentCount'] : int.tryParse('${json['commentCount']}') ?? 0,
      hasUpvoted: json['hasUpvoted'] == true,
      images: (json['images'] is List)
          ? (json['images'] as List).map((i) => IssueImageModel.fromJson(i as Map<String, dynamic>)).toList()
          : [],
    );
  }

  IssueModel copyWith({
    int? issueId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? locationPoint,
    String? visibility,
    String? severity,
    bool? isTransitReport,
    String? createdAt,
    String? updatedAt,
    int? userId,
    String? userFullName,
    String? userEmail,
    int? categoryId,
    String? categoryName,
    int? territoryId,
    String? territoryName,
    int? departmentId,
    String? departmentName,
    int? statusId,
    String? statusName,
    int? upvoteCount,
    int? commentCount,
    bool? hasUpvoted,
    List<IssueImageModel>? images,
  }) {
    return IssueModel(
      issueId: issueId ?? this.issueId,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationPoint: locationPoint ?? this.locationPoint,
      visibility: visibility ?? this.visibility,
      severity: severity ?? this.severity,
      isTransitReport: isTransitReport ?? this.isTransitReport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      userEmail: userEmail ?? this.userEmail,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      territoryId: territoryId ?? this.territoryId,
      territoryName: territoryName ?? this.territoryName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issueId': issueId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationPoint': locationPoint,
      'visibility': visibility,
      'severity': severity,
      'isTransitReport': isTransitReport,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'territoryId': territoryId,
      'territoryName': territoryName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'statusId': statusId,
      'statusName': statusName,
      'upvoteCount': upvoteCount,
      'commentCount': commentCount,
      'hasUpvoted': hasUpvoted,
      'images': images.map((i) => i.toJson()).toList(),
    };
  }
}
