import 'dart:async';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/upload_chat_file.dart';
import 'chat_websocket_service.dart';

class ChatService {
  final ChatRepository _repository;
  final ChatWebSocketService _websocketService;
  
  ChatService(this._repository, this._websocketService);

  /// 初始化聊天服务
  Future<void> initialize(String baseUrl, String accessToken) async {
    await _websocketService.connect(baseUrl, accessToken);
  }

  /// 加入聊天室
  void joinChatRoom(String chatRoomId) {
    _websocketService.joinChatRoom(chatRoomId);
  }

  /// 离开聊天室
  void leaveChatRoom() {
    _websocketService.leaveChatRoom();
  }

  /// 获取聊天列表
  Future<ChatListEntity> getChatList({
    int page = 1,
    int size = 20,
  }) async {
    return await _repository.getChatList(
      page: page,
      size: size,
    );
  }

  /// 获取聊天记录
  Future<MessageListEntity> getChatMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  }) async {
    return await _repository.getChatMessages(
      chatRoomId: chatRoomId,
      page: page,
      size: size,
      before: before,
    );
  }

  /// 发送文本消息
  Future<Map<String, dynamic>> sendTextMessage({
    required String chatRoomId,
    required String content,
  }) async {
    // 通过WebSocket发送实时消息
    _websocketService.sendMessage(
      chatRoomId: chatRoomId,
      type: 'TEXT',
      content: content,
    );

    // 同时通过API发送以确保消息持久化
    return await _repository.sendMessage(
      chatRoomId: chatRoomId,
      type: 'TEXT',
      content: content,
    );
  }

  /// 发送图片消息
  Future<Map<String, dynamic>> sendImageMessage({
    required String chatRoomId,
    required String content,
    required String thumbnail,
    required int width,
    required int height,
    int? fileSize,
  }) async {
    // 通过WebSocket发送实时消息
    _websocketService.sendMessage(
      chatRoomId: chatRoomId,
      type: 'IMAGE',
      content: content,
      thumbnail: thumbnail,
      width: width,
      height: height,
      fileSize: fileSize,
    );

    // 同时通过API发送以确保消息持久化
    return await _repository.sendMessage(
      chatRoomId: chatRoomId,
      type: 'IMAGE',
      content: content,
      thumbnail: thumbnail,
      width: width,
      height: height,
      fileSize: fileSize,
    );
  }

  /// 发送语音消息
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String chatRoomId,
    required String content,
    required int duration,
    int? fileSize,
  }) async {
    // 通过WebSocket发送实时消息
    _websocketService.sendMessage(
      chatRoomId: chatRoomId,
      type: 'VOICE',
      content: content,
      duration: duration,
      fileSize: fileSize,
    );

    // 同时通过API发送以确保消息持久化
    return await _repository.sendMessage(
      chatRoomId: chatRoomId,
      type: 'VOICE',
      content: content,
      duration: duration,
      fileSize: fileSize,
    );
  }

  /// 标记消息已读
  Future<void> markAsRead({
    required String chatRoomId,
    String? lastReadMessageId,
  }) async {
    // 通过WebSocket发送实时状态
    _websocketService.markAsRead(chatRoomId, lastReadMessageId);

    // 同时通过API更新状态
    await _repository.markAsRead(
      chatRoomId: chatRoomId,
      lastReadMessageId: lastReadMessageId,
    );
  }

  /// 发送输入状态
  void sendTypingStatus(String chatRoomId, bool isTyping) {
    _websocketService.sendTypingStatus(chatRoomId, isTyping);
  }

  /// 创建聊天室
  Future<Map<String, dynamic>> createChatRoom({
    required String sellerId,
  }) async {
    return await _repository.createChatRoom(sellerId: sellerId);
  }

  /// 开始商品讨论
  Future<Map<String, dynamic>> startProductDiscussion({
    required String productId,
    String? initialMessage,
  }) async {
    return await _repository.startProductDiscussion(
      productId: productId,
      initialMessage: initialMessage,
    );
  }

  /// 上传聊天文件
  Future<UploadChatFileResponse> uploadChatFile({
    required String filePath,
    required String type,
  }) async {
    return await _repository.uploadChatFile(
      filePath: filePath,
      type: type,
    );
  }

  /// 获取实时消息流
  Stream<MessageEntity> get messageStream => _websocketService.messageStream;

  /// 获取连接状态流
  Stream<String> get connectionStream => _websocketService.connectionStream;

  /// 获取输入状态流
  Stream<Map<String, dynamic>> get typingStream => _websocketService.typingStream;

  /// 检查连接状态
  bool get isConnected => _websocketService.isConnected;

  /// 断开连接
  Future<void> disconnect() async {
    await _websocketService.disconnect();
  }

  /// 释放资源
  void dispose() {
    _websocketService.dispose();
  }
}
