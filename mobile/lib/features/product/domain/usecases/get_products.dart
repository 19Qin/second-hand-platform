import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Get Product List Use Case
class GetProducts {
  final ProductRepository _repository;

  GetProducts(this._repository);

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
  }) async {
    return await _repository.getProducts(
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