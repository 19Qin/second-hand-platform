import '../entities/transaction_inquiry.dart';

abstract class TransactionRepository {
  /// 发起交易申请 [新接口]
  Future<Map<String, dynamic>> createTransactionRequest({
    required String chatRoomId,
    required String productId,
    required String message,
  });

  /// 响应交易申请 [新接口]
  Future<Map<String, dynamic>> respondToTransactionRequest({
    required String transactionId,
    required String action,
    String? reason,
  });

  /// 发起咨询/交易意向 [废弃]
  @Deprecated('Use createTransactionRequest instead')
  Future<TransactionInquiryEntity> createInquiry({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  });

  /// 同意线下交易
  Future<Map<String, dynamic>> agreeOfflineTransaction({
    required String transactionId,
    required String message,
    required DateTime meetingTime,
    required String contactName,
    required String contactPhone,
    required String locationName,
    required String detailAddress,
    required double longitude,
    required double latitude,
    String? notes,
  });

  /// 确认交易完成
  Future<Map<String, dynamic>> completeTransaction({
    required String transactionId,
    required String transactionCode,
    String? feedback,
    required int rating,
  });

  /// 取消交易
  Future<void> cancelTransaction({
    required String transactionId,
    required String reason,
    required String cancelType,
  });

  /// 获取交易记录
  Future<List<Map<String, dynamic>>> getTransactions({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int size = 10,
  });

  /// 获取交易详情
  Future<Map<String, dynamic>> getTransactionDetail({
    required String transactionId,
  });

  /// 获取交易码
  Future<Map<String, dynamic>> getTransactionCode({
    required String transactionId,
  });
}

