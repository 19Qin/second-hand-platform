import '../repositories/chat_repository.dart';

class CreateChatRoom {
  final ChatRepository _repository;

  CreateChatRoom(this._repository);

  Future<Map<String, dynamic>> call({
    required String sellerId,
  }) async {
    return await _repository.createChatRoom(
      sellerId: sellerId,
    );
  }
}


