import '../../domain/entities/product_favorite.dart';

/// 商品收藏数据模型
class ProductFavoriteModel {
  final String productId;
  final bool isFavorited;
  final DateTime? favoritedAt;
  final String? message;

  ProductFavoriteModel({
    required this.productId,
    required this.isFavorited,
    this.favoritedAt,
    this.message,
  });

  factory ProductFavoriteModel.fromJson(Map<String, dynamic> json) {
    return ProductFavoriteModel(
      productId: json['productId'] as String,
      isFavorited: json['isFavorited'] as bool,
      favoritedAt: json['favoritedAt'] != null 
          ? DateTime.tryParse(json['favoritedAt'] as String) 
          : null,
      message: json['message'] as String?,
    );
  }

  ProductFavoriteEntity toEntity() {
    return ProductFavoriteEntity(
      productId: productId,
      isFavorited: isFavorited,
      favoritedAt: favoritedAt,
      message: message,
    );
  }
}
