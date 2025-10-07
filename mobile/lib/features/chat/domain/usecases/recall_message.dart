import '../repositories/chat_repository.dart';

class RecallMessage {
  final ChatRepository _repository;

  RecallMessage(this._repository);

  Future<void> call(String messageId) async {
    return await _repository.recallMessage(messageId: messageId);
  }
}
