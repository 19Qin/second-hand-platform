import '../entities/chat_room.dart';
import '../usecases/upload_chat_file.dart';

abstract class ChatRepository {
  /// 获取聊天列表
  Future<ChatListEntity> getChatList({
    int page = 1,
    int size = 20,
  });

  /// 获取聊天记录
  Future<MessageListEntity> getChatMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  });

  /// 发送消息
  Future<Map<String, dynamic>> sendMessage({
    required String chatRoomId,
    required String type,
    required String content,
    String? thumbnail,
    int? width,
    int? height,
    int? duration,
    int? fileSize,
  });

  /// 标记消息已读
  Future<void> markAsRead({
    required String chatRoomId,
    String? lastReadMessageId,
  });

  /// 创建聊天室
  Future<Map<String, dynamic>> createChatRoom({
    required String sellerId,
  });

  /// 开始商品讨论
  Future<Map<String, dynamic>> startProductDiscussion({
    required String productId,
    String? initialMessage,
  });

  /// 撤回消息
  Future<void> recallMessage({
    required String messageId,
  });

  /// 搜索聊天记录
  Future<MessageListEntity> searchMessages({
    required String chatRoomId,
    required String keyword,
    int page = 1,
    int size = 20,
  });

  /// 获取图片消息
  Future<MessageListEntity> getImageMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
  });

  /// 置顶聊天室
  Future<void> toggleChatRoomPin({
    required String chatRoomId,
  });

  /// 静音聊天室
  Future<void> toggleChatRoomMute({
    required String chatRoomId,
  });

  /// 获取未读消息数
  Future<int> getUnreadCount();

  /// 获取总未读消息数
  Future<int> getTotalUnreadCount();

  /// 获取在线状态
  Future<bool> getChatRoomOnlineStatus({
    required String chatRoomId,
  });

  /// 导出聊天记录
  Future<String> exportChatHistory({
    required String chatRoomId,
  });

  /// 上传聊天文件
  Future<UploadChatFileResponse> uploadChatFile({
    required String filePath,
    required String type,
  });
}
