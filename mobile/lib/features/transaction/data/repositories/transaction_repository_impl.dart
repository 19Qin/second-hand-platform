import '../../domain/entities/transaction_inquiry.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remote;

  TransactionRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> createTransactionRequest({
    required String chatRoomId,
    required String productId,
    required String message,
  }) async {
    try {
      final response = await remote.createTransactionRequest(
        chatRoomId: chatRoomId,
        productId: productId,
        message: message,
      );
      return {
        'transactionId': response.data.transactionId,
        'status': response.data.status,
        'requestedAt': response.data.requestedAt,
        'message': response.data.message,
      };
    } catch (e) {
      throw Exception('发起交易申请失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> respondToTransactionRequest({
    required String transactionId,
    required String action,
    String? reason,
  }) async {
    try {
      final response = await remote.respondToTransactionRequest(
        transactionId: transactionId,
        action: action,
        reason: reason,
      );
      return {
        'transactionId': response.data.transactionId,
        'status': response.data.status,
        'transactionCode': response.data.transactionCode,
        'codeExpiresAt': response.data.codeExpiresAt,
        'note': response.data.note,
        'message': response.data.message,
      };
    } catch (e) {
      throw Exception('响应交易申请失败: $e');
    }
  }

  @override
  Future<TransactionInquiryEntity> createInquiry({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  }) async {
    try {
      final response = await remote.createInquiry(
        productId: productId,
        sellerId: sellerId,
        message: message,
        inquiryType: inquiryType,
      );
      return TransactionInquiryEntity(
        transactionId: response.transactionId,
        chatRoomId: response.chatRoomId,
        status: response.status,
      );
    } catch (e) {
      throw Exception('创建咨询失败: $e');
    }
  }

  @override
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
  }) async {
    try {
      final request = AgreeOfflineRequest(
        message: message,
        meetingTime: meetingTime,
        contactInfo: ContactInfoModel(
          contactName: contactName,
          contactPhone: contactPhone,
        ),
        meetingLocation: MeetingLocationModel(
          locationName: locationName,
          detailAddress: detailAddress,
          longitude: longitude,
          latitude: latitude,
        ),
        notes: notes,
      );

      final response = await remote.agreeOfflineTransaction(
        transactionId: transactionId,
        request: request,
      );

      return {
        'transactionCode': response.transactionCode,
        'expiresAt': response.expiresAt,
        'meetingInfo': {
          'meetingTime': response.meetingInfo.meetingTime,
          'locationName': response.meetingInfo.locationName,
          'contactName': response.meetingInfo.contactName,
          'contactPhone': response.meetingInfo.contactPhone,
        },
      };
    } catch (e) {
      throw Exception('同意线下交易失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeTransaction({
    required String transactionId,
    required String transactionCode,
    String? feedback,
    required int rating,
  }) async {
    try {
      final request = CompleteTransactionRequest(
        transactionCode: transactionCode,
        feedback: feedback,
        rating: rating,
      );

      final response = await remote.completeTransaction(
        transactionId: transactionId,
        request: request,
      );

      return {
        'transactionId': response.transactionId,
        'status': response.status,
        'completedAt': response.completedAt,
        'productStatus': response.productStatus,
      };
    } catch (e) {
      throw Exception('确认交易完成失败: $e');
    }
  }

  @override
  Future<void> cancelTransaction({
    required String transactionId,
    required String reason,
    required String cancelType,
  }) async {
    try {
      final request = CancelTransactionRequest(
        reason: reason,
        cancelType: cancelType,
      );

      await remote.cancelTransaction(
        transactionId: transactionId,
        request: request,
      );
    } catch (e) {
      throw Exception('取消交易失败: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int size = 10,
  }) async {
    try {
      final model = await remote.getTransactions(
        type: type,
        status: status,
        page: page,
        size: size,
      );

      return model.transactions.map((transaction) => {
        'id': transaction.id,
        'type': transaction.type,
        'status': transaction.status,
        'statusText': transaction.statusText,
        'product': {
          'id': transaction.product.id,
          'title': transaction.product.title,
          'price': transaction.product.price,
          'mainImage': transaction.product.mainImage,
        },
        'counterpart': {
          'id': transaction.counterpart.id,
          'username': transaction.counterpart.username,
          'avatar': transaction.counterpart.avatar,
        },
        'transactionTime': transaction.transactionTime,
        'meetingInfo': transaction.meetingInfo?.toJson(),
        'canRate': transaction.canRate,
        'rating': transaction.rating,
      }).toList();
    } catch (e) {
      throw Exception('获取交易记录失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionDetail({
    required String transactionId,
  }) async {
    try {
      final model = await remote.getTransactionDetail(
        transactionId: transactionId,
      );

      return {
        'id': model.id,
        'type': model.type,
        'status': model.status,
        'statusText': model.statusText,
        'product': model.product.toJson(),
        'counterpart': model.counterpart.toJson(),
        'transactionTime': model.transactionTime,
        'meetingInfo': model.meetingInfo?.toJson(),
        'canRate': model.canRate,
        'rating': model.rating,
      };
    } catch (e) {
      throw Exception('获取交易详情失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTransactionCode({
    required String transactionId,
  }) async {
    try {
      final response = await remote.getTransactionCode(
        transactionId: transactionId,
      );

      return {
        'transactionId': response['transactionId'],
        'transactionCode': response['transactionCode'],
        'codeExpiresAt': response['codeExpiresAt'],
        'note': response['note'],
      };
    } catch (e) {
      throw Exception('获取交易码失败: $e');
    }
  }
}

