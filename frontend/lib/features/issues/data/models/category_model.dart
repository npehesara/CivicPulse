class CategoryModel {
  final int categoryId;
  final String categoryName;
  final String? description;

  const CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] is int ? json['categoryId'] : int.tryParse('${json['categoryId']}') ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
    };
  }
}
