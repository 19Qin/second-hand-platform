package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.SendMessageRequest;
import com.fliliy.secondhand.dto.response.ChatMessageResponse;
import com.fliliy.secondhand.dto.response.ChatRoomResponse;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.entity.ChatMessage;
import com.fliliy.secondhand.entity.ChatRoom;
import com.fliliy.secondhand.entity.Product;
import com.fliliy.secondhand.entity.User;
import com.fliliy.secondhand.service.ChatService;
import com.fliliy.secondhand.service.ProductService;
import com.fliliy.secondhand.service.UserService;
import com.fliliy.secondhand.util.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/chats")
public class ChatController {
    
    private static final Logger logger = LoggerFactory.getLogger(ChatController.class);
    
    @Autowired
    private ChatService chatService;
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private ProductService productService;
    
    @Autowired
    private JwtUtil jwtUtil;
    
    /**
     * 创建或获取聊天室
     */
    @PostMapping("/rooms")
    public ResponseEntity<ApiResponse> createChatRoom(@RequestParam Long productId, HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            ChatRoom chatRoom = chatService.createOrGetChatRoom(productId, userId);
            
            ChatRoomResponse response = convertToChatRoomResponse(chatRoom, userId);
            
            logger.info("创建/获取聊天室成功 - 商品ID: {}, 用户ID: {}, 聊天室ID: {}", 
                    productId, userId, chatRoom.getId());
            
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            logger.error("创建聊天室失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 获取聊天列表
     */
    @GetMapping("")
    public ResponseEntity<ApiResponse> getChatList(@RequestParam(defaultValue = "1") int page,
                                                  @RequestParam(defaultValue = "20") int size,
                                                  HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            Page<ChatRoom> chatRooms = chatService.getChatList(userId, page, size);
            
            List<ChatRoomResponse> chatList = chatRooms.getContent().stream()
                    .map(room -> convertToChatRoomResponse(room, userId))
                    .collect(Collectors.toList());
            
            PagedResponse<ChatRoomResponse> response = PagedResponse.of(chatList, chatRooms);
            
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            logger.error("获取聊天列表失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 获取聊天记录
     */
    @GetMapping("/{chatRoomId}/messages")
    public ResponseEntity<ApiResponse> getChatMessages(@PathVariable Long chatRoomId,
                                                      @RequestParam(defaultValue = "1") int page,
                                                      @RequestParam(defaultValue = "20") int size,
                                                      @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime before,
                                                      HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            Page<ChatMessage> messages = chatService.getChatMessages(chatRoomId, userId, page, size, before);
            
            // 获取聊天室信息
            ChatRoom chatRoom = chatService.getChatRoomById(chatRoomId);
            User participant = chatService.getChatRoomParticipant(chatRoomId, userId);
            Product product = productService.getProductById(chatRoom.getProductId());
            
            // 转换消息列表
            List<ChatMessageResponse> messageList = messages.getContent().stream()
                    .map(msg -> convertToChatMessageResponse(msg, userId))
                    .collect(Collectors.toList());
            
            // 构建响应数据
            Map<String, Object> productMap = new HashMap<>();
            productMap.put("id", product.getId());
            productMap.put("title", product.getTitle());
            productMap.put("mainImage", product.getMainImage());
            productMap.put("status", product.getStatus().toString());
            productMap.put("price", product.getPrice().doubleValue());
            
            Map<String, Object> participantMap = new HashMap<>();
            participantMap.put("id", participant.getId());
            participantMap.put("username", participant.getUsername());
            participantMap.put("avatar", participant.getAvatar());
            participantMap.put("isOnline", true); // TODO: 实现在线状态
            
            Map<String, Object> chatInfoMap = new HashMap<>();
            chatInfoMap.put("chatRoomId", chatRoomId);
            chatInfoMap.put("product", productMap);
            chatInfoMap.put("participant", participantMap);
            
            Map<String, Object> paginationMap = new HashMap<>();
            paginationMap.put("page", messages.getNumber() + 1);
            paginationMap.put("size", messages.getSize());
            paginationMap.put("hasMore", messages.hasNext());
            paginationMap.put("oldestTimestamp", messageList.isEmpty() ? null : messageList.get(messageList.size() - 1).getSentAt());
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("chatInfo", chatInfoMap);
            responseData.put("messages", messageList);
            responseData.put("pagination", paginationMap);
            
            // 标记消息为已读
            chatService.markMessagesAsRead(chatRoomId, userId);
            
            return ResponseEntity.ok(ApiResponse.success(responseData));
        } catch (Exception e) {
            logger.error("获取聊天记录失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 发送消息
     */
    @PostMapping("/{chatRoomId}/messages")
    public ResponseEntity<ApiResponse> sendMessage(@PathVariable Long chatRoomId,
                                                  @Valid @RequestBody SendMessageRequest request,
                                                  HttpServletRequest httpRequest) {
        try {
            Long userId = getCurrentUserId(httpRequest);
            ChatMessage message;
            
            switch (request.getType().toUpperCase()) {
                case "TEXT":
                    message = chatService.sendTextMessage(chatRoomId, userId, request.getContent());
                    break;
                case "IMAGE":
                    message = chatService.sendImageMessage(chatRoomId, userId, request.getContent(),
                            request.getThumbnail(), request.getWidth(), request.getHeight(), request.getFileSize());
                    break;
                case "VOICE":
                    message = chatService.sendVoiceMessage(chatRoomId, userId, request.getContent(),
                            request.getDuration(), request.getFileSize());
                    break;
                default:
                    return ResponseEntity.ok(ApiResponse.error("不支持的消息类型"));
            }
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("messageId", message.getId());
            responseData.put("sentAt", message.getSentAt());
            responseData.put("status", message.getStatus().toString());
            
            return ResponseEntity.ok(ApiResponse.success(responseData));
        } catch (Exception e) {
            logger.error("发送消息失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 标记消息为已读
     */
    @PostMapping("/{chatRoomId}/read")
    public ResponseEntity<ApiResponse> markAsRead(@PathVariable Long chatRoomId, HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            chatService.markMessagesAsRead(chatRoomId, userId);
            
            return ResponseEntity.ok(ApiResponse.success("标记已读成功"));
        } catch (Exception e) {
            logger.error("标记已读失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 撤回消息
     */
    @PostMapping("/messages/{messageId}/recall")
    public ResponseEntity<ApiResponse> recallMessage(@PathVariable Long messageId, HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            boolean success = chatService.recallMessage(messageId, userId);
            
            if (success) {
                return ResponseEntity.ok(ApiResponse.success("撤回成功"));
            } else {
                return ResponseEntity.ok(ApiResponse.error("撤回失败，消息不存在或超过时间限制"));
            }
        } catch (Exception e) {
            logger.error("撤回消息失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 获取未读消息总数
     */
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse> getUnreadCount(HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            Long unreadCount = chatService.getTotalUnreadCount(userId);
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("unreadCount", unreadCount);
            return ResponseEntity.ok(ApiResponse.success(responseData));
        } catch (Exception e) {
            logger.error("获取未读消息数失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 搜索聊天记录
     */
    @GetMapping("/{chatRoomId}/search")
    public ResponseEntity<ApiResponse> searchMessages(@PathVariable Long chatRoomId,
                                                     @RequestParam String keyword,
                                                     HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            List<ChatMessage> messages = chatService.searchMessages(chatRoomId, userId, keyword);
            
            List<ChatMessageResponse> messageList = messages.stream()
                    .map(msg -> convertToChatMessageResponse(msg, userId))
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(ApiResponse.success(messageList));
        } catch (Exception e) {
            logger.error("搜索聊天记录失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 获取聊天室图片消息
     */
    @GetMapping("/{chatRoomId}/images")
    public ResponseEntity<ApiResponse> getImageMessages(@PathVariable Long chatRoomId, HttpServletRequest request) {
        try {
            Long userId = getCurrentUserId(request);
            List<ChatMessage> messages = chatService.getImageMessages(chatRoomId, userId);
            
            List<ChatMessageResponse> messageList = messages.stream()
                    .map(msg -> convertToChatMessageResponse(msg, userId))
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(ApiResponse.success(messageList));
        } catch (Exception e) {
            logger.error("获取图片消息失败", e);
            return ResponseEntity.ok(ApiResponse.error(e.getMessage()));
        }
    }
    
    // 工具方法
    private Long getCurrentUserId(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            String userIdStr = jwtUtil.getUserIdFromToken(token);
            return Long.valueOf(userIdStr);
        }
        throw new RuntimeException("未找到有效的认证令牌");
    }
    
    private ChatRoomResponse convertToChatRoomResponse(ChatRoom chatRoom, Long currentUserId) {
        ChatRoomResponse response = new ChatRoomResponse();
        response.setChatRoomId(chatRoom.getId());
        response.setTransactionId(chatRoom.getTransactionId());
        response.setUnreadCount(chatRoom.getUnreadCount(currentUserId));
        response.setTotalMessages(chatRoom.getTotalMessages());
        response.setCreatedAt(chatRoom.getCreatedAt());
        response.setUpdatedAt(chatRoom.getUpdatedAt());
        
        // 设置商品信息
        try {
            Product product = productService.getProductById(chatRoom.getProductId());
            ChatRoomResponse.ProductInfo productInfo = new ChatRoomResponse.ProductInfo();
            productInfo.setId(product.getId());
            productInfo.setTitle(product.getTitle());
            productInfo.setPrice(product.getPrice().doubleValue());
            productInfo.setMainImage(product.getMainImage());
            productInfo.setStatus(product.getStatus().toString());
            response.setProduct(productInfo);
        } catch (Exception e) {
            logger.warn("获取商品信息失败: {}", e.getMessage());
        }
        
        // 设置参与者信息
        try {
            User participant = chatService.getChatRoomParticipant(chatRoom.getId(), currentUserId);
            ChatRoomResponse.ParticipantInfo participantInfo = new ChatRoomResponse.ParticipantInfo();
            participantInfo.setId(participant.getId());
            participantInfo.setUsername(participant.getUsername());
            participantInfo.setAvatar(participant.getAvatar());
            participantInfo.setIsOnline(true); // TODO: 实现在线状态
            response.setParticipant(participantInfo);
        } catch (Exception e) {
            logger.warn("获取参与者信息失败: {}", e.getMessage());
        }
        
        // 设置最后消息信息
        if (chatRoom.getLastMessageId() != null) {
            ChatRoomResponse.LastMessageInfo lastMessage = new ChatRoomResponse.LastMessageInfo();
            lastMessage.setId(chatRoom.getLastMessageId());
            lastMessage.setContent(chatRoom.getLastMessageContent());
            lastMessage.setType(chatRoom.getLastMessageType() != null ? chatRoom.getLastMessageType().toString() : null);
            lastMessage.setSentAt(chatRoom.getLastMessageTime());
            lastMessage.setIsFromMe(currentUserId.equals(chatRoom.getLastMessageSenderId()));
            response.setLastMessage(lastMessage);
        }
        
        return response;
    }
    
    private ChatMessageResponse convertToChatMessageResponse(ChatMessage message, Long currentUserId) {
        ChatMessageResponse response = new ChatMessageResponse();
        response.setId(message.getId());
        response.setSenderId(message.getSenderId());
        response.setType(message.getMessageType().toString());
        response.setContent(message.getDisplayContent());
        response.setSentAt(message.getSentAt());
        response.setIsFromMe(message.getSenderId() != null && currentUserId.equals(message.getSenderId()));
        response.setStatus(message.getStatus().toString());
        response.setIsRecalled(message.getIsRecalled());
        response.setRecalledAt(message.getRecalledAt());
        
        // 设置发送者姓名
        if (message.getSenderId() != null) {
            try {
                User sender = userService.getUserById(message.getSenderId());
                response.setSenderName(sender.getUsername());
            } catch (Exception e) {
                response.setSenderName("未知用户");
            }
        } else {
            response.setSenderName("系统");
        }
        
        // 图片消息相关字段
        if (message.getMessageType() == ChatMessage.MessageType.IMAGE) {
            response.setThumbnail(message.getThumbnailUrl());
            if (message.getImageWidth() != null && message.getImageHeight() != null) {
                response.setImageSize(new ChatMessageResponse.ImageSize(message.getImageWidth(), message.getImageHeight()));
            }
        }
        
        // 语音消息相关字段
        if (message.getMessageType() == ChatMessage.MessageType.VOICE) {
            response.setDuration(message.getDuration());
        }
        
        return response;
    }
}