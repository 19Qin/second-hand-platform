import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repo;
  GetProducts(this.repo);

  Future<ProductListEntity> call({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
  }) {
    return repo.getProducts(
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
  }
}
