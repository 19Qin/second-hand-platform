/// 商品收藏相关实体
class ProductFavoriteEntity {
  final String productId;
  final bool isFavorited;
  final DateTime? favoritedAt;
  final String? message;

  const ProductFavoriteEntity({
    required this.productId,
    required this.isFavorited,
    this.favoritedAt,
    this.message,
  });
}
