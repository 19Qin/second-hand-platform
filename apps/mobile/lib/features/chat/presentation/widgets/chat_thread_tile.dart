import 'package:flutter/material.dart';
import '../../domain/entities/chat_thread.dart';

class ChatThreadTile extends StatelessWidget {
  final ChatThreadEntity thread;
  final VoidCallback? onTap;

  const ChatThreadTile({super.key, required this.thread, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget avatar = CircleAvatar(
      radius: 24,
      backgroundColor: cs.primary.withOpacity(0.15),
      backgroundImage:
          (thread.peerAvatarUrl != null && thread.peerAvatarUrl!.isNotEmpty)
              ? NetworkImage(thread.peerAvatarUrl!)
              : null,
      child: (thread.peerAvatarUrl == null || thread.peerAvatarUrl!.isEmpty)
          ? Text(thread.peerName.isNotEmpty ? thread.peerName[0].toUpperCase() : '?')
          : null,
    );

    return ListTile(
      leading: Stack(
        children: [
          avatar,
          if (thread.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(thread.peerName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(thread.lastMessagePreview, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatHm(thread.lastTime), style: Theme.of(context).textTheme.labelSmall),
          if (thread.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread.unreadCount > 99 ? '99+' : '${thread.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatHm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
