import '../entities/transaction_inquiry.dart';
import '../repositories/transaction_repository.dart';

class CreateInquiry {
  final TransactionRepository repo;

  CreateInquiry(this.repo);

  Future<TransactionInquiryEntity> call({
    required String productId,
    required String sellerId,
    required String message,
    String inquiryType = 'PURCHASE',
  }) async {
    return await repo.createInquiry(
      productId: productId,
      sellerId: sellerId,
      message: message,
      inquiryType: inquiryType,
    );
  }
}

