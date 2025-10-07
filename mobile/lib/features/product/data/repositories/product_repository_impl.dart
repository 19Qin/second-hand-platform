import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_user_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../datasources/product_remote_data_source.dart';

/// Product Repository Implementation
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProductListEntity> getProducts({
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
    final response = await _remoteDataSource.fetchProducts(
      page: page,
      size: size,
      categoryId: categoryId,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
      location: location,
      sellerId: sellerId,
    );
    return response.toEntity();
  }

  @override
  Future<ProductListEntity> searchProducts({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    final response = await _remoteDataSource.searchProducts(
      keyword: keyword,
      page: page,
      size: size,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
    );
    return response.toEntity();
  }

  @override
  Future<ProductEntity> getProductDetail(String productId) async {
    final model = await _remoteDataSource.fetchProductDetail(productId);
    return model.toEntity();
  }

  @override
  Future<List<ProductEntity>> getRelatedProducts(String productId) async {
    // Temporarily use search interface to simulate related products, can be extended with dedicated related products API later
    final response = await _remoteDataSource.fetchProducts(
      page: 1,
      size: 8,
    );
    return response.items
        .where((product) => product.id != productId)
        .take(4)
        .map((model) => model.toEntity())
        .toList();
  }
  
  @override
  Future<UserFavoritesResponse> getUserFavorites({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
  }) async {
    final response = await _remoteDataSource.getUserFavorites(
      status: status,
      page: page,
      size: size,
      sort: sort,
    );
    return response.toEntity();
  }

  @override
  Future<ToggleFavoriteResponse> toggleFavorite(String productId) async {
    final response = await _remoteDataSource.toggleProductFavorite(productId);
    return response.toEntity();
  }
}