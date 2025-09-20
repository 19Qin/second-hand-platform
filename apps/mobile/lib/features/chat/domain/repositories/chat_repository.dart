import '../entities/chat_thread.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatThreadEntity>> getThreads({String? keyword});
  Future<List<ChatMessageEntity>> getMessages(String threadId);
  Future<ChatMessageEntity> sendMessage(String threadId, String text);
  Future<void> markThreadRead(String threadId);
}
