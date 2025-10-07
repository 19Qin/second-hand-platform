import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class GetChatList {
  final ChatRepository _repository;

  GetChatList(this._repository);

  Future<ChatListEntity> call({
    int page = 1,
    int size = 20,
  }) async {
    return await _repository.getChatList(
      page: page,
      size: size,
    );
  }
}


