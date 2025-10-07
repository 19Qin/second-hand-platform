import '../../domain/entities/user_product_entity.dart';
import '../../domain/repositories/user_products_repository.dart';
import '../datasources/user_products_remote_data_source.dart';
import '../models/user_product_model.dart';

class UserProductsRepositoryImpl implements UserProductsRepository {
  final UserProductsRemoteDataSource _remoteDataSource;

  UserProductsRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProductsResponseEntity> getUserProducts({
    String? status,
    int page = 1,
    int size = 10,
    String sort = 'time_desc',
  }) async {
    final response = await _remoteDataSource.getUserProducts(
      status: status,
      page: page,
      size: size,
      sort: sort,
    );

    return _mapToEntity(response);
  }

  UserProductsResponseEntity _mapToEntity(UserProductsResponseModel model) {
    return UserProductsResponseEntity(
      products: model.products.map(_mapProductToEntity).toList(),
      summary: UserProductsSummaryEntity(
        total: model.summary.total,
        active: model.summary.active,
        sold: model.summary.sold,
        inactive: model.summary.inactive,
      ),
      pagination: UserProductsPaginationEntity(
        page: model.pagination.page,
        size: model.pagination.size,
        total: model.pagination.total,
        hasNext: model.pagination.hasNext,
      ),
    );
  }

  UserProductEntity _mapProductToEntity(UserProductModel model) {
    return UserProductEntity(
      id: model.id,
      title: model.title,
      price: model.price,
      mainImage: model.mainImage,
      status: model.status,
      statusText: model.statusText,
      publishTime: model.publishTime,
      stats: UserProductStatsEntity(
        viewCount: model.stats.viewCount,
        favoriteCount: model.stats.favoriteCount,
        chatCount: model.stats.chatCount,
        inquiryCount: model.stats.inquiryCount,
      ),
      actions: model.actions,
    );
  }
}




