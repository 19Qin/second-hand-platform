import '../../domain/entities/product.dart';

class ProductModel {
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
  final UsageInfoModel? usageInfo;
  final WarrantyInfoModel? warranty;
  final List<String> tags;
  final SellerInfoModel? seller;
  final ProductStatsModel? stats;
  final List<RelatedProductModel>? relatedProducts;

  ProductModel({
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

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final cat = j['category'] as Map<String, dynamic>?;
    final seller = j['seller'] as Map<String, dynamic>?;
    
    // Handle location - can be either string (in list) or object (in detail)
    final locationData = j['location'];
    final loc = locationData is Map<String, dynamic> ? locationData : null;
    final locationString = locationData is String ? locationData : null;
    
    final usage = j['usageInfo'] as Map<String, dynamic>?;
    final warranty = j['warranty'] as Map<String, dynamic>?;
    final stats = j['stats'] as Map<String, dynamic>?;
    final relatedProducts = j['relatedProducts'] as List?;

    return ProductModel(
      id: j['id'].toString(),
      title: j['title'] as String,
      description: j['description'] as String?,
      price: (j['price'] as num).toDouble(),
      originalPrice: (j['originalPrice'] as num?)?.toDouble(),
      discount: j['discount'] as String?,
      mainImage: j['mainImage'] as String?,
      images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      condition: j['condition'] as String?,
      conditionText: j['conditionText'] as String?,
      categoryId: j['categoryId'] as int? ?? cat?['id'] as int?,
      categoryName: j['categoryName'] as String? ?? cat?['name'] as String?,
      categoryPath: j['categoryPath'] as String? ?? cat?['breadcrumb'] as String?,
      sellerId: seller?['id']?.toString(),
      sellerUsername: seller?['username'] as String?,
      sellerAvatar: seller?['avatar'] as String?,
      sellerVerified: seller?['verified'] as bool?,
      sellerRating: (seller?['rating'] as num?)?.toDouble(),
      locationCity: loc?['city'] as String? ?? locationString,
      locationDistrict: loc?['district'] as String?,
      locationDetail: loc?['detailAddress'] as String?,
      locationDisplay: loc?['displayText'] as String? ?? locationString,
      status: j['status'] as String?,
      viewCount: stats?['viewCount'] as int?,
      favoriteCount: stats?['favoriteCount'] as int?,
      chatCount: stats?['chatCount'] as int?,
      publishedAt: j['publishTime'] != null ? DateTime.tryParse(j['publishTime'].toString()) : null, // API uses 'publishTime'
      updatedAt: j['updatedTime'] != null ? DateTime.tryParse(j['updatedTime'].toString()) : null, // API uses 'updatedTime'
      isFavorited: stats?['isFavorited'] as bool?,
      distanceKm: j['distance'] != null ? double.tryParse(j['distance'].toString()) : null,
      usageInfo: usage != null ? UsageInfoModel.fromJson(usage) : null,
      warranty: warranty != null ? WarrantyInfoModel.fromJson(warranty) : null,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      seller: seller != null ? SellerInfoModel.fromJson(seller) : null,
      stats: stats != null ? ProductStatsModel.fromJson(stats) : null,
      relatedProducts: relatedProducts?.map((e) => RelatedProductModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  ProductEntity toEntity() => ProductEntity(
        id: id,
        title: title,
        description: description,
        price: price,
        originalPrice: originalPrice,
        discount: discount,
        mainImage: mainImage,
        images: images,
        condition: condition,
        conditionText: conditionText,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryPath: categoryPath,
        sellerId: sellerId,
        sellerUsername: sellerUsername,
        sellerAvatar: sellerAvatar,
        sellerVerified: sellerVerified,
        sellerRating: sellerRating,
        locationCity: locationCity,
        locationDistrict: locationDistrict,
        locationDetail: locationDetail,
        locationDisplay: locationDisplay,
        status: status,
        viewCount: viewCount,
        favoriteCount: favoriteCount,
        chatCount: chatCount,
        publishedAt: publishedAt,
        updatedAt: updatedAt,
        isFavorited: isFavorited,
        distanceKm: distanceKm,
        usageInfo: usageInfo?.toEntity(),
        warranty: warranty?.toEntity(),
        tags: tags,
        seller: seller?.toEntity(),
        stats: stats?.toEntity(),
        relatedProducts: relatedProducts?.map((e) => e.toEntity()).toList(),
      );
}

class PaginationModel {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationModel({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> j) => PaginationModel(
        page: j['page'] as int,
        size: j['size'] as int,
        total: j['total'] as int,
        totalPages: j['totalPages'] as int,
        hasNext: j['hasNext'] as bool,
        hasPrev: j['hasPrevious'] as bool? ?? false, // Backend returns hasPrevious
      );

  PaginationEntity toEntity() => PaginationEntity(
        page: page,
        size: size,
        total: total,
        totalPages: totalPages,
        hasNext: hasNext,
        hasPrev: hasPrev,
      );
}

class ProductListResponseModel {
  final List<ProductModel> items;
  final PaginationModel pagination;
  final ProductFiltersModel? filters;

  ProductListResponseModel({
    required this.items, 
    required this.pagination,
    this.filters,
  });

  factory ProductListResponseModel.fromJson(Map<String, dynamic> root) {
    final data = root['data'] as Map<String, dynamic>;
    // Backend actually returns 'content', not 'products'
    final itemsJson = (data['content'] as List?) ?? const [];
    final items = itemsJson
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = PaginationModel.fromJson(data['pagination'] as Map<String, dynamic>);
    final filters = data['filters'] != null 
        ? ProductFiltersModel.fromJson(data['filters'] as Map<String, dynamic>)
        : null;
    return ProductListResponseModel(
      items: items, 
      pagination: pagination,
      filters: filters,
    );
  }

  ProductListEntity toEntity() => ProductListEntity(
        items: items.map((m) => m.toEntity()).toList(),
        pagination: pagination.toEntity(),
        filters: filters?.toEntity(),
      );
}

// New models for additional fields
class UsageInfoModel {
  final String type; // TIME, COUNT, OTHER
  final int value;
  final String unit; // MONTH, YEAR, etc.
  final String displayText;

  UsageInfoModel({
    required this.type,
    required this.value,
    required this.unit,
    required this.displayText,
  });

  factory UsageInfoModel.fromJson(Map<String, dynamic> j) => UsageInfoModel(
        type: j['type'] as String,
        value: j['value'] as int,
        unit: j['unit'] as String,
        displayText: j['displayText'] as String,
      );

  UsageInfoEntity toEntity() => UsageInfoEntity(
        type: type,
        value: value,
        unit: unit,
        displayText: displayText,
      );
}

class WarrantyInfoModel {
  final bool hasWarranty;
  final String? warrantyType; // OFFICIAL, STORE, NONE
  final int? remainingMonths;
  final String? description;
  final String? displayText;

  WarrantyInfoModel({
    required this.hasWarranty,
    this.warrantyType,
    this.remainingMonths,
    this.description,
    this.displayText,
  });

  factory WarrantyInfoModel.fromJson(Map<String, dynamic> j) => WarrantyInfoModel(
        hasWarranty: j['hasWarranty'] as bool,
        warrantyType: j['warrantyType'] as String?,
        remainingMonths: j['remainingMonths'] as int?,
        description: j['description'] as String?,
        displayText: j['displayText'] as String?,
      );

  WarrantyInfoEntity toEntity() => WarrantyInfoEntity(
        hasWarranty: hasWarranty,
        warrantyType: warrantyType,
        remainingMonths: remainingMonths,
        description: description,
        displayText: displayText,
      );
}

class SellerInfoModel {
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

  SellerInfoModel({
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

  factory SellerInfoModel.fromJson(Map<String, dynamic> j) => SellerInfoModel(
        id: j['id'].toString(),
        username: j['username'] as String,
        avatar: j['avatar'] as String,
        verified: j['verified'] as bool? ?? false,
        registeredDays: j['registeredDays'] as int? ?? 0,
        totalProducts: j['totalProducts'] as int? ?? 0,
        soldCount: j['soldCount'] as int? ?? 0,
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: j['reviewCount'] as int? ?? 0,
        responseRate: j['responseRate'] as String? ?? '0%',
        avgResponseTime: j['avgResponseTime'] as String? ?? '未知',
      );

  SellerInfoEntity toEntity() => SellerInfoEntity(
        id: id,
        username: username,
        avatar: avatar,
        verified: verified,
        registeredDays: registeredDays,
        totalProducts: totalProducts,
        soldCount: soldCount,
        rating: rating,
        reviewCount: reviewCount,
        responseRate: responseRate,
        avgResponseTime: avgResponseTime,
      );
}

class ProductStatsModel {
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final bool isOwn;
  final bool isFavorited;

  ProductStatsModel({
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.isOwn,
    required this.isFavorited,
  });

  factory ProductStatsModel.fromJson(Map<String, dynamic> j) => ProductStatsModel(
        viewCount: j['viewCount'] as int,
        favoriteCount: j['favoriteCount'] as int,
        chatCount: j['chatCount'] as int,
        isOwn: j['isOwn'] as bool,
        isFavorited: j['isFavorited'] as bool,
      );

  ProductStatsEntity toEntity() => ProductStatsEntity(
        viewCount: viewCount,
        favoriteCount: favoriteCount,
        chatCount: chatCount,
        isOwn: isOwn,
        isFavorited: isFavorited,
      );
}

class RelatedProductModel {
  final String id;
  final String title;
  final double price;
  final String mainImage;
  final String? condition;

  RelatedProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.mainImage,
    this.condition,
  });

  factory RelatedProductModel.fromJson(Map<String, dynamic> j) => RelatedProductModel(
        id: j['id'].toString(),
        title: j['title'] as String,
        price: (j['price'] as num).toDouble(),
        mainImage: j['mainImage'] as String,
        condition: j['condition'] as String?,
      );

  RelatedProductEntity toEntity() => RelatedProductEntity(
        id: id,
        title: title,
        price: price,
        mainImage: mainImage,
        condition: condition,
      );
}

class ProductFiltersModel {
  final String? filter;
  final String? filterText;
  final String? category;
  final String? priceRange;
  final String? condition;
  final String? location;

  ProductFiltersModel({
    this.filter,
    this.filterText,
    this.category,
    this.priceRange,
    this.condition,
    this.location,
  });

  factory ProductFiltersModel.fromJson(Map<String, dynamic> j) => ProductFiltersModel(
        filter: j['filter'] as String?,
        filterText: j['filterText'] as String?,
        category: j['category'] as String?,
        priceRange: j['priceRange'] as String?,
        condition: j['condition'] as String?,
        location: j['location'] as String?,
      );

  ProductFiltersEntity toEntity() => ProductFiltersEntity(
        filter: filter,
        filterText: filterText,
        category: category,
        priceRange: priceRange,
        condition: condition,
        location: location,
      );
}
