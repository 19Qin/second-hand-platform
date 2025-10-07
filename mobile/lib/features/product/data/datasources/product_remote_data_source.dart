import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';
import '../models/product_publish_model.dart';
import '../models/product_favorite_model.dart';
import '../models/user_favorites_model.dart';
import '../models/toggle_favorite_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? keyword,
    String? filter, // all, popular, discount, brand, accessories
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort, // time_desc, price_asc, price_desc, popular
    String? location,
    int? sellerId,
    bool? hasWarranty,
    double? longitude,
    double? latitude,
    int? radius, // in meters, default 500
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
  
  // 发布商品
  Future<ProductPublishResponseModel> publishProduct({
    required ProductPublishRequestModel productData,
    String? token,
  });
  
  // 收藏/取消收藏商品
  Future<ProductFavoriteModel> toggleFavorite({
    required String productId,
    String? token,
  });
  
  // 获取用户收藏商品列表
  Future<UserFavoritesResponseModel> getUserFavorites({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
    String? token,
  });

  Future<ToggleFavoriteResponseModel> toggleProductFavorite(String productId, {String? token});
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;
  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ProductListResponseModel> fetchProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? keyword,
    String? filter,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
    bool? hasWarranty,
    double? longitude,
    double? latitude,
    int? radius,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (categoryId != null) 'category': categoryId.toString(),
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (location != null && location.isNotEmpty) 'location': location,
      if (sellerId != null) 'sellerId': sellerId.toString(),
      if (hasWarranty != null) 'hasWarranty': hasWarranty.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (radius != null) 'radius': radius.toString(),
    };

    return await _apiClient.get<ProductListResponseModel>(
      'products',
      queryParameters: queryParameters,
      fromJson: (json) {
        // ApiClient has already extracted the data field, json is the content of data
        return ProductListResponseModel.fromJson({'data': json});
      },
    );
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
    final queryParameters = <String, String>{
      'keyword': keyword,
      'page': page.toString(),
      'size': size.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };

    return await _apiClient.get<ProductListResponseModel>(
      'products/search',
      queryParameters: queryParameters,
      fromJson: (json) {
        // ApiClient has already extracted the data field, json is the content of data
        return ProductListResponseModel.fromJson({'data': json});
      },
    );
  }

  @override
  Future<ProductModel> fetchProductDetail(String productId) async {
    return await _apiClient.get<ProductModel>(
      'products/$productId',
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return ProductModel.fromJson(json);
        } else {
          throw Exception('Invalid JSON format: expected Map<String, dynamic> but got ${json.runtimeType}');
        }
      },
    );
  }
  
  @override
  Future<ProductPublishResponseModel> publishProduct({
    required ProductPublishRequestModel productData,
    String? token,
  }) async {
    return await _apiClient.post<ProductPublishResponseModel>(
      'products',
      body: productData.toJson(),
      fromJson: (json) => ProductPublishResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  @override
  Future<ProductFavoriteModel> toggleFavorite({
    required String productId,
    String? token,
  }) async {
    return await _apiClient.post<ProductFavoriteModel>(
      'products/$productId/favorite',
      fromJson: (json) => ProductFavoriteModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  @override
  Future<UserFavoritesResponseModel> getUserFavorites({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
    String? token,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };
    
    // 只有当status不为空时才添加status参数
    if (status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    return await _apiClient.get<UserFavoritesResponseModel>(
      'user/favorites',
      queryParameters: queryParameters,
      fromJson: (json) => UserFavoritesResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ToggleFavoriteResponseModel> toggleProductFavorite(String productId, {String? token}) async {
    return await _apiClient.post<ToggleFavoriteResponseModel>(
      'products/$productId/favorite',
      fromJson: (json) => ToggleFavoriteResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
