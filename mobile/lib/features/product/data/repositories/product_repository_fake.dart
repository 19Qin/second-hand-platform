import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_user_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../../presentation/mock/product_mock.dart';

/// Product Repository Mock Implementation
class ProductRepositoryFake implements ProductRepository {
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple pagination simulation
    final allProducts = mockRecommendedProducts;
    final startIndex = (page - 1) * size;
    final endIndex = (startIndex + size).clamp(0, allProducts.length);
    
    final items = startIndex < allProducts.length 
        ? allProducts.sublist(startIndex, endIndex)
        : <ProductEntity>[];

    final pagination = PaginationEntity(
      page: page,
      size: size,
      total: allProducts.length,
      totalPages: (allProducts.length / size).ceil(),
      hasNext: endIndex < allProducts.length,
      hasPrev: page > 1,
    );

    return ProductListEntity(items: items, pagination: pagination);
  }

  @override
  Future<ProductEntity> getProductDetail(String productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final product = mockRecommendedProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    return product;
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    final query = keyword.toLowerCase();
    final filteredProducts = mockRecommendedProducts.where((p) =>
        p.title.toLowerCase().contains(query) ||
        (p.categoryName ?? '').toLowerCase().contains(query) ||
        (p.sellerUsername ?? '').toLowerCase().contains(query)
    ).toList();

    final startIndex = (page - 1) * size;
    final endIndex = (startIndex + size).clamp(0, filteredProducts.length);
    
    final items = startIndex < filteredProducts.length 
        ? filteredProducts.sublist(startIndex, endIndex)
        : <ProductEntity>[];

    final pagination = PaginationEntity(
      page: page,
      size: size,
      total: filteredProducts.length,
      totalPages: (filteredProducts.length / size).ceil(),
      hasNext: endIndex < filteredProducts.length,
      hasPrev: page > 1,
    );

    return ProductListEntity(items: items, pagination: pagination);
  }

  @override
  Future<List<ProductEntity>> getRelatedProducts(String productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return other products except current product as related products
    return mockRecommendedProducts
        .where((p) => p.id != productId)
        .take(4)
        .toList();
  }
  
  @override
  Future<UserFavoritesResponse> getUserFavorites({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Return empty favorites for mock
    return UserFavoritesResponse(
      content: [],
      pagination: PaginationInfo(
        page: page,
        size: size,
        total: 0,
        hasNext: false,
      ),
    );
  }

  @override
  Future<ToggleFavoriteResponse> toggleFavorite(String productId) async {
    // Mock implementation - always return success
    return ToggleFavoriteResponse(
      isFavorited: true,
      favoriteCount: 1,
    );
  }
}
