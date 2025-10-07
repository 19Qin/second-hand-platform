class UserProductModel {
  final String id;
  final String title;
  final double price;
  final String mainImage;
  final String status;
  final String statusText;
  final String publishTime;
  final UserProductStats stats;
  final List<String> actions;

  UserProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.mainImage,
    required this.status,
    required this.statusText,
    required this.publishTime,
    required this.stats,
    required this.actions,
  });

  factory UserProductModel.fromJson(Map<String, dynamic> json) {
    return UserProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      mainImage: json['mainImage'] ?? '',
      status: json['status'] ?? 'UNKNOWN', // 默认值
      statusText: json['statusText'] ?? 'Unknown', // 默认值
      publishTime: json['publishTime'] ?? '',
      stats: UserProductStats.fromJson(json['stats'] ?? {}),
      actions: List<String>.from(json['actions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'mainImage': mainImage,
      'status': status,
      'statusText': statusText,
      'publishTime': publishTime,
      'stats': stats.toJson(),
      'actions': actions,
    };
  }
}

class UserProductStats {
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final int inquiryCount;

  UserProductStats({
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.inquiryCount,
  });

  factory UserProductStats.fromJson(Map<String, dynamic> json) {
    return UserProductStats(
      viewCount: json['viewCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      chatCount: json['chatCount'] ?? 0,
      inquiryCount: json['inquiryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'chatCount': chatCount,
      'inquiryCount': inquiryCount,
    };
  }
}

class UserProductsResponseModel {
  final List<UserProductModel> products;
  final UserProductsSummary summary;
  final UserProductsPagination pagination;

  UserProductsResponseModel({
    required this.products,
    required this.summary,
    required this.pagination,
  });

  factory UserProductsResponseModel.fromJson(Map<String, dynamic> json) {
    return UserProductsResponseModel(
      products: (json['products'] as List<dynamic>?)
          ?.map((item) => UserProductModel.fromJson(item))
          .toList() ?? [],
      summary: UserProductsSummary.fromJson(json['summary'] ?? {}),
      pagination: UserProductsPagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'summary': summary.toJson(),
      'pagination': pagination.toJson(),
    };
  }
}

class UserProductsSummary {
  final int total;
  final int active;
  final int sold;
  final int inactive;

  UserProductsSummary({
    required this.total,
    required this.active,
    required this.sold,
    required this.inactive,
  });

  factory UserProductsSummary.fromJson(Map<String, dynamic> json) {
    return UserProductsSummary(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      sold: json['sold'] ?? 0,
      inactive: json['inactive'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'sold': sold,
      'inactive': inactive,
    };
  }
}

class UserProductsPagination {
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  UserProductsPagination({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });

  factory UserProductsPagination.fromJson(Map<String, dynamic> json) {
    return UserProductsPagination(
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'total': total,
      'hasNext': hasNext,
    };
  }
}




