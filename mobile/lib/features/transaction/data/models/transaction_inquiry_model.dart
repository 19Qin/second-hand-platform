import '../../domain/entities/transaction_inquiry.dart';

class TransactionInquiryModel {
  final String transactionId;
  final String chatRoomId;
  final String status;

  const TransactionInquiryModel({
    required this.transactionId,
    required this.chatRoomId,
    required this.status,
  });

  factory TransactionInquiryModel.fromJson(Map<String, dynamic> json) {
    return TransactionInquiryModel(
      transactionId: json['transactionId']?.toString() ?? '',
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'INQUIRY',
    );
  }

  TransactionInquiryEntity toEntity() => TransactionInquiryEntity(
        transactionId: transactionId,
        chatRoomId: chatRoomId,
        status: status,
      );
}
