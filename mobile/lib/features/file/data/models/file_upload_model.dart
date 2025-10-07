import '../../domain/entities/file_upload_entity.dart';

class FileUploadResponseModel {
  final String url;
  final String? thumbnailUrl;
  final String fileName;
  final int size;
  final int? width;
  final int? height;
  final String uploadTime;

  FileUploadResponseModel({
    required this.url,
    this.thumbnailUrl,
    required this.fileName,
    required this.size,
    this.width,
    this.height,
    required this.uploadTime,
  });

  factory FileUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return FileUploadResponseModel(
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['filename'] as String,
      size: json['size'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
      uploadTime: json['uploadTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'filename': fileName,
        'size': size,
        'width': width,
        'height': height,
        'uploadTime': uploadTime,
      };

  FileUploadEntity toEntity() => FileUploadEntity(
        fileId: fileName, // 使用fileName作为fileId
        originalName: fileName, // 使用fileName作为originalName
        fileName: fileName,
        url: url,
        thumbnailUrl: thumbnailUrl,
        fileSize: size,
        mimeType: 'image/jpeg', // 默认MIME类型
        width: width,
        height: height,
        uploadTime: DateTime.parse(uploadTime),
      );
}
