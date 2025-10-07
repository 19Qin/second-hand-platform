import '../repositories/transaction_repository.dart';

class AgreeOfflineTransaction {
  final TransactionRepository _repository;

  AgreeOfflineTransaction(this._repository);

  Future<Map<String, dynamic>> call({
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
    return await _repository.agreeOfflineTransaction(
      transactionId: transactionId,
      message: message,
      meetingTime: meetingTime,
      contactName: contactName,
      contactPhone: contactPhone,
      locationName: locationName,
      detailAddress: detailAddress,
      longitude: longitude,
      latitude: latitude,
      notes: notes,
    );
  }
}


