import '../../domain/entities/transaction_inquiry.dart';

class TransactionModel {
  final String id;
  final String type; // BUY, SELL
  final String status; // PENDING, AGREED, COMPLETED, REJECTED, CANCELLED, EXPIRED
  final String statusText;
  final ProductModel product;
  final CounterpartModel counterpart;
  final DateTime transactionTime;
  final MeetingInfoModel? meetingInfo;
  final bool canRate;
  final int? rating;
  final String? transactionCode;
  final String? codeExpiresAt;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final String? cancelType;
  final String? feedback;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.statusText,
    required this.product,
    required this.counterpart,
    required this.transactionTime,
    this.meetingInfo,
    required this.canRate,
    this.rating,
    this.transactionCode,
    this.codeExpiresAt,
    this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelReason,
    this.cancelType,
    this.feedback,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'BUY',
      status: json['status']?.toString() ?? 'PENDING',
      statusText: json['statusText']?.toString() ?? '',
      product: ProductModel.fromJson(json['product'] ?? {}),
      counterpart: CounterpartModel.fromJson(json['counterpart'] ?? {}),
      transactionTime: json['transactionTime'] != null 
          ? DateTime.parse(json['transactionTime']) 
          : DateTime.now(),
      meetingInfo: json['meetingInfo'] != null 
          ? MeetingInfoModel.fromJson(json['meetingInfo']) 
          : null,
      canRate: json['canRate'] ?? false,
      rating: json['rating'],
      transactionCode: json['transactionCode']?.toString(),
      codeExpiresAt: json['codeExpiresAt']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      cancelReason: json['cancelReason']?.toString(),
      cancelType: json['cancelType']?.toString(),
      feedback: json['feedback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'statusText': statusText,
      'product': product.toJson(),
      'counterpart': counterpart.toJson(),
      'transactionTime': transactionTime.toIso8601String(),
      'meetingInfo': meetingInfo?.toJson(),
      'canRate': canRate,
      'rating': rating,
      'transactionCode': transactionCode,
      'codeExpiresAt': codeExpiresAt,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'cancelType': cancelType,
      'feedback': feedback,
    };
  }

  TransactionInquiryEntity toEntity() => TransactionInquiryEntity(
        transactionId: id,
        chatRoomId: '', // 这个字段在TransactionModel中不直接包含
        status: status,
      );
}

class ProductModel {
  final String id;
  final String title;
  final double price;
  final String mainImage;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.mainImage,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      mainImage: json['mainImage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'mainImage': mainImage,
    };
  }
}

class CounterpartModel {
  final String id;
  final String username;
  final String avatar;

  const CounterpartModel({
    required this.id,
    required this.username,
    required this.avatar,
  });

  factory CounterpartModel.fromJson(Map<String, dynamic> json) {
    return CounterpartModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
    };
  }
}

class MeetingInfoModel {
  final DateTime meetingTime;
  final String locationName;

  const MeetingInfoModel({
    required this.meetingTime,
    required this.locationName,
  });

  factory MeetingInfoModel.fromJson(Map<String, dynamic> json) {
    return MeetingInfoModel(
      meetingTime: DateTime.parse(json['meetingTime']),
      locationName: json['locationName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meetingTime': meetingTime.toIso8601String(),
      'locationName': locationName,
    };
  }
}

class TransactionListModel {
  final List<TransactionModel> transactions;
  final PaginationModel pagination;

  const TransactionListModel({
    required this.transactions,
    required this.pagination,
  });

  factory TransactionListModel.fromJson(Map<String, dynamic> json) {
    return TransactionListModel(
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((item) => TransactionModel.fromJson(item))
          .toList() ?? [],
      pagination: PaginationModel.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class PaginationModel {
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  const PaginationModel({
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
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

class CreateInquiryRequest {
  final String productId;
  final String sellerId;
  final String message;
  final String inquiryType;

  const CreateInquiryRequest({
    required this.productId,
    required this.sellerId,
    required this.message,
    this.inquiryType = 'PURCHASE',
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'message': message,
      'inquiryType': inquiryType,
    };
  }
}

class CreateInquiryResponse {
  final String transactionId;
  final String chatRoomId;
  final String status;

  const CreateInquiryResponse({
    required this.transactionId,
    required this.chatRoomId,
    required this.status,
  });

  factory CreateInquiryResponse.fromJson(Map<String, dynamic> json) {
    return CreateInquiryResponse(
      transactionId: json['transactionId']?.toString() ?? '',
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'INQUIRY',
    );
  }
}

class AgreeOfflineRequest {
  final String message;
  final DateTime meetingTime;
  final ContactInfoModel contactInfo;
  final MeetingLocationModel meetingLocation;
  final String? notes;

  const AgreeOfflineRequest({
    required this.message,
    required this.meetingTime,
    required this.contactInfo,
    required this.meetingLocation,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'meetingTime': meetingTime.toIso8601String(),
      'contactInfo': contactInfo.toJson(),
      'meetingLocation': meetingLocation.toJson(),
      if (notes != null) 'notes': notes,
    };
  }
}

class ContactInfoModel {
  final String contactName;
  final String contactPhone;

  const ContactInfoModel({
    required this.contactName,
    required this.contactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
  }
}

class MeetingLocationModel {
  final String locationName;
  final String detailAddress;
  final double longitude;
  final double latitude;

  const MeetingLocationModel({
    required this.locationName,
    required this.detailAddress,
    required this.longitude,
    required this.latitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'detailAddress': detailAddress,
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}

class AgreeOfflineResponse {
  final String transactionCode;
  final DateTime expiresAt;
  final MeetingInfoResponseModel meetingInfo;

  const AgreeOfflineResponse({
    required this.transactionCode,
    required this.expiresAt,
    required this.meetingInfo,
  });

  factory AgreeOfflineResponse.fromJson(Map<String, dynamic> json) {
    return AgreeOfflineResponse(
      transactionCode: json['transactionCode']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
      meetingInfo: MeetingInfoResponseModel.fromJson(json['meetingInfo']),
    );
  }
}

class MeetingInfoResponseModel {
  final DateTime meetingTime;
  final String locationName;
  final String contactName;
  final String contactPhone;

  const MeetingInfoResponseModel({
    required this.meetingTime,
    required this.locationName,
    required this.contactName,
    required this.contactPhone,
  });

  factory MeetingInfoResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingInfoResponseModel(
      meetingTime: DateTime.parse(json['meetingTime']),
      locationName: json['locationName']?.toString() ?? '',
      contactName: json['contactName']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
    );
  }
}

class CompleteTransactionRequest {
  final String transactionCode;
  final String? feedback;
  final int rating;

  const CompleteTransactionRequest({
    required this.transactionCode,
    this.feedback,
    required this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionCode': transactionCode,
      if (feedback != null) 'feedback': feedback,
      'rating': rating,
    };
  }
}

class CompleteTransactionResponse {
  final String transactionId;
  final String status;
  final DateTime completedAt;
  final String productStatus;

  const CompleteTransactionResponse({
    required this.transactionId,
    required this.status,
    required this.completedAt,
    required this.productStatus,
  });

  factory CompleteTransactionResponse.fromJson(Map<String, dynamic> json) {
    return CompleteTransactionResponse(
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      completedAt: DateTime.parse(json['completedAt']),
      productStatus: json['productStatus']?.toString() ?? '',
    );
  }
}

class CancelTransactionRequest {
  final String reason;
  final String cancelType;

  const CancelTransactionRequest({
    required this.reason,
    required this.cancelType,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'cancelType': cancelType,
    };
  }
}


