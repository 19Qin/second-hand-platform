import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../auth/token_manager.dart';
import 'api_response.dart';
import 'api_exception.dart';

/// Unified API Client
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  /// GET Request
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _buildHeaders();
      
      // 调试日志
      print('🔍 GET Request Debug:');
      print('URL: $uri');
      print('Headers: $headers');
      
      final response = await _client
          .get(uri, headers: headers)
          .timeout(AppConfig.receiveTimeout);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network connection failed',
        details: e.message,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        message: 'HTTP request failed',
        details: e.message,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Request failed',
        details: e.toString(),
      );
    }
  }

  /// POST Request
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final requestHeaders = headers ?? await _buildHeaders(contentType: 'application/json');
      final requestBody = body != null ? json.encode(body) : null;
      
      // 调试日志
      print('🔍 POST Request Debug:');
      print('URL: $uri');
      print('Headers: $requestHeaders');
      print('Body: $requestBody');
      
      final response = await _client
          .post(
            uri,
            headers: requestHeaders,
            body: requestBody,
          )
          .timeout(AppConfig.receiveTimeout);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network connection failed',
        details: e.message,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        message: 'HTTP request failed',
        details: e.message,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Request failed',
        details: e.toString(),
      );
    }
  }

  /// PUT Request
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _buildHeaders(contentType: 'application/json');
      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network connection failed',
        details: e.message,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        message: 'HTTP request failed',
        details: e.message,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Request failed',
        details: e.toString(),
      );
    }
  }

  /// DELETE Request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final headers = await _buildHeaders();
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network connection failed',
        details: e.message,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        message: 'HTTP request failed',
        details: e.message,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(
        message: 'Request failed',
        details: e.toString(),
      );
    }
  }

  /// Build URI
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final baseUri = Uri.parse(AppConfig.baseUrl);
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return baseUri.replace(
      path: '${baseUri.path}/$path'.replaceAll('//', '/'),
      queryParameters: queryParameters,
    );
  }

  /// Get base URL
  String get baseUrl => AppConfig.baseUrl;

  /// Get headers for external use
  Future<Map<String, String>> getHeaders() async {
    return await _buildHeaders();
  }

  /// Build Request Headers
  Future<Map<String, String>> _buildHeaders({String? contentType}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    // 添加认证Token
    final token = await TokenManager.instance.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('🔍 添加认证Token: Bearer ${token.substring(0, 20)}...');
    } else {
      print('⚠️ 没有找到有效的认证Token');
    }

    return headers;
  }

  /// Handle Response
  T _handleResponse<T>(http.Response response, T Function(dynamic)? fromJson) {
    try {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return null as T;
        } else {
          throw ServerException(
            code: response.statusCode,
            message: 'HTTP ${response.statusCode}',
          );
        }
      }

      final Map<String, dynamic> jsonData;
      try {
        // 预处理响应体，将大数字ID转换为字符串
        String processedResponseBody = responseBody;
        
        // 使用正则表达式匹配并替换大数字ID
        final bigNumberPattern = RegExp(r'"(chatRoomId|transactionId|productId|userId|sellerId|buyerId|id)":(\d{16,})');
        processedResponseBody = processedResponseBody.replaceAllMapped(
          bigNumberPattern,
          (match) {
            final fieldName = match.group(1)!;
            final numberValue = match.group(2)!;
            print('🔍 预处理大数字ID: $fieldName = $numberValue');
            return '"$fieldName":"$numberValue"';
          },
        );
        
        jsonData = json.decode(processedResponseBody) as Map<String, dynamic>;
      } catch (e) {
        throw ParseException(
          message: 'JSON parsing failed',
          details: e.toString(),
        );
      }

      final apiResponse = ApiResponse.fromJson(jsonData, fromJson);
      
      if (apiResponse.isSuccess) {
        return apiResponse.data as T;
      } else {
        throw ServerException(
          code: apiResponse.code,
          message: apiResponse.message,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ParseException(
        message: 'Response handling failed',
        details: e.toString(),
      );
    }
  }

  /// Upload File
  Future<Map<String, dynamic>> uploadFile(
    File file,
    String type, {
    bool compress = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/file/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // 读取文件字节数据
      final bytes = await file.readAsBytes();
      
      // 添加文件
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.path.split('/').last,
        ),
      );
      
      // 添加其他参数
      request.fields['type'] = type;
      request.fields['compress'] = compress.toString();
      
      // 添加认证头
      final headers = await _buildHeaders();
      request.headers.addAll(headers);
      
      print('🔍 Upload Request Debug:');
      print('URL: $uri');
      print('Type: $type');
      print('File size: ${bytes.length} bytes');
      
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Upload Response Status: ${response.statusCode}');
      print('📥 Upload Response Body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        
        if (jsonData['code'] == 200) {
          return jsonData;
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

  /// Release Resources
  void dispose() {
    _client.close();
  }
}
