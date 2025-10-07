import '../entities/user_product_entity.dart';
import '../repositories/user_products_repository.dart';

class GetUserProductsUseCase {
  final UserProductsRepository _repository;

  GetUserProductsUseCase(this._repository);

  Future<UserProductsResponseEntity> call({
    String? status,
    int page = 1,
    int size = 10,
    String sort = 'time_desc',
  }) async {
    return await _repository.getUserProducts(
      status: status,
      page: page,
      size: size,
      sort: sort,
    );
  }
}




