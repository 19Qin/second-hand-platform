import '../repositories/chat_repository.dart';

class UploadChatFile {
  final ChatRepository _repository;

  UploadChatFile(this._repository);

  Future<UploadChatFileResponse> call({
    required String filePath,
    required String type, // image or voice
  }) async {
    return await _repository.uploadChatFile(
      filePath: filePath,
      type: type,
    );
  }
}

class UploadChatFileResponse {
  final String url;
  final String? thumbnail; // 图片才有
  final String filename;
  final int size;
  final int? duration; // 语音才有

  UploadChatFileResponse({
    required this.url,
    this.thumbnail,
    required this.filename,
    required this.size,
    this.duration,
  });
}


