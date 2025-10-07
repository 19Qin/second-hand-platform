import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/chat_room.dart';

class ChatWebSocketService {
  WebSocket? _socket;
  String? _currentChatRoomId;
  final StreamController<MessageEntity> _messageController = StreamController<MessageEntity>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageEntity> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  /// 连接到WebSocket服务器
  Future<void> connect(String baseUrl, String accessToken) async {
    try {
      final uri = Uri.parse('$baseUrl/ws/chat?token=$accessToken');
      _socket = await WebSocket.connect(uri.toString());
      
      _socket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _connectionController.add('connected');
    } catch (e) {
      _connectionController.add('error');
      throw Exception('WebSocket连接失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _currentChatRoomId = null;
    _connectionController.add('disconnected');
  }

  /// 加入聊天室
  void joinChatRoom(String chatRoomId) {
    if (!isConnected) {
      throw Exception('WebSocket未连接');
    }

    _currentChatRoomId = chatRoomId;
    _sendMessage({
      'type': 'join_room',
      'chatRoomId': chatRoomId,
    });
  }

  /// 离开聊天室
  void leaveChatRoom() {
    if (_currentChatRoomId != null) {
      _sendMessage({
        'type': 'leave_room',
        'chatRoomId': _currentChatRoomId,
      });
      _currentChatRoomId = null;
    }
  }

  /// 发送消息
  void sendMessage({
    required String chatRoomId,
    required String type,
    required String content,
    String? thumbnail,
    int? width,
    int? height,
    int? duration,
    int? fileSize,
    String? transactionId,
    String? productId,
  }) {
    if (!isConnected) {
      throw Exception('WebSocket未连接');
    }

    _sendMessage({
      'type': 'send_message',
      'chatRoomId': chatRoomId,
      'message': {
        'type': type,
        'content': content,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (duration != null) 'duration': duration,
        if (fileSize != null) 'fileSize': fileSize,
        if (transactionId != null) 'transactionId': transactionId,
        if (productId != null) 'productId': productId,
      },
    });
  }

  /// 发送输入状态
  void sendTypingStatus(String chatRoomId, bool isTyping) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'typing',
      'chatRoomId': chatRoomId,
      'isTyping': isTyping,
    });
  }

  /// 标记消息已读
  void markAsRead(String chatRoomId, String? lastReadMessageId) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'mark_read',
      'chatRoomId': chatRoomId,
      if (lastReadMessageId != null) 'lastReadMessageId': lastReadMessageId,
    });
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic data) {
    try {
      final message = json.decode(data);
      final messageType = message['type'] as String?;

      switch (messageType) {
        case 'new_message':
          _handleNewMessage(message);
          break;
        case 'typing':
          _handleTypingStatus(message);
          break;
        case 'user_online':
          _handleUserOnline(message);
          break;
        case 'user_offline':
          _handleUserOffline(message);
          break;
        case 'message_delivered':
          _handleMessageDelivered(message);
          break;
        case 'message_read':
          _handleMessageRead(message);
          break;
        default:
          print('未知消息类型: $messageType');
      }
    } catch (e) {
      print('处理WebSocket消息失败: $e');
    }
  }

  /// 处理新消息
  void _handleNewMessage(Map<String, dynamic> message) {
    final messageData = message['message'] as Map<String, dynamic>?;
    if (messageData == null) return;

    final messageEntity = MessageEntity(
      id: messageData['id']?.toString() ?? '',
      senderId: messageData['senderId']?.toString() ?? '',
      senderName: messageData['senderName']?.toString() ?? '',
      type: messageData['type']?.toString() ?? 'TEXT',
      content: messageData['content']?.toString() ?? '',
      thumbnail: messageData['thumbnail']?.toString(),
      imageSize: messageData['imageSize'] != null 
          ? ImageSizeEntity(
              width: messageData['imageSize']['width'] ?? 0,
              height: messageData['imageSize']['height'] ?? 0,
            )
          : null,
      duration: messageData['duration'],
      waveform: messageData['waveform']?.toString(),
      sentAt: DateTime.parse(messageData['sentAt']),
      isFromMe: messageData['isFromMe'] ?? false,
      status: messageData['status']?.toString() ?? 'SENT',
      transactionId: messageData['transactionId']?.toString(),
      productId: messageData['productId']?.toString(),
      systemData: messageData['systemData'] != null 
          ? SystemDataEntity(
              transactionCode: messageData['systemData']['transactionCode']?.toString(),
              meetingTime: messageData['systemData']['meetingTime'] != null 
                  ? DateTime.parse(messageData['systemData']['meetingTime'])
                  : null,
              location: messageData['systemData']['location']?.toString(),
            )
          : null,
    );

    _messageController.add(messageEntity);
  }

  /// 处理输入状态
  void _handleTypingStatus(Map<String, dynamic> message) {
    _typingController.add({
      'chatRoomId': message['chatRoomId'],
      'userId': message['userId'],
      'isTyping': message['isTyping'],
    });
  }

  /// 处理用户上线
  void _handleUserOnline(Map<String, dynamic> message) {
    // 可以在这里处理用户上线逻辑
    print('用户上线: ${message['userId']}');
  }

  /// 处理用户下线
  void _handleUserOffline(Map<String, dynamic> message) {
    // 可以在这里处理用户下线逻辑
    print('用户下线: ${message['userId']}');
  }

  /// 处理消息送达
  void _handleMessageDelivered(Map<String, dynamic> message) {
    // 可以在这里处理消息送达逻辑
    print('消息送达: ${message['messageId']}');
  }

  /// 处理消息已读
  void _handleMessageRead(Map<String, dynamic> message) {
    // 可以在这里处理消息已读逻辑
    print('消息已读: ${message['messageId']}');
  }

  /// 处理错误
  void _handleError(error) {
    print('WebSocket错误: $error');
    _connectionController.add('error');
  }

  /// 处理断开连接
  void _handleDisconnect() {
    print('WebSocket断开连接');
    _connectionController.add('disconnected');
  }

  /// 发送消息到服务器
  void _sendMessage(Map<String, dynamic> message) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(json.encode(message));
    }
  }

  /// 释放资源
  void dispose() {
    _socket?.close();
    _messageController.close();
    _connectionController.close();
    _typingController.close();
  }
}


