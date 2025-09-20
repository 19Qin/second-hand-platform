// lib/features/chat/presentation/mock/chat_mock.dart
import 'dart:async';

// Data-layer interfaces & models (IMPORTANT: use these exact imports)
import 'package:mobile/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:mobile/features/chat/data/models/chat_thread_model.dart';
import 'package:mobile/features/chat/data/models/chat_message_model.dart';

// Domain enum for status (if it lives with the entity, re-export in your model or just duplicate the enum here)
import 'package:mobile/features/chat/domain/entities/chat_message.dart' show ChatMessageStatus;

/// Fake remote source that the repository can consume
class ChatFakeDataSource implements ChatRemoteDataSource {
  final String myId = 'me';

  // ---- In-memory threads ----
  final List<ChatThreadModel> _threads = [
    ChatThreadModel(
      id: 't1',
      peerName: 'Alice',
      peerAvatarUrl: '',
      lastMessagePreview: 'See you at 6!',
      lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isOnline: true,
    ),
    ChatThreadModel(
      id: 't2',
      peerName: 'Bob',
      peerAvatarUrl: '',
      lastMessagePreview: 'Thanks!',
      lastTime: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    ChatThreadModel(
      id: 't3',
      peerName: 'Cathy',
      peerAvatarUrl: '',
      lastMessagePreview: 'Are you available tomorrow?',
      lastTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: true,
    ),
  ];

  // ---- In-memory messages per thread ----
  final Map<String, List<ChatMessageModel>> _messages = {
    't1': [
      ChatMessageModel(
        id: 'm1',
        threadId: 't1',
        senderId: 'alice',
        text: 'Hi!',
        sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isMine: false,
        status: ChatMessageStatus.read,
      ),
      ChatMessageModel(
        id: 'm2',
        threadId: 't1',
        senderId: 'me',
        text: 'Hello Alice, see you at 6!',
        sentAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isMine: true,
        status: ChatMessageStatus.read,
      ),
    ],
    't2': [
      ChatMessageModel(
        id: 'm3',
        threadId: 't2',
        senderId: 'bob',
        text: 'Thanks!',
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
        isMine: false,
        status: ChatMessageStatus.delivered,
      ),
    ],
    't3': [
      ChatMessageModel(
        id: 'm4',
        threadId: 't3',
        senderId: 'cathy',
        text: 'Are you available tomorrow?',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
        isMine: false,
        status: ChatMessageStatus.sent,
      ),
    ],
  };

  // ---------------- ChatRemoteDataSource implementation ----------------

  @override
  Future<List<ChatThreadModel>> fetchThreads({String? keyword}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final k = keyword?.toLowerCase().trim();
    final list = (k == null || k.isEmpty)
        ? List<ChatThreadModel>.from(_threads)
        : _threads
            .where((t) =>
                t.peerName.toLowerCase().contains(k) ||
                t.lastMessagePreview.toLowerCase().contains(k))
            .toList();
    list.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return list;
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List<ChatMessageModel>.from(_messages[threadId] ?? const <ChatMessageModel>[]);
    // Return a *copy* so callers can sort/map without mutating our store.
  }

  @override
  Future<ChatMessageModel> sendMessage(String threadId, String text) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final msg = ChatMessageModel(
      id: 'm${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      senderId: myId,
      text: text,
      sentAt: DateTime.now(),
      isMine: true,
      status: ChatMessageStatus.sent,
    );
    _messages.putIfAbsent(threadId, () => []).add(msg);

    // Update thread preview
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      final t = _threads[idx];
      _threads[idx] = ChatThreadModel(
        id: t.id,
        peerName: t.peerName,
        peerAvatarUrl: t.peerAvatarUrl,
        lastMessagePreview: text,
        lastTime: msg.sentAt,
        unreadCount: t.unreadCount,
        isOnline: t.isOnline,
      );
    }
    return msg;
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      final t = _threads[idx];
      _threads[idx] = ChatThreadModel(
        id: t.id,
        peerName: t.peerName,
        peerAvatarUrl: t.peerAvatarUrl,
        lastMessagePreview: t.lastMessagePreview,
        lastTime: t.lastTime,
        unreadCount: 0,
        isOnline: t.isOnline,
      );
    }
  }
}
