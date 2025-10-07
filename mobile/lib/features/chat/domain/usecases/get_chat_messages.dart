import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class GetChatMessages {
  final ChatRepository _repository;

  GetChatMessages(this._repository);

  Future<MessageListEntity> call({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  }) async {
    return await _repository.getChatMessages(
      chatRoomId: chatRoomId,
      page: page,
      size: size,
      before: before,
    );
  }
}


