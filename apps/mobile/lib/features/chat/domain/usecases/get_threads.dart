import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class GetThreads {
  final ChatRepository repo;
  GetThreads(this.repo);

  Future<List<ChatThreadEntity>> call({String? keyword}) {
    return repo.getThreads(keyword: keyword);
  }
}
