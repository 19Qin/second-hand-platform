import '../entities/user_product_entity.dart';

abstract class UserProductsRepository {
  Future<UserProductsResponseEntity> getUserProducts({
    String? status,
    int page = 1,
    int size = 10,
    String sort = 'time_desc',
  });
}




