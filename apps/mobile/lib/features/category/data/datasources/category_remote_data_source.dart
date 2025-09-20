import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> fetchCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  // Read API base from --dart-define=API_BASE=...
  static const _apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'https://api.fliliy.com');

  final http.Client client;
  CategoryRemoteDataSourceImpl(this.client);

  @override
  Future<List<CategoryModel>> fetchCategories({
    int parentId = 0,
    bool isActive = true,
    bool includeChildren = true,
  }) async {
    final uri = Uri.parse('$_apiBase/categories').replace(queryParameters: {
      'parent_id': parentId.toString(),
      'is_active': isActive.toString(),
      'include_children': includeChildren.toString(),
    });

    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch categories: ${res.statusCode}');
    }

    final root = json.decode(res.body) as Map<String, dynamic>;
    final list = root['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
