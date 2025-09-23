import '../models/chat_thread_model.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatThreadModel>> fetchThreads({String? keyword});
  Future<List<ChatMessageModel>> fetchMessages(String threadId);
  Future<ChatMessageModel> sendMessage(String threadId, String text);
  Future<void> markThreadRead(String threadId);
}
