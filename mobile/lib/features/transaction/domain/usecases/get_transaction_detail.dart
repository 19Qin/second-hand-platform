import '../repositories/transaction_repository.dart';

class GetTransactionDetail {
  final TransactionRepository _repository;

  GetTransactionDetail(this._repository);

  Future<Map<String, dynamic>> call({
    required String transactionId,
  }) async {
    return await _repository.getTransactionDetail(
      transactionId: transactionId,
    );
  }
}
