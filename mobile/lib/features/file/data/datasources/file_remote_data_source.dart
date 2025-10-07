import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/file_upload_model.dart';

abstract class FileRemoteDataSource {
  Future<FileUploadResponseModel> uploadFile({
    required XFile file,
    required String type,
    bool compress = true,
    String? token,
  });
  
  // 商品图片上传专用接口
  Future<FileUploadResponseModel> uploadProductImage({
    required XFile file,
    String? token,
  });
}

class FileRemoteDataSourceImpl implements FileRemoteDataSource {
  final http.Client _client;

  FileRemoteDataSourceImpl(this._client);

  @override
  Future<FileUploadResponseModel> uploadFile({
    required XFile file,
    required String type,
    bool compress = true,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/file/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // 读取文件字节数据
      final bytes = await file.readAsBytes();
      
      // 添加文件 - 使用MultipartFile.fromBytes支持Web
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );
      
      // 添加其他参数
      request.fields['type'] = type;
      request.fields['compress'] = compress.toString();
      
      // 添加认证头
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        // 检查响应格式
        if (jsonData['code'] == 200) {
          return FileUploadResponseModel.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            code: jsonData['code'] as int,
            message: jsonData['message'] as String,
          );
        }
      } else {
        throw ServerException(
          code: response.statusCode,
          message: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'File upload failed',
        details: e.toString(),
      );
    }
  }
  
  @override
  Future<FileUploadResponseModel> uploadProductImage({
    required XFile file,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/products/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // 读取文件字节数据
      final bytes = await file.readAsBytes();
      
      // 获取文件扩展名并确保格式正确
      String fileName = file.name;
      String extension = fileName.toLowerCase().split('.').last;
      
      // 处理jpg/jpeg扩展名
      if (extension == 'jpeg') {
        extension = 'jpg';
        fileName = fileName.replaceAll(RegExp(r'\.jpeg$', caseSensitive: false), '.jpg');
      }
      
      // 验证文件格式
      if (!['jpg', 'png', 'webp'].contains(extension)) {
        throw Exception('Unsupported file format: $extension. Only JPG, PNG, WebP are supported.');
      }
      
      // 确定MIME类型
      String mimeType;
      switch (extension) {
        case 'jpg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }
      
      print('📤 Uploading file: $fileName, extension: $extension, mimeType: $mimeType, size: ${bytes.length} bytes');
      
      // 添加文件 - 使用MultipartFile.fromBytes支持Web
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      // 添加认证头
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      print('📤 Sending request to: ${uri.toString()}');
      print('📤 Request headers: ${request.headers}');
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        // 检查响应格式
        if (jsonData['code'] == 200) {
          print('✅ Upload successful: ${jsonData['data']}');
          return FileUploadResponseModel.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          print('❌ Server error: ${jsonData['message']}');
          throw ServerException(
            code: jsonData['code'] as int,
            message: jsonData['message'] as String,
          );
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
        throw ServerException(
          code: response.statusCode,
          message: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Product image upload failed',
        details: e.toString(),
      );
    }
  }
}
