import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class SearchThreads {
  final ChatRepository repo;
  SearchThreads(this.repo);

  Future<List<ChatThreadEntity>> call(String keyword) {
    return repo.getThreads(keyword: keyword);
  }
}
