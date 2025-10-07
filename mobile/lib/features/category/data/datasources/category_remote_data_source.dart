import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> fetchCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient _apiClient;

  CategoryRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CategoryModel>> fetchCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  }) async {
    final queryParameters = <String, String>{
      'parent_id': parentId.toString(),
      'is_active': isActive.toString(),
      'include_children': includeChildren.toString(),
    };

    final response = await _apiClient.get<List<CategoryModel>>(
      'categories',
      queryParameters: queryParameters,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return <CategoryModel>[];
      },
    );
    
    return response;
  }
}
