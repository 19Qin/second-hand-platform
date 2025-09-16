import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SearchProducts {
  final ProductRepository repo;
  SearchProducts(this.repo);

  Future<ProductListEntity> call({
    required String keyword,
    int page = 1,
    int size = 20,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) {
    return repo.searchProducts(
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
