package com.fliliy.secondhand.config;

import com.fliliy.secondhand.service.WebSocketMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.web.socket.messaging.SessionSubscribeEvent;
import org.springframework.web.socket.messaging.SessionUnsubscribeEvent;

import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class WebSocketEventListener {

    private final WebSocketMessageService webSocketMessageService;

    /**
     * WebSocket连接建立事件
     */
    @EventListener
    public void handleWebSocketConnectListener(SessionConnectedEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        
        Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();
        if (sessionAttributes != null) {
            String userId = (String) sessionAttributes.get("userId");
            String mobile = (String) sessionAttributes.get("mobile");
            
            log.info("WebSocket connection established: sessionId={}, userId={}, mobile={}", 
                    sessionId, userId, mobile);
            
            // 更新用户在线状态
            if (userId != null) {
                webSocketMessageService.updateUserOnlineStatus(Long.parseLong(userId), true);
            }
        } else {
            log.warn("WebSocket connection established without session attributes: sessionId={}", sessionId);
        }
    }

    /**
     * WebSocket连接断开事件
     */
    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        
        Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();
        if (sessionAttributes != null) {
            String userId = (String) sessionAttributes.get("userId");
            String mobile = (String) sessionAttributes.get("mobile");
            
            log.info("WebSocket connection closed: sessionId={}, userId={}, mobile={}", 
                    sessionId, userId, mobile);
            
            // 更新用户离线状态
            if (userId != null) {
                Long userIdLong = Long.parseLong(userId);
                webSocketMessageService.updateUserOnlineStatus(userIdLong, false);
                
                // 从所有聊天室中移除用户
                for (String chatRoomId : webSocketMessageService.getUserChatRooms(userIdLong)) {
                    webSocketMessageService.removeUserFromChatRoom(Long.parseLong(chatRoomId), userIdLong);
                }
            }
        } else {
            log.warn("WebSocket connection closed without session attributes: sessionId={}", sessionId);
        }
    }

    /**
     * WebSocket订阅事件
     */
    @EventListener
    public void handleWebSocketSubscribeListener(SessionSubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        String destination = headerAccessor.getDestination();
        
        Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();
        if (sessionAttributes != null) {
            String userId = (String) sessionAttributes.get("userId");
            
            log.info("WebSocket subscription: sessionId={}, userId={}, destination={}", 
                    sessionId, userId, destination);
            
            // 处理聊天室订阅
            if (destination != null && destination.startsWith("/topic/chat/")) {
                String chatRoomId = extractChatRoomIdFromDestination(destination);
                if (chatRoomId != null && userId != null) {
                    webSocketMessageService.addUserToChatRoom(Long.parseLong(chatRoomId), Long.parseLong(userId));
                }
            }
        }
    }

    /**
     * WebSocket取消订阅事件
     */
    @EventListener
    public void handleWebSocketUnsubscribeListener(SessionUnsubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        String subscriptionId = headerAccessor.getSubscriptionId();
        
        Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();
        if (sessionAttributes != null) {
            String userId = (String) sessionAttributes.get("userId");
            
            log.info("WebSocket unsubscription: sessionId={}, userId={}, subscriptionId={}", 
                    sessionId, userId, subscriptionId);
        }
    }

    /**
     * 从目标地址中提取聊天室ID
     */
    private String extractChatRoomIdFromDestination(String destination) {
        try {
            // destination格式: /topic/chat/{chatRoomId}
            if (destination.startsWith("/topic/chat/")) {
                return destination.substring("/topic/chat/".length());
            }
        } catch (Exception e) {
            log.error("Failed to extract chatRoomId from destination: {}", destination, e);
        }
        return null;
    }
}