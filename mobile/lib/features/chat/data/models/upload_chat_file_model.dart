import '../../domain/usecases/upload_chat_file.dart';

class UploadChatFileModel {
  final String url;
  final String? thumbnail;
  final String filename;
  final int size;
  final int? duration;

  UploadChatFileModel({
    required this.url,
    this.thumbnail,
    required this.filename,
    required this.size,
    this.duration,
  });

  factory UploadChatFileModel.fromJson(Map<String, dynamic> json) {
    return UploadChatFileModel(
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnail': thumbnail,
      'filename': filename,
      'size': size,
      'duration': duration,
    };
  }

  UploadChatFileResponse toEntity() => UploadChatFileResponse(
        url: url,
        thumbnail: thumbnail,
        filename: filename,
        size: size,
        duration: duration,
      );
}


