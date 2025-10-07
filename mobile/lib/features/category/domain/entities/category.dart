class CategoryEntity {
  final int id;
  final String name;
  final String? icon;
  final int parentId;
  final int sortOrder;
  final bool isActive;
  final int? productCount;

  /// Children categories (non-null, default empty)
  final List<CategoryEntity> children;

  /// Optional H5 link URL
  final String? linkUrl;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.icon,
    required this.parentId,
    required this.sortOrder,
    required this.isActive,
    this.productCount,
    this.children = const <CategoryEntity>[],
    this.linkUrl,
  });
}
