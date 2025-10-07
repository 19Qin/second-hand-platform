import '../repositories/transaction_repository.dart';

class CreateTransactionRequest {
  final TransactionRepository _repository;

  CreateTransactionRequest(this._repository);

  Future<Map<String, dynamic>> call({
    required String chatRoomId,
    required String productId,
    required String message,
  }) async {
    return await _repository.createTransactionRequest(
      chatRoomId: chatRoomId,
      productId: productId,
      message: message,
    );
  }
}


