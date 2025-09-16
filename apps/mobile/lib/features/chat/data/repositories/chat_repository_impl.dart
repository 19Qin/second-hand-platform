import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl(this.remote);

  @override
  Future<List<ChatThreadEntity>> getThreads({String? keyword}) async {
    final models = await remote.fetchThreads(keyword: keyword);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String threadId) async {
    final models = await remote.fetchMessages(threadId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ChatMessageEntity> sendMessage(String threadId, String text) async {
    final model = await remote.sendMessage(threadId, text);
    return model.toEntity();
  }

  @override
  Future<void> markThreadRead(String threadId) => remote.markThreadRead(threadId);
}
