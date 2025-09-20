import '../../domain/entities/chat_thread.dart';

class ChatThreadModel {
  final String id;
  final String peerName;
  final String? peerAvatarUrl;
  final String lastMessagePreview;
  final DateTime lastTime;
  final int unreadCount;
  final bool isOnline;

  const ChatThreadModel({
    required this.id,
    required this.peerName,
    this.peerAvatarUrl,
    required this.lastMessagePreview,
    required this.lastTime,
    required this.unreadCount,
    required this.isOnline,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id'] as String,
      peerName: json['peerName'] as String,
      peerAvatarUrl: json['peerAvatarUrl'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      lastTime: DateTime.parse(json['lastTime'] as String),
      unreadCount: (json['unreadCount'] ?? 0) as int,
      isOnline: (json['isOnline'] ?? false) as bool,
    );
  }

  ChatThreadEntity toEntity() => ChatThreadEntity(
        id: id,
        peerName: peerName,
        peerAvatarUrl: peerAvatarUrl,
        lastMessagePreview: lastMessagePreview,
        lastTime: lastTime,
        unreadCount: unreadCount,
        isOnline: isOnline,
      );
}
