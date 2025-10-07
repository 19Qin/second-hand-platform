import '../../domain/entities/product_publish.dart';

class ProductPublishRequestModel {
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int categoryId;
  final List<String> images;
  final String condition;
  final UsageInfoRequestModel? usageInfo;
  final WarrantyInfoRequestModel? warranty;
  final LocationInfoRequestModel? location;
  final List<String> tags;

  ProductPublishRequestModel({
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

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'price': price,
      'categoryId': categoryId,
      'images': images,
      'condition': condition,
    };
    
    // 必填字段：location
    if (location != null) {
      json['location'] = location!.toJson();
    }
    
    // 可选字段：只在有值时添加
    if (description.isNotEmpty) {
      json['description'] = description;
    }
    
    if (originalPrice != null && originalPrice! > 0) {
      json['originalPrice'] = originalPrice;
    }
    
    if (usageInfo != null) {
      json['usageInfo'] = usageInfo!.toJson();
    }
    
    if (warranty != null) {
      json['warranty'] = warranty!.toJson();
    }
    
    // tags如果为空数组，可能不发送更好
    if (tags.isNotEmpty) {
      json['tags'] = tags;
    }
    
    return json;
  }

  // 创建最简化版本的JSON（用于调试）
  Map<String, dynamic> toMinimalJson() {
    return {
      'title': title,
      'price': price,
      'categoryId': categoryId,
      'images': images,
      'condition': condition,
      'location': location?.toJson() ?? {
        'province': '北京市',
        'city': '北京市',
        'district': '朝阳区',
      },
    };
  }

  ProductPublishRequestEntity toEntity() => ProductPublishRequestEntity(
        title: title,
        description: description,
        price: price,
        originalPrice: originalPrice,
        categoryId: categoryId,
        images: images,
        condition: condition,
        usageInfo: usageInfo?.toEntity(),
        warranty: warranty?.toEntity(),
        location: location?.toEntity(),
        tags: tags,
      );
}

class UsageInfoRequestModel {
  final String type; // TIME, COUNT, OTHER
  final int value;
  final String? unit; // MONTH, YEAR, etc. (nullable for COUNT/OTHER)

  UsageInfoRequestModel({
    required this.type,
    required this.value,
    this.unit, // 可选字段
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'value': value,
    };
    
    // 只有当type为TIME且unit不为null时才添加unit字段
    if (type == 'TIME' && unit != null) {
      json['unit'] = unit;
    }
    
    return json;
  }

  UsageInfoRequestEntity toEntity() => UsageInfoRequestEntity(
        type: type,
        value: value,
        unit: unit ?? '', // 提供默认值
      );
}

class WarrantyInfoRequestModel {
  final bool hasWarranty;
  final String? warrantyType; // OFFICIAL, STORE, NONE
  final int? remainingMonths;
  final String? description;

  WarrantyInfoRequestModel({
    required this.hasWarranty,
    this.warrantyType,
    this.remainingMonths,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasWarranty': hasWarranty,
      'warrantyType': warrantyType ?? (hasWarranty ? 'OFFICIAL' : 'NONE'),
      'remainingMonths': remainingMonths ?? (hasWarranty ? 12 : 0),
      'description': description ?? (hasWarranty ? null : '已过保修期，但功能完好'),
    };
  }

  WarrantyInfoRequestEntity toEntity() => WarrantyInfoRequestEntity(
        hasWarranty: hasWarranty,
        warrantyType: warrantyType,
        remainingMonths: remainingMonths,
        description: description,
      );
}

class LocationInfoRequestModel {
  final String province;
  final String city;
  final String district;
  final String? detailAddress;
  final double? longitude;
  final double? latitude;

  LocationInfoRequestModel({
    required this.province,
    required this.city,
    required this.district,
    this.detailAddress,
    this.longitude,
    this.latitude,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'province': province,
      'city': city,
      'district': district,
    };
    
    // 可选字段：只在有值时添加
    if (detailAddress != null && detailAddress!.isNotEmpty) {
      json['detailAddress'] = detailAddress;
    }
    
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    
    return json;
  }

  LocationInfoRequestEntity toEntity() => LocationInfoRequestEntity(
        province: province,
        city: city,
        district: district,
        detailAddress: detailAddress,
        longitude: longitude,
        latitude: latitude,
      );
}

class ProductPublishResponseModel {
  final String productId;
  final String status;
  final DateTime publishTime;

  ProductPublishResponseModel({
    required this.productId,
    required this.status,
    required this.publishTime,
  });

  factory ProductPublishResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductPublishResponseModel(
      productId: json['productId'].toString(),
      status: json['status'] as String,
      publishTime: DateTime.parse(json['publishTime'] as String),
    );
  }

  ProductPublishResponseEntity toEntity() => ProductPublishResponseEntity(
        productId: productId,
        status: status,
        publishTime: publishTime,
      );
}
