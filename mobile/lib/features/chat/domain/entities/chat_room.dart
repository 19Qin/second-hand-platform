class ChatRoomEntity {
  final String chatRoomId;
  final String? transactionId;
  final ProductInfoEntity? product;
  final ParticipantEntity participant;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final int totalMessages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transactionStatus; // INQUIRY, AGREED, COMPLETED, CANCELLED

  const ChatRoomEntity({
    required this.chatRoomId,
    this.transactionId,
    this.product,
    required this.participant,
    this.lastMessage,
    required this.unreadCount,
    required this.totalMessages,
    required this.createdAt,
    required this.updatedAt,
    this.transactionStatus,
  });
}

class ProductInfoEntity {
  final String id;
  final String title;
  final double price;
  final String? mainImage;
  final String status;

  const ProductInfoEntity({
    required this.id,
    required this.title,
    required this.price,
    this.mainImage,
    required this.status,
  });
}

class ParticipantEntity {
  final String id;
  final String username;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const ParticipantEntity({
    required this.id,
    required this.username,
    this.avatar,
    required this.isOnline,
    this.lastSeenAt,
  });
}

class MessageEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String type; // TEXT, IMAGE, VOICE, SYSTEM, TRANSACTION_REQUEST
  final String content;
  final String? thumbnail;
  final ImageSizeEntity? imageSize;
  final int? duration; // Voice duration (seconds)
  final String? waveform; // Voice waveform data
  final DateTime sentAt;
  final bool isFromMe;
  final String status; // SENT, DELIVERED, READ, SYSTEM
  final SystemDataEntity? systemData;
  final String? transactionId; // 关联的交易ID
  final String? productId; // 关联的商品ID

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    this.thumbnail,
    this.imageSize,
    this.duration,
    this.waveform,
    required this.sentAt,
    required this.isFromMe,
    required this.status,
    this.systemData,
    this.transactionId,
    this.productId,
  });
}

class ImageSizeEntity {
  final int width;
  final int height;

  const ImageSizeEntity({
    required this.width,
    required this.height,
  });
}

class SystemDataEntity {
  final String? transactionCode;
  final DateTime? meetingTime;
  final String? location;

  const SystemDataEntity({
    this.transactionCode,
    this.meetingTime,
    this.location,
  });
}

class ChatInfoEntity {
  final String chatRoomId;
  final ProductInfoEntity? product;
  final ParticipantEntity participant;
  final List<Map<String, dynamic>>? discussedProducts;

  const ChatInfoEntity({
    required this.chatRoomId,
    this.product,
    required this.participant,
    this.discussedProducts,
  });
}

class ChatListEntity {
  final List<ChatRoomEntity> content;
  final PaginationEntity pagination;

  const ChatListEntity({
    required this.content,
    required this.pagination,
  });
}

class PaginationEntity {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isFirst;
  final bool isLast;

  const PaginationEntity({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.isFirst,
    required this.isLast,
  });
}

class MessageListEntity {
  final ChatInfoEntity chatInfo;
  final List<MessageEntity> messages;
  final PaginationEntity pagination;

  const MessageListEntity({
    required this.chatInfo,
    required this.messages,
    required this.pagination,
  });
}
