import '../repositories/transaction_repository.dart';

class CompleteTransaction {
  final TransactionRepository _repository;

  CompleteTransaction(this._repository);

  Future<Map<String, dynamic>> call({
    required String transactionId,
    required String transactionCode,
    String? feedback,
    required int rating,
  }) async {
    return await _repository.completeTransaction(
      transactionId: transactionId,
      transactionCode: transactionCode,
      feedback: feedback,
      rating: rating,
    );
  }
}


