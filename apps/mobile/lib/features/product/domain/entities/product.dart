class ProductEntity {
  final String id;
  final String title;
  final String? description;
  final double price;
  final double? originalPrice;
  final int? discount;
  final String? mainImage;
  final List<String> images;
  final String? condition;
  final String? conditionText;
  final int? categoryId;
  final String? categoryName;
  final String? categoryParentName;
  final int? sellerId;
  final String? sellerUsername;
  final String? sellerAvatar;
  final bool? sellerVerified;
  final double? sellerRating;
  final String? locationCity;
  final String? locationDistrict;
  final String? status;
  final int? viewCount;
  final int? favoriteCount;
  final int? chatCount;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool? isFavorited;
  final double? distanceKm;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.originalPrice,
    this.discount,
    this.mainImage,
    this.images = const [],
    this.condition,
    this.conditionText,
    this.categoryId,
    this.categoryName,
    this.categoryParentName,
    this.sellerId,
    this.sellerUsername,
    this.sellerAvatar,
    this.sellerVerified,
    this.sellerRating,
    this.locationCity,
    this.locationDistrict,
    this.status,
    this.viewCount,
    this.favoriteCount,
    this.chatCount,
    this.publishedAt,
    this.updatedAt,
    this.isFavorited,
    this.distanceKm,
  });
}

class PaginationEntity {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationEntity({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });
}

class ProductListEntity {
  final List<ProductEntity> items;
  final PaginationEntity pagination;

  const ProductListEntity({required this.items, required this.pagination});
}
