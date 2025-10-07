import '../repositories/transaction_repository.dart';

class GetTransactionCode {
  final TransactionRepository _repository;

  GetTransactionCode(this._repository);

  Future<Map<String, dynamic>> call({
    required String transactionId,
  }) async {
    return await _repository.getTransactionCode(
      transactionId: transactionId,
    );
  }
}
