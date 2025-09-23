import '../../domain/entities/category.dart';

class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final int parentId;
  final int sortOrder;
  final bool isActive;
  final int? productCount;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.parentId,
    required this.sortOrder,
    required this.isActive,
    this.icon,
    this.productCount,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final kids = (json['children'] as List<dynamic>?)
            ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <CategoryModel>[];

    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      parentId: (json['parentId'] ?? 0) as int,
      sortOrder: (json['sortOrder'] ?? 0) as int,
      isActive: (json['isActive'] ?? true) as bool,
      productCount: json['productCount'] as int?,
      children: kids,
    );
  }

  Map<String, dynamic> toJson({bool includeChildren = true}) => {
        'id': id,
        'name': name,
        'icon': icon,
        'parentId': parentId,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'productCount': productCount,
        if (includeChildren)
          'children': children.map((c) => c.toJson(includeChildren: true)).toList(),
      };

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        icon: icon,
        parentId: parentId,
        sortOrder: sortOrder,
        isActive: isActive,
        productCount: productCount,
        children: children.map((c) => c.toEntity()).toList(),
      );
}
