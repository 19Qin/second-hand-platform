import '../entities/product.dart';
import '../usecases/get_user_favorites.dart';
import '../usecases/toggle_favorite.dart';

abstract class ProductRepository {
  Future<ProductListEntity> getProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? condition,     // NEW, LIKE_NEW, GOOD, FAIR, POOR
    double? minPrice,
    double? maxPrice,
    String? sort,          // created_at_desc, price_asc, price_desc, popular
    String? location,
    int? sellerId,
  });

  Future<ProductListEntity> searchProducts({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,          // relevance, created_at_desc, price_asc, price_desc
  });

  Future<ProductEntity> getProductDetail(String productId);
  
  Future<List<ProductEntity>> getRelatedProducts(String productId);
  
  // 获取用户收藏商品
  Future<UserFavoritesResponse> getUserFavorites({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
  });

  Future<ToggleFavoriteResponse> toggleFavorite(String productId);
}
