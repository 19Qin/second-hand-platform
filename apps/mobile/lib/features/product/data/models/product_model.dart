import '../../domain/entities/product.dart';

class ProductModel {
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

  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final cat = j['category'] as Map<String, dynamic>?;
    final seller = j['seller'] as Map<String, dynamic>?;
    final loc = j['location'] as Map<String, dynamic>?;

    return ProductModel(
      id: j['id'].toString(),
      title: j['title'] as String,
      description: j['description'] as String?,
      price: (j['price'] as num).toDouble(),
      originalPrice: (j['originalPrice'] as num?)?.toDouble(),
      discount: j['discount'] as int?,
      mainImage: j['mainImage'] as String?,
      images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      condition: j['condition'] as String?,
      conditionText: j['conditionText'] as String?,
      categoryId: cat?['id'] as int?,
      categoryName: cat?['name'] as String?,
      categoryParentName: cat?['parentName'] as String?,
      sellerId: (seller?['id']) == null ? null : int.tryParse(seller!['id'].toString()),
      sellerUsername: seller?['username'] as String?,
      sellerAvatar: seller?['avatar'] as String?,
      sellerVerified: seller?['verified'] as bool?,
      sellerRating: (seller?['rating'] as num?)?.toDouble(),
      locationCity: loc?['city'] as String?,
      locationDistrict: loc?['district'] as String?,
      status: j['status'] as String?,
      viewCount: j['viewCount'] as int?,
      favoriteCount: j['favoriteCount'] as int?,
      chatCount: j['chatCount'] as int?,
      publishedAt: j['publishedAt'] != null ? DateTime.tryParse(j['publishedAt']) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt']) : null,
      isFavorited: j['isFavorited'] as bool?,
      distanceKm: (j['distance'] as num?)?.toDouble(),
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
        categoryParentName: categoryParentName,
        sellerId: sellerId,
        sellerUsername: sellerUsername,
        sellerAvatar: sellerAvatar,
        sellerVerified: sellerVerified,
        sellerRating: sellerRating,
        locationCity: locationCity,
        locationDistrict: locationDistrict,
        status: status,
        viewCount: viewCount,
        favoriteCount: favoriteCount,
        chatCount: chatCount,
        publishedAt: publishedAt,
        updatedAt: updatedAt,
        isFavorited: isFavorited,
        distanceKm: distanceKm,
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
        hasPrev: j['hasPrev'] as bool,
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

  ProductListResponseModel({required this.items, required this.pagination});

  factory ProductListResponseModel.fromJson(Map<String, dynamic> root) {
    final data = root['data'] as Map<String, dynamic>;
    final itemsJson = (data['items'] as List?) ?? const [];
    final items = itemsJson
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = PaginationModel.fromJson(data['pagination'] as Map<String, dynamic>);
    return ProductListResponseModel(items: items, pagination: pagination);
  }

  ProductListEntity toEntity() => ProductListEntity(
        items: items.map((m) => m.toEntity()).toList(),
        pagination: pagination.toEntity(),
      );
}
