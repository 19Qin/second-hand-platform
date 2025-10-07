class ProductEntity {
  final String id;
  final String title;
  final String? description;
  final double price;
  final double? originalPrice;
  final String? discount; // Changed from int to String (e.g., "85折")
  final String? mainImage;
  final List<String> images;
  final String? condition;
  final String? conditionText;
  final int? categoryId;
  final String? categoryName;
  final String? categoryPath; // Added category path (e.g., "电子产品 > 手机")
  final String? sellerId;
  final String? sellerUsername;
  final String? sellerAvatar;
  final bool? sellerVerified;
  final double? sellerRating;
  final String? locationCity;
  final String? locationDistrict;
  final String? locationDetail; // Added detailed location
  final String? locationDisplay; // Added display text for location
  final String? status;
  final int? viewCount;
  final int? favoriteCount;
  final int? chatCount;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool? isFavorited;
  final double? distanceKm;
  
  // New fields from API
  final UsageInfoEntity? usageInfo;
  final WarrantyInfoEntity? warranty;
  final List<String> tags;
  final SellerInfoEntity? seller;
  final ProductStatsEntity? stats;
  final List<RelatedProductEntity>? relatedProducts;

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
    this.categoryPath,
    this.sellerId,
    this.sellerUsername,
    this.sellerAvatar,
    this.sellerVerified,
    this.sellerRating,
    this.locationCity,
    this.locationDistrict,
    this.locationDetail,
    this.locationDisplay,
    this.status,
    this.viewCount,
    this.favoriteCount,
    this.chatCount,
    this.publishedAt,
    this.updatedAt,
    this.isFavorited,
    this.distanceKm,
    this.usageInfo,
    this.warranty,
    this.tags = const [],
    this.seller,
    this.stats,
    this.relatedProducts,
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
  final ProductFiltersEntity? filters;

  const ProductListEntity({
    required this.items, 
    required this.pagination,
    this.filters,
  });
}

// New entities for additional fields
class UsageInfoEntity {
  final String type; // TIME, COUNT, OTHER
  final int value;
  final String unit; // MONTH, YEAR, etc.
  final String displayText;

  const UsageInfoEntity({
    required this.type,
    required this.value,
    required this.unit,
    required this.displayText,
  });
}

class WarrantyInfoEntity {
  final bool hasWarranty;
  final String? warrantyType; // OFFICIAL, STORE, NONE
  final int? remainingMonths;
  final String? description;
  final String? displayText;

  const WarrantyInfoEntity({
    required this.hasWarranty,
    this.warrantyType,
    this.remainingMonths,
    this.description,
    this.displayText,
  });
}

class SellerInfoEntity {
  final String id;
  final String username;
  final String avatar;
  final bool verified;
  final int registeredDays;
  final int totalProducts;
  final int soldCount;
  final double rating;
  final int reviewCount;
  final String responseRate;
  final String avgResponseTime;

  const SellerInfoEntity({
    required this.id,
    required this.username,
    required this.avatar,
    required this.verified,
    required this.registeredDays,
    required this.totalProducts,
    required this.soldCount,
    required this.rating,
    required this.reviewCount,
    required this.responseRate,
    required this.avgResponseTime,
  });
}

class ProductStatsEntity {
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final bool isOwn;
  final bool isFavorited;

  const ProductStatsEntity({
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.isOwn,
    required this.isFavorited,
  });
}

class RelatedProductEntity {
  final String id;
  final String title;
  final double price;
  final String mainImage;
  final String? condition;

  const RelatedProductEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.mainImage,
    this.condition,
  });
}

class ProductFiltersEntity {
  final String? filter;
  final String? filterText;
  final String? category;
  final String? priceRange;
  final String? condition;
  final String? location;

  const ProductFiltersEntity({
    this.filter,
    this.filterText,
    this.category,
    this.priceRange,
    this.condition,
    this.location,
  });
}
