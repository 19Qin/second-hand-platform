import '../repositories/chat_repository.dart';

class MarkRead {
  final ChatRepository repo;
  MarkRead(this.repo);

  Future<void> call(String threadId) => repo.markThreadRead(threadId);
}
