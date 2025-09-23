import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetMessages {
  final ChatRepository repo;
  GetMessages(this.repo);

  Future<List<ChatMessageEntity>> call(String threadId) {
    return repo.getMessages(threadId);
  }
}
