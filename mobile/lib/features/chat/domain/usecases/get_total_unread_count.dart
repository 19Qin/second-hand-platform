import '../repositories/chat_repository.dart';

class GetTotalUnreadCount {
  final ChatRepository _repository;

  GetTotalUnreadCount(this._repository);

  Future<int> call() async {
    return await _repository.getTotalUnreadCount();
  }
}


