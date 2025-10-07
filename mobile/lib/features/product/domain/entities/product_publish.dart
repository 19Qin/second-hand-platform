class ProductPublishRequestEntity {
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int categoryId;
  final List<String> images;
  final String condition;
  final UsageInfoRequestEntity? usageInfo;
  final WarrantyInfoRequestEntity? warranty;
  final LocationInfoRequestEntity? location;
  final List<String> tags;

  const ProductPublishRequestEntity({
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.categoryId,
    required this.images,
    required this.condition,
    this.usageInfo,
    this.warranty,
    this.location,
    this.tags = const [],
  });
}

class UsageInfoRequestEntity {
  final String type; // TIME, COUNT, OTHER
  final int value;
  final String unit; // MONTH, YEAR, etc.

  const UsageInfoRequestEntity({
    required this.type,
    required this.value,
    required this.unit,
  });
}

class WarrantyInfoRequestEntity {
  final bool hasWarranty;
  final String? warrantyType; // OFFICIAL, STORE, NONE
  final int? remainingMonths;
  final String? description;

  const WarrantyInfoRequestEntity({
    required this.hasWarranty,
    this.warrantyType,
    this.remainingMonths,
    this.description,
  });
}

class LocationInfoRequestEntity {
  final String province;
  final String city;
  final String district;
  final String? detailAddress;
  final double? longitude;
  final double? latitude;

  const LocationInfoRequestEntity({
    required this.province,
    required this.city,
    required this.district,
    this.detailAddress,
    this.longitude,
    this.latitude,
  });
}

class ProductPublishResponseEntity {
  final String productId;
  final String status;
  final DateTime publishTime;

  const ProductPublishResponseEntity({
    required this.productId,
    required this.status,
    required this.publishTime,
  });
}
