import 'dart:convert';
import '../models/transaction_inquiry_model.dart';
import '../models/transaction_request_model.dart';
import '../models/transaction_model.dart';
import '../../../../core/network/api_client.dart';
import 'transaction_remote_data_source.dart';

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient _apiClient;

  TransactionRemoteDataSourceImpl(this._apiClient);

  @override
  Future<TransactionRequestResponse> createTransactionRequest({
    required String chatRoomId,
    required String productId,
    required String message,
  }) async {
    final request = {
      'chatRoomId': chatRoomId,
      'productId': productId,
      'message': message,
    };

    final data = await _apiClient.post(
      '/transactions/request',
      body: request,
    );

    return TransactionRequestResponse.fromJson(data);
  }

  @override
  Future<TransactionRespondResponse> respondToTransactionRequest({
    required String transactionId,
    required String action,
    String? reason,
  }) async {
    final request = {
      'action': action,
      if (reason != null) 'reason': reason,
    };

    final data = await _apiClient.post(
      '/transactions/$transactionId/respond',
      body: request,
    );

    return TransactionRespondResponse.fromJson(data);
  }

  @override
  Future<CreateInquiryResponse> createInquiry({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  }) async {
    final request = CreateInquiryRequest(
      productId: productId,
      sellerId: sellerId,
      message: message,
      inquiryType: inquiryType,
    );

    final data = await _apiClient.post(
      '/transactions/inquiry',
      body: request.toJson(),
    );

    return CreateInquiryResponse.fromJson(data);
  }

  @override
  Future<AgreeOfflineResponse> agreeOfflineTransaction({
    required String transactionId,
    required AgreeOfflineRequest request,
  }) async {
    final data = await _apiClient.post(
      '/transactions/$transactionId/agree-offline',
      body: request.toJson(),
    );

    return AgreeOfflineResponse.fromJson(data);
  }

  @override
  Future<CompleteTransactionResponse> completeTransaction({
    required String transactionId,
    required CompleteTransactionRequest request,
  }) async {
    final data = await _apiClient.post(
      '/transactions/$transactionId/complete',
      body: request.toJson(),
    );

    return CompleteTransactionResponse.fromJson(data);
  }

  @override
  Future<void> cancelTransaction({
    required String transactionId,
    required CancelTransactionRequest request,
  }) async {
    await _apiClient.post(
      '/transactions/$transactionId/cancel',
      body: request.toJson(),
    );
  }

  @override
  Future<TransactionListModel> getTransactions({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = <String, String>{
      'type': type,
      'status': status,
      'page': page.toString(),
      'size': size.toString(),
    };

    final data = await _apiClient.get(
      '/transactions',
      queryParameters: queryParams,
    );

    return TransactionListModel.fromJson(data);
  }

  @override
  Future<TransactionModel> getTransactionDetail({
    required String transactionId,
  }) async {
    final data = await _apiClient.get(
      '/transactions/$transactionId',
    );

    return TransactionModel.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> getTransactionCode({
    required String transactionId,
  }) async {
    final data = await _apiClient.get(
      '/transactions/$transactionId',
    );

    return data;
  }
}