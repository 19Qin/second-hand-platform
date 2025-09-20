import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductDetail {
  final ProductRepository repo;
  GetProductDetail(this.repo);

  Future<ProductEntity> call(String productId) => repo.getProductDetail(productId);
}
