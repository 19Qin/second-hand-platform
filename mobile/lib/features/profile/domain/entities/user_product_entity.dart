class UserProductEntity {
  final String id;
  final String title;
  final double price;
  final String mainImage;
  final String status;
  final String statusText;
  final String publishTime;
  final UserProductStatsEntity stats;
  final List<String> actions;

  UserProductEntity({
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
}

class UserProductStatsEntity {
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final int inquiryCount;

  UserProductStatsEntity({
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.inquiryCount,
  });
}

class UserProductsResponseEntity {
  final List<UserProductEntity> products;
  final UserProductsSummaryEntity summary;
  final UserProductsPaginationEntity pagination;

  UserProductsResponseEntity({
    required this.products,
    required this.summary,
    required this.pagination,
  });
}

class UserProductsSummaryEntity {
  final int total;
  final int active;
  final int sold;
  final int inactive;

  UserProductsSummaryEntity({
    required this.total,
    required this.active,
    required this.sold,
    required this.inactive,
  });
}

class UserProductsPaginationEntity {
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  UserProductsPaginationEntity({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });
}






