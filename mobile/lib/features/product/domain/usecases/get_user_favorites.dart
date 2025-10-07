import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetUserFavorites {
  final ProductRepository _repository;

  GetUserFavorites(this._repository);

  Future<UserFavoritesResponse> call({
    String status = 'all',
    int page = 1,
    int size = 20,
    String sort = 'time_desc',
  }) async {
    return await _repository.getUserFavorites(
      status: status,
      page: page,
      size: size,
      sort: sort,
    );
  }
}

class UserFavoritesResponse {
  final List<ProductEntity> content;
  final PaginationInfo pagination;

  const UserFavoritesResponse({
    required this.content,
    required this.pagination,
  });
}

class PaginationInfo {
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  const PaginationInfo({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });
}


