enum ChatMessageStatus { sending, sent, delivered, read, failed }

class ChatMessageEntity {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final ChatMessageStatus status;

  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.status,
  });
}
