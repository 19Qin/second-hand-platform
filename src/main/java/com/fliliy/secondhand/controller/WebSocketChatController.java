package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.dto.request.SendMessageRequest;
import com.fliliy.secondhand.dto.response.ChatMessageResponse;
import com.fliliy.secondhand.service.ChatService;
import com.fliliy.secondhand.service.WebSocketMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
@Slf4j
public class WebSocketChatController {

    private final ChatService chatService;
    private final WebSocketMessageService webSocketMessageService;

    /**
     * 处理发送消息的WebSocket请求
     * 客户端发送到: /app/chat/{chatRoomId}/send
     */
    @MessageMapping("/chat/{chatRoomId}/send")
    public void sendMessage(@DestinationVariable String chatRoomId, 
                           @Payload SendMessageRequest request,
                           SimpMessageHeaderAccessor headerAccessor) {
        
        // 从WebSocket会话属性中获取用户信息
        String userId = (String) headerAccessor.getSessionAttributes().get("userId");
        String mobile = (String) headerAccessor.getSessionAttributes().get("mobile");
        
        log.info("Received WebSocket message from user {} in chatRoom {}: {}", 
                userId, chatRoomId, request.getContent());

        try {
            // 1. 保存消息到数据库
            ChatMessageResponse savedMessage = chatService.sendMessage(
                Long.parseLong(chatRoomId), 
                Long.parseLong(userId), 
                request
            );

            // 2. 通过WebSocket推送消息给聊天室参与者
            webSocketMessageService.broadcastMessageToChatRoom(
                Long.parseLong(chatRoomId), 
                savedMessage
            );

            log.info("Message sent successfully: messageId={}", savedMessage.getId());
            
        } catch (Exception e) {
            log.error("Failed to send message in chatRoom {}: {}", chatRoomId, e.getMessage(), e);
            
            // 发送错误消息给发送者
            webSocketMessageService.sendErrorToUser(
                Long.parseLong(userId),
                "消息发送失败: " + e.getMessage()
            );
        }
    }

    /**
     * 处理用户订阅聊天室的WebSocket请求
     * 客户端订阅: /topic/chat/{chatRoomId}
     */
    @SubscribeMapping("/topic/chat/{chatRoomId}")
    public void subscribeToChatRoom(@DestinationVariable String chatRoomId,
                                   SimpMessageHeaderAccessor headerAccessor) {
        
        String userId = (String) headerAccessor.getSessionAttributes().get("userId");
        
        log.info("User {} subscribed to chatRoom {}", userId, chatRoomId);
        
        try {
            // 验证用户是否有权限访问该聊天室
            boolean hasAccess = chatService.hasAccessToChatRoom(
                Long.parseLong(chatRoomId), 
                Long.parseLong(userId)
            );
            
            if (!hasAccess) {
                log.warn("User {} has no access to chatRoom {}", userId, chatRoomId);
                webSocketMessageService.sendErrorToUser(
                    Long.parseLong(userId),
                    "无权限访问该聊天室"
                );
                return;
            }

            // 记录用户连接到聊天室
            webSocketMessageService.addUserToChatRoom(
                Long.parseLong(chatRoomId), 
                Long.parseLong(userId)
            );
            
            // 标记消息为已读
            chatService.markMessagesAsRead(
                Long.parseLong(chatRoomId), 
                Long.parseLong(userId)
            );
            
        } catch (Exception e) {
            log.error("Failed to subscribe user {} to chatRoom {}: {}", 
                    userId, chatRoomId, e.getMessage(), e);
        }
    }

    /**
     * 处理用户在线状态更新
     * 客户端发送到: /app/user/status
     */
    @MessageMapping("/user/status")
    public void updateUserStatus(@Payload String status,
                                SimpMessageHeaderAccessor headerAccessor) {
        
        String userId = (String) headerAccessor.getSessionAttributes().get("userId");
        
        log.info("User {} status updated to: {}", userId, status);
        
        try {
            // 更新用户在线状态
            webSocketMessageService.updateUserOnlineStatus(
                Long.parseLong(userId), 
                "online".equals(status)
            );
            
        } catch (Exception e) {
            log.error("Failed to update status for user {}: {}", userId, e.getMessage(), e);
        }
    }

    /**
     * 处理标记消息已读的WebSocket请求
     * 客户端发送到: /app/chat/{chatRoomId}/read
     */
    @MessageMapping("/chat/{chatRoomId}/read")
    public void markMessagesAsRead(@DestinationVariable String chatRoomId,
                                  @Payload String lastReadMessageId,
                                  SimpMessageHeaderAccessor headerAccessor) {
        
        String userId = (String) headerAccessor.getSessionAttributes().get("userId");
        
        log.info("User {} marking messages as read in chatRoom {} up to messageId {}", 
                userId, chatRoomId, lastReadMessageId);

        try {
            // 标记消息为已读
            chatService.markMessagesAsRead(
                Long.parseLong(chatRoomId), 
                Long.parseLong(userId)
            );

            // 通知聊天室其他参与者消息已读状态更新
            webSocketMessageService.broadcastReadStatusToChatRoom(
                Long.parseLong(chatRoomId),
                Long.parseLong(userId),
                Long.parseLong(lastReadMessageId)
            );
            
        } catch (Exception e) {
            log.error("Failed to mark messages as read: {}", e.getMessage(), e);
        }
    }
}