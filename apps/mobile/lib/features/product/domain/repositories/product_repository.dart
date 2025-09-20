import '../entities/product.dart';

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
}
