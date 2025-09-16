import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategories {
  final CategoryRepository repository;
  GetCategories(this.repository);

  Future<List<CategoryEntity>> call({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  }) {
    return repository.getCategories(
      parentId: parentId,
      isActive: isActive,
      includeChildren: includeChildren,
    );
  }
}
