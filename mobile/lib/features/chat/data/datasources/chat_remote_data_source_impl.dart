import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_room_model.dart';
import 'chat_remote_data_source.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;

  ChatRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ChatListModel> getChatList({
    int page = 1,
    int size = 20,
  }) async {
    final data = await _apiClient.get(
      '/chats',
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    return ChatListModel.fromJson(data);
  }

  @override
  Future<MessageListModel> getChatMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    
    if (before != null) {
      queryParams['before'] = before.toIso8601String();
    }

    final data = await _apiClient.get(
      '/chats/$chatRoomId/messages',
      queryParameters: queryParams,
    );

    return MessageListModel.fromJson(data);
  }

  @override
  Future<SendMessageResponse> sendMessage({
    required String chatRoomId,
    required SendMessageRequest request,
  }) async {
    final data = await _apiClient.post(
      '/chats/$chatRoomId/messages',
      body: request.toJson(),
    );

    return SendMessageResponse.fromJson(data);
  }

  @override
  Future<void> markAsRead({
    required String chatRoomId,
    String? lastReadMessageId,
  }) async {
    final request = MarkAsReadRequest(lastReadMessageId: lastReadMessageId);
    
    await _apiClient.post(
      '/chats/$chatRoomId/read',
      body: request.toJson(),
    );
  }

  @override
  Future<CreateChatRoomResponse> createChatRoom({
    required String sellerId,
  }) async {
    final data = await _apiClient.post(
      '/chats/rooms?sellerId=$sellerId',
    );

    return CreateChatRoomResponse.fromJson(data);
  }

  @override
  Future<CreateChatRoomResponse> startProductDiscussion({
    required String productId,
    String? initialMessage,
  }) async {
    final queryParams = <String, String>{
      'productId': productId,
    };
    
    if (initialMessage != null) {
      queryParams['message'] = initialMessage;
    }

    final data = await _apiClient.post(
      '/chats/product-discussion',
      queryParameters: queryParams,
    );

    return CreateChatRoomResponse.fromJson(data);
  }

  @override
  Future<void> recallMessage({
    required String messageId,
  }) async {
    await _apiClient.post(
      '/chats/messages/$messageId/recall',
    );
  }

  @override
  Future<MessageListModel> searchMessages({
    required String chatRoomId,
    required String keyword,
    int page = 1,
    int size = 20,
  }) async {
    final data = await _apiClient.get(
      '/chats/$chatRoomId/search',
      queryParameters: {
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    return MessageListModel.fromJson(data);
  }

  @override
  Future<MessageListModel> getImageMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
  }) async {
    final data = await _apiClient.get(
      '/chats/$chatRoomId/images',
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    return MessageListModel.fromJson(data);
  }

  @override
  Future<void> toggleChatRoomPin({
    required String chatRoomId,
  }) async {
    await _apiClient.post(
      '/chats/$chatRoomId/pin',
    );
  }

  @override
  Future<void> toggleChatRoomMute({
    required String chatRoomId,
  }) async {
    await _apiClient.post(
      '/chats/$chatRoomId/mute',
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final data = await _apiClient.get('/chats/unread-count');
    return data['unreadCount'] ?? 0;
  }

  @override
  Future<bool> getChatRoomOnlineStatus({
    required String chatRoomId,
  }) async {
    final data = await _apiClient.get('/chats/$chatRoomId/online-status');
    return data['isOnline'] ?? false;
  }

  @override
  Future<String> exportChatHistory({
    required String chatRoomId,
  }) async {
    final data = await _apiClient.get('/chats/$chatRoomId/export');
    return data['downloadUrl'] ?? '';
  }

  @override
  Future<Map<String, dynamic>> uploadChatFile({
    required String filePath,
    required String type,
  }) async {
    if (kIsWeb) {
      // Web环境下的处理
      throw Exception('Web环境下暂不支持文件上传，请在移动设备上使用');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiClient.baseUrl}/chats/upload'),
      );

      // 添加认证头
      final headers = await _apiClient.getHeaders();
      request.headers.addAll(headers);

      // 添加文件
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
      request.fields['type'] = type;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('上传失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('上传聊天文件失败: $e');
    }
  }
}