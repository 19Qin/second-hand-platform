class ChatThreadEntity {
  final String id;
  final String peerName;
  final String? peerAvatarUrl;
  final String lastMessagePreview;
  final DateTime lastTime;
  final int unreadCount;
  final bool isOnline;

  const ChatThreadEntity({
    required this.id,
    required this.peerName,
    this.peerAvatarUrl,
    required this.lastMessagePreview,
    required this.lastTime,
    required this.unreadCount,
    required this.isOnline,
  });
}
