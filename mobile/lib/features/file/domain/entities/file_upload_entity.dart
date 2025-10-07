class FileUploadEntity {
  final String fileId;
  final String originalName;
  final String fileName;
  final String url;
  final String? thumbnailUrl;
  final int fileSize;
  final String mimeType;
  final int? width;
  final int? height;
  final DateTime uploadTime;

  const FileUploadEntity({
    required this.fileId,
    required this.originalName,
    required this.fileName,
    required this.url,
    this.thumbnailUrl,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    required this.uploadTime,
  });

  /// 获取文件大小的友好显示格式
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 是否为图片文件
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  /// 获取文件扩展名
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}
