package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.request.SendMessageRequest;
import com.fliliy.secondhand.dto.response.ChatMessageResponse;
import com.fliliy.secondhand.entity.ChatMessage;
import com.fliliy.secondhand.entity.ChatRoom;
import com.fliliy.secondhand.entity.Product;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.repository.ChatMessageRepository;
import com.fliliy.secondhand.repository.ChatRoomRepository;
import com.fliliy.secondhand.repository.ProductRepository;
import com.fliliy.secondhand.repository.UserRepository;
import com.fliliy.secondhand.util.IdGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class ChatService {
    
    private static final Logger logger = LoggerFactory.getLogger(ChatService.class);
    
    @Autowired
    private ChatRoomRepository chatRoomRepository;
    
    @Autowired
    private ChatMessageRepository chatMessageRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private ProductRepository productRepository;
    
    @Autowired
    private WebSocketMessageService webSocketMessageService;
    
    
    /**
     * 创建或获取聊天室 - 基于用户对唯一性
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public ChatRoom createOrGetChatRoom(Long userId1, Long userId2) {
        // 验证用户存在
        if (!userRepository.existsById(userId1)) {
            throw new RuntimeException("用户不存在: " + userId1);
        }
        if (!userRepository.existsById(userId2)) {
            throw new RuntimeException("用户不存在: " + userId2);
        }
        
        // 用户不能与自己聊天
        if (userId1.equals(userId2)) {
            throw new RuntimeException("不能与自己聊天");
        }
        
        // 首先检查两个用户之间是否已存在聊天室（不区分角色）
        Optional<ChatRoom> existingRoom = chatRoomRepository.findBetweenUsers(userId1, userId2);
        if (existingRoom.isPresent()) {
            logger.info("找到已存在的聊天室 - 用户ID: {} 和 {}, 聊天室ID: {}", 
                    userId1, userId2, existingRoom.get().getId());
            return existingRoom.get();
        }
        
        // 如果不存在，则创建新聊天室
        // 为了保证数据一致性，总是让较小的ID作为buyerId
        Long buyerId = Math.min(userId1, userId2);
        Long sellerId = Math.max(userId1, userId2);
        
        // 创建新聊天室
        ChatRoom chatRoom = new ChatRoom(buyerId, sellerId);
        chatRoom.setId(IdGenerator.generateProductId());
        
        logger.info("创建新聊天室 - 用户1: {}, 用户2: {}, 聊天室ID: {}, 标准化为 buyer: {}, seller: {}", 
                userId1, userId2, chatRoom.getId(), buyerId, sellerId);
        
        return chatRoomRepository.save(chatRoom);
    }
    
    /**
     * 创建或获取聊天室 - 保持向后兼容的方法
     */
    public ChatRoom createOrGetChatRoomByRole(Long buyerId, Long sellerId) {
        return createOrGetChatRoom(buyerId, sellerId);
    }
    
    
    /**
     * 发送带商品关联的消息
     */
    public ChatMessage sendMessageWithProduct(Long chatRoomId, Long senderId, 
                                            String content, Long productId) {
        ChatMessage message = sendTextMessage(chatRoomId, senderId, content);
        if (productId != null) {
            message.setRelatedProductId(productId);
            chatMessageRepository.save(message);
        }
        return message;
    }
    
    /**
     * 获取聊天室讨论的商品列表
     */
    @Transactional(readOnly = true)
    public List<Long> getDiscussedProducts(Long chatRoomId, Long userId) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        return chatMessageRepository.getDiscussedProducts(chatRoomId);
    }
    
    /**
     * 创建商品快照JSON
     */
    private String createProductSnapshot(Product product) {
        // 创建商品快照JSON
        Map<String, Object> snapshot = new HashMap<>();
        snapshot.put("id", product.getId());
        snapshot.put("title", product.getTitle());
        snapshot.put("price", product.getPrice());
        snapshot.put("imageUrl", ""); // 暂时设为空，后续可通过ProductImage关联获取
        snapshot.put("status", product.getStatus());
        snapshot.put("sellerId", product.getSellerId());
        // 转换为JSON字符串 - 这里简化处理，实际项目中应该使用Jackson
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(snapshot);
        } catch (Exception e) {
            return "{}";
        }
    }
    
    /**
     * 获取用户的聊天列表
     */
    @Transactional(readOnly = true)
    public Page<ChatRoom> getChatList(Long userId, int page, int size) {
        Pageable pageable = PageRequest.of(page - 1, size);
        return chatRoomRepository.findByParticipant(userId, pageable);
    }
    
    /**
     * 获取用户的所有聊天室
     */
    @Transactional(readOnly = true)
    public List<ChatRoom> getAllChatRooms(Long userId) {
        return chatRoomRepository.findByParticipant(userId);
    }
    
    /**
     * 获取聊天室详情
     */
    @Transactional(readOnly = true)
    public ChatRoom getChatRoomById(Long chatRoomId) {
        return chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new RuntimeException("聊天室不存在"));
    }
    
    /**
     * 验证用户是否有权限访问聊天室
     */
    @Transactional(readOnly = true)
    public boolean canAccessChatRoom(Long chatRoomId, Long userId) {
        return chatRoomRepository.isParticipant(chatRoomId, userId);
    }
    
    /**
     * 获取聊天记录
     */
    @Transactional(readOnly = true)
    public Page<ChatMessage> getChatMessages(Long chatRoomId, Long userId, int page, int size, LocalDateTime before) {
        // 验证访问权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        Pageable pageable = PageRequest.of(page - 1, size);
        
        if (before != null) {
            return chatMessageRepository.findByChatRoomIdAndSentAtBefore(chatRoomId, before, pageable);
        } else {
            return chatMessageRepository.findByChatRoomIdOrderBySentAtDesc(chatRoomId, pageable);
        }
    }
    
    /**
     * 发送文本消息
     */
    public ChatMessage sendTextMessage(Long chatRoomId, Long senderId, String content) {
        // 验证聊天室和权限
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        if (!chatRoom.isParticipant(senderId)) {
            throw new RuntimeException("无权限在此聊天室发送消息");
        }
        
        // 创建消息
        ChatMessage message = ChatMessage.createTextMessage(chatRoomId, senderId, content);
        message.setId(IdGenerator.generateProductId());
        
        // 保存消息
        message = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息
        updateChatRoomLastMessage(chatRoom, message);
        
        // WebSocket实时推送
        try {
            ChatMessageResponse response = convertToChatMessageResponse(message);
            webSocketMessageService.broadcastMessageToChatRoom(chatRoomId, response);
            
            // 向接收者发送推送通知
            Long receiverId = chatRoom.getOtherParticipant(senderId);
            if (receiverId != null && !webSocketMessageService.isUserOnline(receiverId)) {
                // 如果接收者离线，可以发送推送通知
                webSocketMessageService.sendNotificationToUser(receiverId, 
                    "新消息", content, "chat_message");
            }
        } catch (Exception e) {
            logger.warn("WebSocket推送失败 - 聊天室ID: {}, 错误: {}", chatRoomId, e.getMessage());
        }
        
        logger.info("发送文本消息 - 聊天室ID: {}, 发送者ID: {}, 内容: {}", chatRoomId, senderId, content);
        
        return message;
    }
    
    /**
     * 发送图片消息
     */
    public ChatMessage sendImageMessage(Long chatRoomId, Long senderId, String fileUrl, 
                                      String thumbnailUrl, Integer width, Integer height, Integer fileSize) {
        // 验证聊天室和权限
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        if (!chatRoom.isParticipant(senderId)) {
            throw new RuntimeException("无权限在此聊天室发送消息");
        }
        
        // 创建图片消息
        ChatMessage message = ChatMessage.createImageMessage(chatRoomId, senderId, fileUrl, 
                thumbnailUrl, width, height, fileSize);
        message.setId(IdGenerator.generateProductId());
        
        // 保存消息
        message = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息
        updateChatRoomLastMessage(chatRoom, message);
        
        logger.info("发送图片消息 - 聊天室ID: {}, 发送者ID: {}, 文件URL: {}", chatRoomId, senderId, fileUrl);
        
        return message;
    }
    
    /**
     * 发送语音消息
     */
    public ChatMessage sendVoiceMessage(Long chatRoomId, Long senderId, String fileUrl, 
                                      Integer duration, Integer fileSize) {
        // 验证聊天室和权限
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        if (!chatRoom.isParticipant(senderId)) {
            throw new RuntimeException("无权限在此聊天室发送消息");
        }
        
        // 创建语音消息
        ChatMessage message = ChatMessage.createVoiceMessage(chatRoomId, senderId, fileUrl, duration, fileSize);
        message.setId(IdGenerator.generateProductId());
        
        // 保存消息
        message = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息
        updateChatRoomLastMessage(chatRoom, message);
        
        logger.info("发送语音消息 - 聊天室ID: {}, 发送者ID: {}, 时长: {}秒", chatRoomId, senderId, duration);
        
        return message;
    }
    
    /**
     * 发送系统消息
     */
    public ChatMessage sendSystemMessage(Long chatRoomId, ChatMessage.SystemMessageType systemType, 
                                       String content, String systemData) {
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        
        // 创建系统消息
        ChatMessage message = ChatMessage.createSystemMessage(chatRoomId, systemType, content, systemData);
        message.setId(IdGenerator.generateProductId());
        
        // 保存消息
        message = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息（系统消息不增加未读数）
        chatRoom.setLastMessageId(message.getId());
        chatRoom.setLastMessageContent(content);
        chatRoom.setLastMessageType(ChatRoom.MessageType.SYSTEM);
        chatRoom.setLastMessageTime(LocalDateTime.now());
        chatRoom.setLastMessageSenderId(null);
        chatRoom.setTotalMessages(chatRoom.getTotalMessages() + 1);
        
        chatRoomRepository.save(chatRoom);
        
        logger.info("发送系统消息 - 聊天室ID: {}, 类型: {}, 内容: {}", chatRoomId, systemType, content);
        
        return message;
    }
    
    /**
     * 标记消息为已读
     */
    public void markMessagesAsRead(Long chatRoomId, Long userId) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        // 批量标记消息为已读
        chatMessageRepository.markChatRoomMessagesAsRead(chatRoomId, userId);
        
        // 更新聊天室未读计数
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        chatRoom.markAsRead(userId);
        chatRoomRepository.save(chatRoom);
        
        logger.info("标记消息为已读 - 聊天室ID: {}, 用户ID: {}", chatRoomId, userId);
    }
    
    /**
     * 标记特定消息为已送达
     */
    public void markMessageAsDelivered(Long messageId, Long userId) {
        ChatMessage message = chatMessageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("消息不存在"));
        
        // 验证权限：只有接收者可以标记为已送达
        ChatRoom chatRoom = getChatRoomById(message.getChatRoomId());
        if (!chatRoom.isParticipant(userId) || message.getSenderId().equals(userId)) {
            throw new RuntimeException("无权限标记此消息");
        }
        
        chatMessageRepository.markAsDelivered(messageId);
        logger.info("标记消息为已送达 - 消息ID: {}, 用户ID: {}", messageId, userId);
    }
    
    /**
     * 标记特定消息为已读
     */
    public void markMessageAsRead(Long messageId, Long userId) {
        ChatMessage message = chatMessageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("消息不存在"));
        
        // 验证权限：只有接收者可以标记为已读
        ChatRoom chatRoom = getChatRoomById(message.getChatRoomId());
        if (!chatRoom.isParticipant(userId) || message.getSenderId().equals(userId)) {
            throw new RuntimeException("无权限标记此消息");
        }
        
        chatMessageRepository.markAsRead(messageId);
        logger.info("标记消息为已读 - 消息ID: {}, 用户ID: {}", messageId, userId);
    }
    
    /**
     * 获取消息送达统计
     */
    @Transactional(readOnly = true)
    public Map<String, Long> getMessageDeliveryStats(Long chatRoomId, Long userId) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        Map<String, Long> stats = new HashMap<>();
        stats.put("sent", chatMessageRepository.countByChatRoomIdAndSenderIdAndStatus(chatRoomId, userId, ChatMessage.MessageStatus.SENT));
        stats.put("delivered", chatMessageRepository.countByChatRoomIdAndSenderIdAndStatus(chatRoomId, userId, ChatMessage.MessageStatus.DELIVERED));
        stats.put("read", chatMessageRepository.countByChatRoomIdAndSenderIdAndStatus(chatRoomId, userId, ChatMessage.MessageStatus.READ));
        stats.put("failed", chatMessageRepository.countByChatRoomIdAndSenderIdAndStatus(chatRoomId, userId, ChatMessage.MessageStatus.FAILED));
        
        return stats;
    }
    
    /**
     * 撤回消息
     */
    public boolean recallMessage(Long messageId, Long userId) {
        // 查找可撤回的消息（2分钟内）
        LocalDateTime timeLimit = LocalDateTime.now().minusMinutes(2);
        ChatMessage message = chatMessageRepository.findRecallableMessage(messageId, userId, timeLimit);
        
        if (message == null) {
            return false; // 消息不存在或不能撤回
        }
        
        // 撤回消息
        chatMessageRepository.recallMessage(messageId);
        
        logger.info("撤回消息 - 消息ID: {}, 用户ID: {}", messageId, userId);
        
        return true;
    }
    
    /**
     * 获取用户未读消息总数
     */
    @Transactional(readOnly = true)
    public Long getTotalUnreadCount(Long userId) {
        return chatRoomRepository.getTotalUnreadCount(userId);
    }
    
    /**
     * 搜索聊天记录
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> searchMessages(Long chatRoomId, Long userId, String keyword) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限搜索此聊天室消息");
        }
        
        return chatMessageRepository.searchMessages(chatRoomId, keyword);
    }
    
    /**
     * 获取聊天室的图片消息
     */
    @Transactional(readOnly = true)
    public List<ChatMessage> getImageMessages(Long chatRoomId, Long userId) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        return chatMessageRepository.findImageMessages(chatRoomId);
    }
    
    /**
     * 关闭聊天室
     */
    public void closeChatRoom(Long chatRoomId, Long userId) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限关闭此聊天室");
        }
        
        chatRoomRepository.closeChatRoom(chatRoomId);
        
        logger.info("关闭聊天室 - 聊天室ID: {}, 操作用户ID: {}", chatRoomId, userId);
    }
    
    /**
     * 更新聊天室最后消息信息
     */
    private void updateChatRoomLastMessage(ChatRoom chatRoom, ChatMessage message) {
        // 1. 更新基本的最后消息信息
        chatRoomRepository.updateLastMessage(
            chatRoom.getId(), 
            message.getId(), 
            message.getDisplayContent(),
            ChatRoom.MessageType.valueOf(message.getMessageType().name()), 
            message.getSenderId()
        );
        
        // 2. 增加消息总数
        chatRoomRepository.incrementTotalMessages(chatRoom.getId());
        
        // 3. 增加未读数（根据发送者不同分别处理）
        chatRoomRepository.incrementBuyerUnreadCount(chatRoom.getId(), message.getSenderId());
        chatRoomRepository.incrementSellerUnreadCount(chatRoom.getId(), message.getSenderId());
    }
    
    /**
     * 获取聊天室参与者信息
     */
    @Transactional(readOnly = true)
    public User getChatRoomParticipant(Long chatRoomId, Long currentUserId) {
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        
        if (!chatRoom.isParticipant(currentUserId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        Long otherUserId = chatRoom.getOtherParticipant(currentUserId);
        if (otherUserId == null) {
            throw new RuntimeException("无法找到聊天对象");
        }
        
        return userRepository.findById(otherUserId)
                .orElseThrow(() -> new RuntimeException("聊天对象不存在"));
    }

    /**
     * 检查用户是否有权限访问聊天室
     */
    @Transactional(readOnly = true)
    public boolean hasAccessToChatRoom(Long chatRoomId, Long userId) {
        return canAccessChatRoom(chatRoomId, userId);
    }

    /**
     * 发送消息 - WebSocket使用
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public ChatMessageResponse sendMessage(Long chatRoomId, Long senderId, SendMessageRequest request) {
        ChatMessage message;
        
        switch (request.getType()) {
            case "TEXT":
                message = sendTextMessage(chatRoomId, senderId, request.getContent());
                break;
            case "IMAGE":
                message = sendImageMessage(chatRoomId, senderId, request.getContent(), 
                    request.getThumbnail(), null, null, null);
                break;
            case "VOICE":
                message = sendVoiceMessage(chatRoomId, senderId, request.getContent(), 
                    request.getDuration(), null);
                break;
            default:
                throw new RuntimeException("不支持的消息类型: " + request.getType());
        }
        
        return convertToChatMessageResponse(message);
    }

    /**
     * 检查用户是否在线
     */
    public boolean isUserOnline(Long userId) {
        return webSocketMessageService.isUserOnline(userId);
    }
    
    /**
     * 置顶/取消置顶聊天室
     */
    public void toggleChatRoomPin(Long chatRoomId, Long userId) {
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        
        // 验证权限
        if (!chatRoom.isParticipant(userId)) {
            throw new RuntimeException("无权限操作此聊天室");
        }
        
        boolean currentPinned = chatRoom.isPinned(userId);
        chatRoom.setPinned(userId, !currentPinned);
        
        chatRoomRepository.save(chatRoom);
        
        logger.info("切换聊天室置顶状态 - 聊天室ID: {}, 用户ID: {}, 置顶: {}", 
                chatRoomId, userId, !currentPinned);
    }
    
    /**
     * 开启/关闭聊天室免打扰
     */
    public void toggleChatRoomMute(Long chatRoomId, Long userId) {
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        
        // 验证权限
        if (!chatRoom.isParticipant(userId)) {
            throw new RuntimeException("无权限操作此聊天室");
        }
        
        boolean currentMuted = chatRoom.isMuted(userId);
        chatRoom.setMuted(userId, !currentMuted);
        
        chatRoomRepository.save(chatRoom);
        
        logger.info("切换聊天室免打扰状态 - 聊天室ID: {}, 用户ID: {}, 免打扰: {}", 
                chatRoomId, userId, !currentMuted);
    }
    
    /**
     * 导出聊天记录
     */
    @Transactional(readOnly = true)
    public Map<String, Object> exportChatHistory(Long chatRoomId, Long userId, 
                                                LocalDateTime startTime, LocalDateTime endTime) {
        // 验证权限
        if (!canAccessChatRoom(chatRoomId, userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        List<ChatMessage> messages;
        
        if (startTime != null && endTime != null) {
            messages = chatMessageRepository.findByTimeRange(chatRoomId, startTime, endTime);
        } else {
            messages = chatMessageRepository.findByChatRoomIdOrderBySentAtAsc(chatRoomId);
        }
        
        // 获取聊天室参与者信息
        User buyer = userRepository.findById(chatRoom.getBuyerId()).orElse(null);
        User seller = userRepository.findById(chatRoom.getSellerId()).orElse(null);
        
        Map<String, Object> exportData = new HashMap<>();
        exportData.put("chatRoomId", chatRoomId);
        exportData.put("exportTime", LocalDateTime.now());
        Map<String, Object> timeRange = new HashMap<>();
        timeRange.put("start", startTime != null ? startTime : chatRoom.getCreatedAt());
        timeRange.put("end", endTime != null ? endTime : LocalDateTime.now());
        exportData.put("timeRange", timeRange);
        Map<String, Object> participants = new HashMap<>();
        if (buyer != null) {
            Map<String, Object> buyerInfo = new HashMap<>();
            buyerInfo.put("id", buyer.getId());
            buyerInfo.put("username", buyer.getUsername());
            participants.put("buyer", buyerInfo);
        } else {
            participants.put("buyer", null);
        }
        if (seller != null) {
            Map<String, Object> sellerInfo = new HashMap<>();
            sellerInfo.put("id", seller.getId());
            sellerInfo.put("username", seller.getUsername());
            participants.put("seller", sellerInfo);
        } else {
            participants.put("seller", null);
        }
        exportData.put("participants", participants);
        exportData.put("totalMessages", messages.size());
        
        List<Map<String, Object>> messageList = messages.stream()
                .map(msg -> {
                    Map<String, Object> msgMap = new HashMap<>();
                    msgMap.put("id", msg.getId());
                    msgMap.put("senderId", msg.getSenderId());
                    msgMap.put("type", msg.getMessageType().name());
                    msgMap.put("content", msg.getDisplayContent());
                    msgMap.put("sentAt", msg.getSentAt());
                    msgMap.put("isRecalled", msg.getIsRecalled());
                    return msgMap;
                })
                .collect(Collectors.toList());
        
        exportData.put("messages", messageList);
        
        logger.info("导出聊天记录 - 聊天室ID: {}, 用户ID: {}, 消息数: {}", 
                chatRoomId, userId, messages.size());
        
        return exportData;
    }
    
    /**
     * 获取聊天室设置
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getChatRoomSettings(Long chatRoomId, Long userId) {
        ChatRoom chatRoom = getChatRoomById(chatRoomId);
        
        // 验证权限
        if (!chatRoom.isParticipant(userId)) {
            throw new RuntimeException("无权限访问此聊天室");
        }
        
        Map<String, Object> settings = new HashMap<>();
        settings.put("chatRoomId", chatRoomId);
        settings.put("isPinned", chatRoom.isPinned(userId));
        settings.put("isMuted", chatRoom.isMuted(userId));
        settings.put("unreadCount", chatRoom.getUnreadCount(userId));
        settings.put("totalMessages", chatRoom.getTotalMessages());
        
        return settings;
    }

    /**
     * 将ChatMessage转换为ChatMessageResponse
     */
    private ChatMessageResponse convertToChatMessageResponse(ChatMessage message) {
        ChatMessageResponse response = new ChatMessageResponse();
        response.setId(message.getId());
        response.setSenderId(message.getSenderId());
        response.setType(message.getMessageType().name());
        response.setContent(message.getContent());
        response.setSentAt(message.getSentAt());
        response.setIsFromMe(false); // 在实际使用时需要根据当前用户判断
        response.setStatus("SENT");
        
        // 设置额外信息
        if (message.getMessageType() == ChatMessage.MessageType.IMAGE) {
            response.setThumbnail(message.getThumbnailUrl());
            if (message.getImageWidth() != null && message.getImageHeight() != null) {
                response.setImageWidth(message.getImageWidth());
                response.setImageHeight(message.getImageHeight());
            }
        } else if (message.getMessageType() == ChatMessage.MessageType.VOICE) {
            response.setDuration(message.getDuration());
        } else if (message.getMessageType() == ChatMessage.MessageType.SYSTEM) {
            // 需要将systemData从String转换为Map
            if (message.getSystemData() != null) {
                Map<String, Object> systemDataMap = new HashMap<>();
                systemDataMap.put("data", message.getSystemData());
                response.setSystemData(systemDataMap);
            }
        } else if (message.getMessageType() == ChatMessage.MessageType.PRODUCT_CARD) {
            // 处理商品卡片消息
            if (message.getProductSnapshot() != null) {
                try {
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    @SuppressWarnings("unchecked")
                    Map<String, Object> productData = mapper.readValue(message.getProductSnapshot(), Map.class);
                    response.setSystemData(productData);
                } catch (Exception e) {
                    // 处理JSON解析异常
                    Map<String, Object> fallbackData = new HashMap<>();
                    fallbackData.put("productId", message.getRelatedProductId());
                    response.setSystemData(fallbackData);
                }
            }
        }
        
        return response;
    }
    
    /**
     * 开始商品讨论
     * 验证商品ID有效性，创建聊天室，发送商品卡片消息
     */
    @Transactional
    public ChatMessageResponse startProductDiscussion(Long productId, Long buyerId) {
        logger.info("开始商品讨论 - 商品ID: {}, 买家ID: {}", productId, buyerId);
        
        // 1. 验证商品存在且有效
        Optional<Product> productOpt = productRepository.findByIdAndNotDeleted(productId);
        if (!productOpt.isPresent()) {
            throw new RuntimeException("商品不存在或已删除");
        }
        
        Product product = productOpt.get();
        if (!Product.ProductStatus.ACTIVE.equals(product.getStatus())) {
            throw new RuntimeException("商品不可讨论，当前状态: " + product.getStatus());
        }
        
        // 2. 验证不能与自己讨论
        if (buyerId.equals(product.getSellerId())) {
            throw new RuntimeException("不能讨论自己发布的商品");
        }
        
        // 3. 创建或获取聊天室
        ChatRoom chatRoom = createOrGetChatRoom(buyerId, product.getSellerId());
        
        // 4. 创建商品卡片消息
        ChatMessage productCard = new ChatMessage();
        productCard.setId(IdGenerator.generateProductId());
        productCard.setChatRoomId(chatRoom.getId());
        productCard.setSenderId(null); // 系统消息
        productCard.setMessageType(ChatMessage.MessageType.PRODUCT_CARD);
        productCard.setRelatedProductId(productId);
        productCard.setContent("分享了商品: " + product.getTitle());
        
        // 构建简单的商品快照信息
        String productSnapshotJson = String.format(
            "{\"id\":%d,\"title\":\"%s\",\"price\":%.2f,\"mainImage\":\"%s\",\"condition\":\"%s\",\"status\":\"%s\"}", 
            product.getId(), 
            product.getTitle().replace("\"", "\\\""), 
            product.getPrice(), 
            product.getMainImage() != null ? product.getMainImage() : "",
            product.getProductCondition().name(),
            product.getStatus().name()
        );
        
        productCard.setProductSnapshot(productSnapshotJson);
        productCard.setStatus(ChatMessage.MessageStatus.SENT);
        productCard.setSentAt(LocalDateTime.now());
        
        // 5. 保存消息
        productCard = chatMessageRepository.save(productCard);
        
        // 6. 更新聊天室最后消息信息
        updateChatRoomLastMessage(chatRoom, productCard);
        
        // 7. 发送WebSocket通知
        try {
            ChatMessageResponse response = convertToChatMessageResponse(productCard);
            webSocketMessageService.sendMessageToUser(product.getSellerId(), response);
        } catch (Exception e) {
            logger.warn("发送WebSocket通知失败: {}", e.getMessage());
        }
        
        logger.info("商品讨论开始成功 - 商品ID: {}, 消息ID: {}", productId, productCard.getId());
        
        return convertToChatMessageResponse(productCard);
    }
    
    /**
     * 发送交易申请消息
     */
    @Transactional
    public void sendTransactionRequestMessage(ChatMessage message) {
        logger.info("发送交易申请消息 - 聊天室ID: {}, 交易ID: {}", message.getChatRoomId(), message.getTransactionId());
        
        // 保存消息
        ChatMessage savedMessage = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息
        ChatRoom chatRoom = getChatRoomById(message.getChatRoomId());
        updateChatRoomLastMessage(chatRoom, savedMessage);
        
        // WebSocket实时推送
        try {
            ChatMessageResponse response = convertToChatMessageResponse(savedMessage);
            Long receiverId = chatRoom.getOtherParticipant(message.getSenderId());
            webSocketMessageService.broadcastMessageToChatRoom(message.getChatRoomId(), response);
            webSocketMessageService.sendMessageToUser(receiverId, response);
        } catch (Exception e) {
            logger.warn("发送WebSocket通知失败: {}", e.getMessage());
        }
    }
    
    /**
     * 发送交易响应消息（同意/拒绝）
     */
    @Transactional
    public void sendTransactionResponseMessage(ChatMessage message) {
        logger.info("发送交易响应消息 - 聊天室ID: {}, 交易ID: {}", message.getChatRoomId(), message.getTransactionId());
        
        // 保存消息
        ChatMessage savedMessage = chatMessageRepository.save(message);
        
        // 更新聊天室最后消息信息
        ChatRoom chatRoom = getChatRoomById(message.getChatRoomId());
        chatRoom.setLastMessageId(savedMessage.getId());
        chatRoom.setLastMessageContent(savedMessage.getContent());
        chatRoom.setLastMessageType(ChatRoom.MessageType.SYSTEM);
        chatRoom.setLastMessageTime(LocalDateTime.now());
        chatRoom.setLastMessageSenderId(null);
        chatRoom.setTotalMessages(chatRoom.getTotalMessages() + 1);
        chatRoomRepository.save(chatRoom);
        
        // WebSocket实时推送给双方
        try {
            ChatMessageResponse response = convertToChatMessageResponse(savedMessage);
            webSocketMessageService.broadcastMessageToChatRoom(message.getChatRoomId(), response);
        } catch (Exception e) {
            logger.warn("发送WebSocket通知失败: {}", e.getMessage());
        }
    }
}