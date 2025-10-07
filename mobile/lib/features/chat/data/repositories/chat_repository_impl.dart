import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/upload_chat_file.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_room_model.dart';
import '../models/upload_chat_file_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<ChatListEntity> getChatList({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final model = await _remoteDataSource.getChatList(
        page: page,
        size: size,
      );
      return model.toEntity();
    } catch (e) {
      throw Exception('获取聊天列表失败: $e');
    }
  }

  @override
  Future<MessageListEntity> getChatMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  }) async {
    try {
      final model = await _remoteDataSource.getChatMessages(
        chatRoomId: chatRoomId,
        page: page,
        size: size,
        before: before,
      );
      return model.toEntity();
    } catch (e) {
      throw Exception('获取聊天记录失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String chatRoomId,
    required String type,
    required String content,
    String? thumbnail,
    int? width,
    int? height,
    int? duration,
    int? fileSize,
  }) async {
    try {
      final request = SendMessageRequest(
        type: type,
        content: content,
        thumbnail: thumbnail,
        width: width,
        height: height,
        duration: duration,
        fileSize: fileSize,
      );

      final response = await _remoteDataSource.sendMessage(
        chatRoomId: chatRoomId,
        request: request,
      );

      return {
        'messageId': response.messageId,
        'sentAt': response.sentAt,
        'status': response.status,
      };
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
  }

  @override
  Future<void> markAsRead({
    required String chatRoomId,
    String? lastReadMessageId,
  }) async {
    try {
      await _remoteDataSource.markAsRead(
        chatRoomId: chatRoomId,
        lastReadMessageId: lastReadMessageId,
      );
    } catch (e) {
      throw Exception('标记已读失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createChatRoom({
    required String sellerId,
  }) async {
    try {
      final response = await _remoteDataSource.createChatRoom(
        sellerId: sellerId,
      );

      return {
        'chatRoomId': response.chatRoomId,
        'participant': response.participant.toEntity(),
        'unreadCount': response.unreadCount,
        'totalMessages': response.totalMessages,
      };
    } catch (e) {
      throw Exception('创建聊天室失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> startProductDiscussion({
    required String productId,
    String? initialMessage,
  }) async {
    try {
      final response = await _remoteDataSource.startProductDiscussion(
        productId: productId,
        initialMessage: initialMessage,
      );

      return {
        'chatRoomId': response.chatRoomId,
        'participant': response.participant.toEntity(),
        'unreadCount': response.unreadCount,
        'totalMessages': response.totalMessages,
      };
    } catch (e) {
      throw Exception('开始商品讨论失败: $e');
    }
  }

  @override
  Future<void> recallMessage({
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.recallMessage(messageId: messageId);
    } catch (e) {
      throw Exception('撤回消息失败: $e');
    }
  }

  @override
  Future<MessageListEntity> searchMessages({
    required String chatRoomId,
    required String keyword,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final model = await _remoteDataSource.searchMessages(
        chatRoomId: chatRoomId,
        keyword: keyword,
        page: page,
        size: size,
      );
      return model.toEntity();
    } catch (e) {
      throw Exception('搜索聊天记录失败: $e');
    }
  }

  @override
  Future<MessageListEntity> getImageMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final model = await _remoteDataSource.getImageMessages(
        chatRoomId: chatRoomId,
        page: page,
        size: size,
      );
      return model.toEntity();
    } catch (e) {
      throw Exception('获取图片消息失败: $e');
    }
  }

  @override
  Future<void> toggleChatRoomPin({
    required String chatRoomId,
  }) async {
    try {
      await _remoteDataSource.toggleChatRoomPin(chatRoomId: chatRoomId);
    } catch (e) {
      throw Exception('置顶聊天室失败: $e');
    }
  }

  @override
  Future<void> toggleChatRoomMute({
    required String chatRoomId,
  }) async {
    try {
      await _remoteDataSource.toggleChatRoomMute(chatRoomId: chatRoomId);
    } catch (e) {
      throw Exception('静音聊天室失败: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await _remoteDataSource.getUnreadCount();
    } catch (e) {
      throw Exception('获取未读消息数失败: $e');
    }
  }

  @override
  Future<int> getTotalUnreadCount() async {
    try {
      // 获取聊天列表并计算总未读消息数
      final chatList = await _remoteDataSource.getChatList(page: 1, size: 100);
      int totalUnread = 0;
      for (final chatRoom in chatList.content) {
        totalUnread += chatRoom.unreadCount;
      }
      return totalUnread;
    } catch (e) {
      throw Exception('获取总未读消息数失败: $e');
    }
  }

  @override
  Future<bool> getChatRoomOnlineStatus({
    required String chatRoomId,
  }) async {
    try {
      return await _remoteDataSource.getChatRoomOnlineStatus(
        chatRoomId: chatRoomId,
      );
    } catch (e) {
      throw Exception('获取在线状态失败: $e');
    }
  }

  @override
  Future<String> exportChatHistory({
    required String chatRoomId,
  }) async {
    try {
      return await _remoteDataSource.exportChatHistory(
        chatRoomId: chatRoomId,
      );
    } catch (e) {
      throw Exception('导出聊天记录失败: $e');
    }
  }

  @override
  Future<UploadChatFileResponse> uploadChatFile({
    required String filePath,
    required String type,
  }) async {
    try {
      final data = await _remoteDataSource.uploadChatFile(
        filePath: filePath,
        type: type,
      );
      final model = UploadChatFileModel.fromJson(data);
      return model.toEntity();
    } catch (e) {
      throw Exception('上传聊天文件失败: $e');
    }
  }
}
