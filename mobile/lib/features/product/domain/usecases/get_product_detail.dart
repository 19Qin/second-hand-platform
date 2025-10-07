import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Get Product Detail Use Case
class GetProductDetail {
  final ProductRepository _repository;

  GetProductDetail(this._repository);

  Future<ProductEntity> call(String productId) async {
    return await _repository.getProductDetail(productId);
  }
}

/// Get Related Products Use Case
class GetRelatedProducts {
  final ProductRepository _repository;

  GetRelatedProducts(this._repository);

  Future<List<ProductEntity>> call(String productId) async {
    return await _repository.getRelatedProducts(productId);
  }
}