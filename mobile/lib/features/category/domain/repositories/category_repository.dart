import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  });
}
