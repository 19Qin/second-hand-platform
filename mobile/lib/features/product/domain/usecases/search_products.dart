import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Search Products Use Case
class SearchProducts {
  final ProductRepository _repository;

  SearchProducts(this._repository);

  Future<ProductListEntity> call({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    return await _repository.searchProducts(
      keyword: keyword,
      page: page,
      size: size,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
    );
  }
}