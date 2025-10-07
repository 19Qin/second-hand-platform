import '../models/chat_room_model.dart';
import '../models/upload_chat_file_model.dart';

abstract class ChatRemoteDataSource {
  /// 获取聊天列表
  Future<ChatListModel> getChatList({
    int page = 1,
    int size = 20,
  });

  /// 获取聊天记录
  Future<MessageListModel> getChatMessages({
    required String chatRoomId,
    int page = 1,
    int size = 20,
    DateTime? before,
  });

  /// 发送消息
  Future<SendMessageResponse> sendMessage({
    required String chatRoomId,
    required SendMessageRequest request,
  });

  /// 标记消息已读
  Future<void> markAsRead({
    required String chatRoomId,
    String? lastReadMessageId,
  });

  /// 创建聊天室
  Future<CreateChatRoomResponse> createChatRoom({
    required String sellerId,
  });

  /// 开始商品讨论
  Future<CreateChatRoomResponse> startProductDiscussion({
    required String productId,
    String? initialMessage,
  });

  /// 撤回消息
  Future<void> recallMessage({
    required String messageId,
  });

  /// 搜索聊天记录
  Future<MessageListModel> searchMessages({
    required String chatRoomId,
    required String keyword,
    int page = 1,
    int size = 20,
  });

  /// 获取图片消息
  Future<MessageListModel> getImageMessages({
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

  /// 获取在线状态
  Future<bool> getChatRoomOnlineStatus({
    required String chatRoomId,
  });

  /// 导出聊天记录
  Future<String> exportChatHistory({
    required String chatRoomId,
  });

  /// 上传聊天文件
  Future<Map<String, dynamic>> uploadChatFile({
    required String filePath,
    required String type, // image or voice
  });
}
