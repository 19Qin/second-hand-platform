import '../models/transaction_inquiry_model.dart';
import '../models/transaction_request_model.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  /// 发起交易申请 [新接口]
  Future<TransactionRequestResponse> createTransactionRequest({
    required String chatRoomId,
    required String productId,
    required String message,
  });

  /// 响应交易申请 [新接口]
  Future<TransactionRespondResponse> respondToTransactionRequest({
    required String transactionId,
    required String action, // AGREE or REJECT
    String? reason,
  });

  /// 发起咨询/交易意向 [废弃]
  @Deprecated('Use createTransactionRequest instead')
  Future<CreateInquiryResponse> createInquiry({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  });

  /// 同意线下交易 [废弃]
  @Deprecated('Use respondToTransactionRequest instead')
  Future<AgreeOfflineResponse> agreeOfflineTransaction({
    required String transactionId,
    required AgreeOfflineRequest request,
  });

  /// 确认交易完成
  Future<CompleteTransactionResponse> completeTransaction({
    required String transactionId,
    required CompleteTransactionRequest request,
  });

  /// 取消交易
  Future<void> cancelTransaction({
    required String transactionId,
    required CancelTransactionRequest request,
  });

  /// 获取交易记录
  Future<TransactionListModel> getTransactions({
    String type = 'all', // buy, sell, all
    String status = 'all', // INQUIRY, AGREED, COMPLETED, CANCELLED, all
    int page = 1,
    int size = 10,
  });

  /// 获取交易详情
  Future<TransactionModel> getTransactionDetail({
    required String transactionId,
  });

  /// 获取交易码
  Future<Map<String, dynamic>> getTransactionCode({
    required String transactionId,
  });
}

