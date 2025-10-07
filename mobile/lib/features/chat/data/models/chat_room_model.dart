import '../../domain/entities/chat_room.dart';

class ChatRoomModel {
  final String chatRoomId;
  final String? transactionId;
  final ProductInfoModel? product;
  final ParticipantModel participant;
  final MessageModel? lastMessage;
  final int unreadCount;
  final int totalMessages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transactionStatus;

  const ChatRoomModel({
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

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
      product: json['product'] != null 
          ? ProductInfoModel.fromJson(json['product']) 
          : null,
      participant: ParticipantModel.fromJson(json['participant']),
      lastMessage: json['lastMessage'] != null 
          ? MessageModel.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      transactionStatus: json['transactionStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'transactionId': transactionId,
      'product': product?.toJson(),
      'participant': participant.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'totalMessages': totalMessages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transactionStatus': transactionStatus,
    };
  }

  ChatRoomEntity toEntity() => ChatRoomEntity(
        chatRoomId: chatRoomId,
        transactionId: transactionId,
        product: product?.toEntity(),
        participant: participant.toEntity(),
        lastMessage: lastMessage?.toEntity(),
        unreadCount: unreadCount,
        totalMessages: totalMessages,
        createdAt: createdAt,
        updatedAt: updatedAt,
        transactionStatus: transactionStatus,
      );
}

class ProductInfoModel {
  final String id;
  final String title;
  final double price;
  final String? mainImage;
  final String status;

  const ProductInfoModel({
    required this.id,
    required this.title,
    required this.price,
    this.mainImage,
    required this.status,
  });

  factory ProductInfoModel.fromJson(Map<String, dynamic> json) {
    return ProductInfoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      mainImage: json['mainImage']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'mainImage': mainImage,
      'status': status,
    };
  }

  ProductInfoEntity toEntity() => ProductInfoEntity(
        id: id,
        title: title,
        price: price,
        mainImage: mainImage,
        status: status,
      );
}

