import '../models/transaction_inquiry_model.dart';
import '../models/transaction_request_model.dart';
import '../models/transaction_model.dart';
import 'transaction_remote_data_source.dart';

/// 临时的Mock数据源，用于在等待新API期间保持UI可用
class TransactionMockDataSource implements TransactionRemoteDataSource {
  @override
  Future<TransactionRequestResponse> createTransactionRequest({
    required String chatRoomId,
    required String productId,
    required String message,
  }) async {
    return TransactionRequestResponse(
      code: '200',
      message: 'Transaction request sent',
      data: TransactionRequestModel(
        transactionId: 'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
        status: 'PENDING',
        requestedAt: DateTime.now().toIso8601String(),
        message: 'Transaction request sent, waiting for response',
      ),
    );
  }

  @override
  Future<TransactionRespondResponse> respondToTransactionRequest({
    required String transactionId,
    required String action,
    String? reason,
  }) async {
    return TransactionRespondResponse(
      code: '200',
      message: action == 'AGREE' ? 'Transaction request agreed' : 'Transaction request rejected',
      data: TransactionRespondModel(
        transactionId: transactionId,
        status: action == 'AGREE' ? 'AGREED' : 'REJECTED',
        transactionCode: action == 'AGREE' ? '1234' : null,
        codeExpiresAt: action == 'AGREE' ? DateTime.now().add(Duration(hours: 24)).toIso8601String() : null,
        note: action == 'AGREE' ? 'Please provide this code to the seller during the transaction' : null,
        message: action == 'AGREE' ? 'Transaction request agreed' : 'Transaction request rejected',
      ),
    );
  }

  @override
  Future<CreateInquiryResponse> createInquiry({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  }) async {
    // 返回一个模拟的交易咨询，避免UI崩溃
    return CreateInquiryResponse(
      transactionId: 'mock_transaction_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: 'mock_chat_${DateTime.now().millisecondsSinceEpoch}',
      status: 'INQUIRY',
    );
  }

  @override
  Future<AgreeOfflineResponse> agreeOfflineTransaction({
    required String transactionId,
    required AgreeOfflineRequest request,
  }) async {
    return AgreeOfflineResponse(
      transactionCode: '1234',
      expiresAt: DateTime.now().add(Duration(hours: 24)),
      meetingInfo: MeetingInfoResponseModel(
        meetingTime: request.meetingTime,
        locationName: request.meetingLocation.locationName,
        contactName: request.contactInfo.contactName,
        contactPhone: request.contactInfo.contactPhone,
      ),
    );
  }

  @override
  Future<CompleteTransactionResponse> completeTransaction({
    required String transactionId,
    required CompleteTransactionRequest request,
  }) async {
    return CompleteTransactionResponse(
      transactionId: transactionId,
      status: 'COMPLETED',
      completedAt: DateTime.now(),
      productStatus: 'SOLD',
    );
  }

  @override
  Future<void> cancelTransaction({
    required String transactionId,
    required CancelTransactionRequest request,
  }) async {
    // Mock implementation - do nothing
  }

  @override
  Future<TransactionListModel> getTransactions({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int size = 10,
  }) async {
    return TransactionListModel(
      transactions: [],
      pagination: PaginationModel(
        page: page,
        size: size,
        total: 0,
        hasNext: false,
      ),
    );
  }

  @override
  Future<TransactionModel> getTransactionDetail({
    required String transactionId,
  }) async {
    return TransactionModel(
      id: transactionId,
      type: 'BUY',
      status: 'INQUIRY',
      statusText: '咨询中',
      product: ProductModel(
        id: 'mock_product',
        title: 'Mock Product',
        price: 100.0,
        mainImage: 'mock_image.jpg',
      ),
      counterpart: CounterpartModel(
        id: 'mock_user',
        username: 'Mock User',
        avatar: 'mock_avatar.jpg',
      ),
      transactionTime: DateTime.now(),
      canRate: false,
    );
  }

  @override
  Future<Map<String, dynamic>> getTransactionCode({
    required String transactionId,
  }) async {
    // Mock implementation - return a fixed transaction code
    return {
      'transactionId': transactionId,
      'transactionCode': '1234',
      'codeExpiresAt': DateTime.now().add(Duration(hours: 24)).toIso8601String(),
      'note': 'Please provide this code to the seller during the transaction',
    };
  }
}

