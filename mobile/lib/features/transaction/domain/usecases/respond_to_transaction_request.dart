import '../repositories/transaction_repository.dart';

class RespondToTransactionRequest {
  final TransactionRepository _repository;

  RespondToTransactionRequest(this._repository);

  Future<Map<String, dynamic>> call({
    required String transactionId,
    required String action,
    String? reason,
  }) async {
    return await _repository.respondToTransactionRequest(
      transactionId: transactionId,
      action: action,
      reason: reason,
    );
  }
}