class ParticipantModel {
  final String id;
  final String username;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const ParticipantModel({
    required this.id,
    required this.username,
    this.avatar,
    required this.isOnline,
    this.lastSeenAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isOnline: json['isOnline'] ?? false,
      lastSeenAt: json['lastSeenAt'] != null 
          ? DateTime.parse(json['lastSeenAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  ParticipantEntity toEntity() => ParticipantEntity(
        id: id,
        username: username,
        avatar: avatar,
        isOnline: isOnline,
        lastSeenAt: lastSeenAt,
      );
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String type;
  final String content;
  final String? thumbnail;
  final ImageSizeModel? imageSize;
  final int? duration;
  final String? waveform;
  final DateTime sentAt;
  final bool isFromMe;
  final String status;
  final SystemDataModel? systemData;
  final String? transactionId;
  final String? productId;

  // 解析时间字符串的辅助方法
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      // 如果时间字符串包含时区信息，直接解析
      if (dateTimeString.contains('T') || dateTimeString.contains('Z') || dateTimeString.contains('+')) {
        return DateTime.parse(dateTimeString);
      }
      // 否则，假设是UTC时间并添加UTC标识
      return DateTime.parse('${dateTimeString}Z').toLocal();
    } catch (e) {
      print('❌ Error parsing datetime: $dateTimeString, error: $e');
      return DateTime.now();
    }
  }

  const MessageModel({
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

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      content: json['content']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      imageSize: json['imageSize'] != null 
          ? ImageSizeModel.fromJson(json['imageSize']) 
          : null,
      duration: json['duration'],
      waveform: json['waveform']?.toString(),
      sentAt: _parseDateTime(json['sentAt']),
      isFromMe: json['isFromMe'] ?? false,
      status: json['status']?.toString() ?? 'SENT',
      transactionId: json['transactionId']?.toString(),
      productId: json['productId']?.toString(),
      systemData: json['systemData'] != null 
          ? SystemDataModel.fromJson(json['systemData']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'content': content,
      'thumbnail': thumbnail,
      'imageSize': imageSize?.toJson(),
      'duration': duration,
      'waveform': waveform,
      'sentAt': sentAt.toIso8601String(),
      'isFromMe': isFromMe,
      'status': status,
      'transactionId': transactionId,
      'productId': productId,
      'systemData': systemData?.toJson(),
    };
  }

  MessageEntity toEntity() => MessageEntity(
        id: id,
        senderId: senderId,
        senderName: senderName,
        type: type,
        content: content,
        thumbnail: thumbnail,
        imageSize: imageSize?.toEntity(),
        duration: duration,
        waveform: waveform,
        sentAt: sentAt,
        isFromMe: isFromMe,
        status: status,
        transactionId: transactionId,
        productId: productId,
        systemData: systemData?.toEntity(),
      );
}

class ImageSizeModel {
  final int width;
  final int height;

  const ImageSizeModel({
    required this.width,
    required this.height,
  });

  factory ImageSizeModel.fromJson(Map<String, dynamic> json) {
    return ImageSizeModel(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }

  ImageSizeEntity toEntity() => ImageSizeEntity(
        width: width,
        height: height,
      );
}

class SystemDataModel {
  final String? transactionCode;
  final DateTime? meetingTime;
  final String? location;

  const SystemDataModel({
    this.transactionCode,
    this.meetingTime,
    this.location,
  });

  factory SystemDataModel.fromJson(Map<String, dynamic> json) {
    return SystemDataModel(
      transactionCode: json['transactionCode']?.toString(),
      meetingTime: json['meetingTime'] != null 
          ? DateTime.parse(json['meetingTime']) 
          : null,
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionCode': transactionCode,
      'meetingTime': meetingTime?.toIso8601String(),
      'location': location,
    };
  }

  SystemDataEntity toEntity() => SystemDataEntity(
        transactionCode: transactionCode,
        meetingTime: meetingTime,
        location: location,
      );
}

class ChatInfoModel {
  final String chatRoomId;
  final ProductInfoModel? product;
  final ParticipantModel participant;
  final List<Map<String, dynamic>>? discussedProducts;

  const ChatInfoModel({
    required this.chatRoomId,
    this.product,
    required this.participant,
    this.discussedProducts,
  });

  factory ChatInfoModel.fromJson(Map<String, dynamic> json) {
    return ChatInfoModel(
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      product: json['product'] != null 
          ? ProductInfoModel.fromJson(json['product']) 
          : null,
      participant: ParticipantModel.fromJson(json['participant']),
      discussedProducts: json['discussedProducts'] != null 
          ? List<Map<String, dynamic>>.from(json['discussedProducts']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'product': product?.toJson(),
      'participant': participant.toJson(),
      'discussedProducts': discussedProducts,
    };
  }

  ChatInfoEntity toEntity() => ChatInfoEntity(
        chatRoomId: chatRoomId,
        product: product?.toEntity(),
        participant: participant.toEntity(),
        discussedProducts: discussedProducts,
      );
}

class ChatListModel {
  final List<ChatRoomModel> content;
  final PaginationModel pagination;

  const ChatListModel({
    required this.content,
    required this.pagination,
  });

  factory ChatListModel.fromJson(Map<String, dynamic> json) {
    return ChatListModel(
      content: (json['content'] as List<dynamic>?)
          ?.map((item) => ChatRoomModel.fromJson(item))
          .toList() ?? [],
      pagination: PaginationModel.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  ChatListEntity toEntity() => ChatListEntity(
        content: content.map((item) => item.toEntity()).toList(),
        pagination: pagination.toEntity(),
      );
}

class PaginationModel {
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isFirst;
  final bool isLast;

  const PaginationModel({
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.isFirst,
    required this.isLast,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      size: json['size'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
      isFirst: json['isFirst'] ?? false,
      isLast: json['isLast'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'isFirst': isFirst,
      'isLast': isLast,
    };
  }

  PaginationEntity toEntity() => PaginationEntity(
        page: page,
        size: size,
        total: total,
        totalPages: totalPages,
        hasNext: hasNext,
        hasPrevious: hasPrevious,
        isFirst: isFirst,
        isLast: isLast,
      );
}

class MessageListModel {
  final ChatInfoModel chatInfo;
  final List<MessageModel> messages;
  final PaginationModel pagination;

  const MessageListModel({
    required this.chatInfo,
    required this.messages,
    required this.pagination,
  });

  factory MessageListModel.fromJson(Map<String, dynamic> json) {
    return MessageListModel(
      chatInfo: ChatInfoModel.fromJson(json['chatInfo']),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((item) => MessageModel.fromJson(item))
          .toList() ?? [],
      pagination: PaginationModel.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatInfo': chatInfo.toJson(),
      'messages': messages.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  MessageListEntity toEntity() => MessageListEntity(
        chatInfo: chatInfo.toEntity(),
        messages: messages.map((item) => item.toEntity()).toList(),
        pagination: pagination.toEntity(),
      );
}

class SendMessageRequest {
  final String type;
  final String content;
  final String? thumbnail;
  final int? width;
  final int? height;
  final int? duration;
  final int? fileSize;

  const SendMessageRequest({
    required this.type,
    required this.content,
    this.thumbnail,
    this.width,
    this.height,
    this.duration,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
      'content': content,
    };
    
    if (thumbnail != null) json['thumbnail'] = thumbnail;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (duration != null) json['duration'] = duration;
    if (fileSize != null) json['fileSize'] = fileSize;
    
    return json;
  }
}

class SendMessageResponse {
  final String messageId;
  final DateTime sentAt;
  final String status;

  const SendMessageResponse({
    required this.messageId,
    required this.sentAt,
    required this.status,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      messageId: json['messageId']?.toString() ?? '',
      sentAt: MessageModel._parseDateTime(json['sentAt']),
      status: json['status']?.toString() ?? 'SENT',
    );
  }
}

class MarkAsReadRequest {
  final String? lastReadMessageId;

  const MarkAsReadRequest({this.lastReadMessageId});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (lastReadMessageId != null) {
      json['lastReadMessageId'] = lastReadMessageId;
    }
    return json;
  }
}

class CreateChatRoomResponse {
  final String chatRoomId;
  final ParticipantModel participant;
  final int unreadCount;
  final int totalMessages;

  const CreateChatRoomResponse({
    required this.chatRoomId,
    required this.participant,
    required this.unreadCount,
    required this.totalMessages,
  });

  factory CreateChatRoomResponse.fromJson(Map<String, dynamic> json) {
    return CreateChatRoomResponse(
      chatRoomId: json['chatRoomId']?.toString() ?? '',
      participant: ParticipantModel.fromJson(json['participant']),
      unreadCount: json['unreadCount'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
    );
  }
}
