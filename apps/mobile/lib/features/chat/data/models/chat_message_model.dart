import '../../domain/entities/chat_message.dart';

class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final ChatMessageStatus status;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.status,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    ChatMessageStatus parseStatus(String? s) {
      switch (s) {
        case 'sent':
          return ChatMessageStatus.sent;
        case 'delivered':
          return ChatMessageStatus.delivered;
        case 'read':
          return ChatMessageStatus.read;
        case 'failed':
          return ChatMessageStatus.failed;
        default:
          return ChatMessageStatus.sending;
      }
    }

    return ChatMessageModel(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isMine: (json['isMine'] ?? false) as bool,
      status: parseStatus(json['status'] as String?),
    );
  }

  ChatMessageEntity toEntity() => ChatMessageEntity(
        id: id,
        threadId: threadId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isMine: isMine,
        status: status,
      );
}
