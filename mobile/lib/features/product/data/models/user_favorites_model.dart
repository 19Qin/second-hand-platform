import '../../domain/entities/product.dart';
import '../../domain/usecases/get_user_favorites.dart';
import 'product_model.dart';

class UserFavoritesResponseModel {
  final List<ProductModel> content;
  final PaginationModel pagination;

  const UserFavoritesResponseModel({
    required this.content,
    required this.pagination,
  });

  factory UserFavoritesResponseModel.fromJson(Map<String, dynamic> json) {
    return UserFavoritesResponseModel(
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => ProductModel.fromJson(item))
          .toList() ?? [],
      pagination: PaginationModel.fromJson(json['pagination']),
    );
  }

  UserFavoritesResponse toEntity() {
    return UserFavoritesResponse(
      content: content.map((item) => item.toEntity()).toList(),
      pagination: PaginationInfo(
        page: pagination.page,
        size: pagination.size,
        total: pagination.total,
        hasNext: pagination.hasNext,
      ),
    );
  }
}

class PaginationModel {
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  const PaginationModel({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      size: json['size'] ?? 20,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
