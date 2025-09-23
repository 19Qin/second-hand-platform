import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
  });

  Future<ProductListResponseModel> searchProducts({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  });

  Future<ProductModel> fetchProductDetail(String productId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  static const _apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'https://api.fliliy.com');

  final http.Client client;
  ProductRemoteDataSourceImpl(this.client);

  @override
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
  }) async {
    final uri = Uri.parse('$_apiBase/products').replace(queryParameters: {
      'page': page.toString(),
      'size': size.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sellerId != null) 'seller_id': sellerId.toString(),
    });

    final res = await client.get(uri);
    if (res.statusCode != 200) throw Exception('GET /products failed (${res.statusCode})');
    final root = json.decode(res.body) as Map<String, dynamic>;
    return ProductListResponseModel.fromJson(root);
  }

  @override
  Future<ProductListResponseModel> searchProducts({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    final uri = Uri.parse('$_apiBase/products/search').replace(queryParameters: {
      'keyword': keyword,
      'page': page.toString(),
      'size': size.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    });

    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('GET /products/search failed (${res.statusCode})');
    }
    final root = json.decode(res.body) as Map<String, dynamic>;
    return ProductListResponseModel.fromJson(root);
  }

  @override
  Future<ProductModel> fetchProductDetail(String productId) async {
    final uri = Uri.parse('$_apiBase/products/$productId');
    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('GET /products/{id} failed (${res.statusCode})');
    }
    final root = json.decode(res.body) as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>;
    return ProductModel.fromJson(data);
  }
}
