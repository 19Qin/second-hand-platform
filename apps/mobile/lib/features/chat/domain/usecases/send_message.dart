import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repo;
  SendMessage(this.repo);

  Future<ChatMessageEntity> call(String threadId, String text) {
    return repo.sendMessage(threadId, text);
  }
}
