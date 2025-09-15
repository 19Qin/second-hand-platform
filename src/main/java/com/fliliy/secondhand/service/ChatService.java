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
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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
    
    
    /**
     * 创建或获取聊天室
     */
    public ChatRoom createOrGetChatRoom(Long productId, Long buyerId) {
        // 验证商品和买家存在
        Optional<Product> productOpt = productRepository.findById(productId);
        if (!productOpt.isPresent()) {
            throw new RuntimeException("商品不存在");
        }
        
        Product product = productOpt.get();
        Long sellerId = product.getSellerId();
        
        // 买家和卖家不能是同一人
        if (buyerId.equals(sellerId)) {
            throw new RuntimeException("不能与自己聊天");
        }
        
        // 检查是否已存在聊天室
        Optional<ChatRoom> existingRoom = chatRoomRepository.findByProductIdAndBuyerId(productId, buyerId);
        if (existingRoom.isPresent()) {
            return existingRoom.get();
        }
        
        // 创建新聊天室
        ChatRoom chatRoom = new ChatRoom(productId, buyerId, sellerId);
        chatRoom.setId(IdGenerator.generateProductId());
        
        logger.info("创建新聊天室 - 商品ID: {}, 买家ID: {}, 卖家ID: {}", productId, buyerId, sellerId);
        
        return chatRoomRepository.save(chatRoom);
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
            response.setDuration(message.getVoiceDuration());
        } else if (message.getMessageType() == ChatMessage.MessageType.SYSTEM) {
            response.setSystemData(message.getSystemData());
        }
        
        return response;
    }
}