import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository _repository;

  SendMessage(this._repository);

  Future<Map<String, dynamic>> call({
    required String chatRoomId,
    required String type,
    required String content,
    String? thumbnail,
    int? width,
    int? height,
    int? duration,
    int? fileSize,
  }) async {
    return await _repository.sendMessage(
      chatRoomId: chatRoomId,
      type: type,
      content: content,
      thumbnail: thumbnail,
      width: width,
      height: height,
      duration: duration,
      fileSize: fileSize,
    );
  }
}


