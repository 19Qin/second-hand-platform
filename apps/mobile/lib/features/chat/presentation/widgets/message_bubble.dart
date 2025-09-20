import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageEntity msg;
  const MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final align = msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isMine ? cs.primary : cs.surfaceContainerHigh;
    final textColor = msg.isMine ? Colors.white : cs.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(msg.text, style: TextStyle(color: textColor)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _formatHm(msg.sentAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }

  String _formatHm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
