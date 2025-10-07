import '../repositories/transaction_repository.dart';

class GetTransactions {
  final TransactionRepository _repository;

  GetTransactions(this._repository);

  Future<List<Map<String, dynamic>>> call({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int size = 10,
  }) async {
    return await _repository.getTransactions(
      type: type,
      status: status,
      page: page,
      size: size,
    );
  }
}


