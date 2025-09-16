import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../data_sources/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remote;
  CategoryRepositoryImpl(this.remote);

  @override
  Future<List<CategoryEntity>> getCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  }) async {
    final models = await remote.fetchCategories(
      parentId: parentId,
      isActive: isActive,
      includeChildren: includeChildren,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
