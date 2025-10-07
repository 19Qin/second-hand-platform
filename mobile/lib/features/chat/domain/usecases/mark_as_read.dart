import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class MarkAsRead {
  final ChatRepository _repository;

  MarkAsRead(this._repository);

  Future<void> call(String chatRoomId) async {
    await _repository.markAsRead(chatRoomId: chatRoomId);
  }
}
