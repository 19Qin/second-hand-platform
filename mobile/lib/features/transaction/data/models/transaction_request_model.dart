import '../../domain/entities/transaction_inquiry.dart';

class TransactionRequestModel {
  final String transactionId;
  final String status;
  final String requestedAt;
  final String message;

  const TransactionRequestModel({
    required this.transactionId,
    required this.status,
    required this.requestedAt,
    required this.message,
  });

  factory TransactionRequestModel.fromJson(Map<String, dynamic> json) {
    return TransactionRequestModel(
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      requestedAt: json['requestedAt']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  TransactionInquiryEntity toEntity() => TransactionInquiryEntity(
        transactionId: transactionId,
        chatRoomId: '', // Will be set separately
        status: status,
      );
}

class TransactionRequestResponse {
  final String code;
  final String message;
  final TransactionRequestModel data;

  const TransactionRequestResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory TransactionRequestResponse.fromJson(Map<String, dynamic> json) {
    return TransactionRequestResponse(
      code: json['code']?.toString() ?? '200',
      message: json['message']?.toString() ?? '',
      data: TransactionRequestModel.fromJson(json['data'] ?? {}),
    );
  }
}

class TransactionRespondModel {
  final String transactionId;
  final String status;
  final String? transactionCode;
  final String? codeExpiresAt;
  final String? note;
  final String message;

  const TransactionRespondModel({
    required this.transactionId,
    required this.status,
    this.transactionCode,
    this.codeExpiresAt,
    this.note,
    required this.message,
  });

  factory TransactionRespondModel.fromJson(Map<String, dynamic> json) {
    return TransactionRespondModel(
      transactionId: json['transactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      transactionCode: json['transactionCode']?.toString(),
      codeExpiresAt: json['codeExpiresAt']?.toString(),
      note: json['note']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}

class TransactionRespondResponse {
  final String code;
  final String message;
  final TransactionRespondModel data;

  const TransactionRespondResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory TransactionRespondResponse.fromJson(Map<String, dynamic> json) {
    return TransactionRespondResponse(
      code: json['code']?.toString() ?? '200',
      message: json['message']?.toString() ?? '',
      data: TransactionRespondModel.fromJson(json['data'] ?? {}),
    );
  }
}


