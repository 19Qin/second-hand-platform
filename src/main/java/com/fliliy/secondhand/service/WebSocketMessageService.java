package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.response.ChatMessageResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class WebSocketMessageService {

    private final SimpMessagingTemplate messagingTemplate;
    private final RedisTemplate<String, Object> redisTemplate;
    
    // Redis键前缀
    private static final String ONLINE_USERS_KEY = "websocket:online_users";
    private static final String CHATROOM_USERS_KEY = "websocket:chatroom:users:";
    private static final String USER_STATUS_KEY = "websocket:user:status:";

    /**
     * 向指定聊天室广播消息
     */
    public void broadcastMessageToChatRoom(Long chatRoomId, ChatMessageResponse message) {
        String destination = "/topic/chat/" + chatRoomId;
        
        try {
            messagingTemplate.convertAndSend(destination, message);
            log.info("Broadcasted message to chatRoom {}: messageId={}", chatRoomId, message.getId());
            
        } catch (Exception e) {
            log.error("Failed to broadcast message to chatRoom {}: {}", chatRoomId, e.getMessage(), e);
        }
    }

    /**
     * 向特定用户发送私人消息
     */
    public void sendMessageToUser(Long userId, Object message) {
        String destination = "/user/" + userId + "/queue/messages";
        
        try {
            messagingTemplate.convertAndSend(destination, message);
            log.info("Sent private message to user {}", userId);
            
        } catch (Exception e) {
            log.error("Failed to send private message to user {}: {}", userId, e.getMessage(), e);
        }
    }

    /**
     * 向用户发送错误消息
     */
    public void sendErrorToUser(Long userId, String errorMessage) {
        Map<String, Object> errorResponse = new HashMap<>();
        errorResponse.put("type", "error");
        errorResponse.put("message", errorMessage);
        errorResponse.put("timestamp", LocalDateTime.now());
        
        sendMessageToUser(userId, errorResponse);
    }

    /**
     * 向用户发送通知消息
     */
    public void sendNotificationToUser(Long userId, String title, String content, String type) {
        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "notification");
        notification.put("title", title);
        notification.put("content", content);
        notification.put("notificationType", type);
        notification.put("timestamp", LocalDateTime.now());
        
        sendMessageToUser(userId, notification);
    }

    /**
     * 广播已读状态更新到聊天室
     */
    public void broadcastReadStatusToChatRoom(Long chatRoomId, Long userId, Long lastReadMessageId) {
        Map<String, Object> readStatus = new HashMap<>();
        readStatus.put("type", "read_status");
        readStatus.put("userId", userId);
        readStatus.put("lastReadMessageId", lastReadMessageId);
        readStatus.put("timestamp", LocalDateTime.now());
        
        String destination = "/topic/chat/" + chatRoomId;
        
        try {
            messagingTemplate.convertAndSend(destination, readStatus);
            log.info("Broadcasted read status to chatRoom {}: user={}, messageId={}", 
                    chatRoomId, userId, lastReadMessageId);
            
        } catch (Exception e) {
            log.error("Failed to broadcast read status to chatRoom {}: {}", chatRoomId, e.getMessage(), e);
        }
    }

    /**
     * 广播用户在线状态变更
     */
    public void broadcastUserStatusChange(Long userId, boolean isOnline) {
        Map<String, Object> statusChange = new HashMap<>();
        statusChange.put("type", "user_status");
        statusChange.put("userId", userId);
        statusChange.put("isOnline", isOnline);
        statusChange.put("timestamp", LocalDateTime.now());
        
        // 获取该用户所在的所有聊天室
        Set<String> chatRooms = getUserChatRooms(userId);
        
        for (String chatRoomId : chatRooms) {
            String destination = "/topic/chat/" + chatRoomId;
            try {
                messagingTemplate.convertAndSend(destination, statusChange);
            } catch (Exception e) {
                log.error("Failed to broadcast status change to chatRoom {}: {}", chatRoomId, e.getMessage());
            }
        }
        
        log.info("Broadcasted status change for user {}: isOnline={}, chatRooms={}", 
                userId, isOnline, chatRooms.size());
    }

    /**
     * 添加用户到聊天室（Redis记录）
     */
    public void addUserToChatRoom(Long chatRoomId, Long userId) {
        String key = CHATROOM_USERS_KEY + chatRoomId;
        try {
            redisTemplate.opsForSet().add(key, userId.toString());
            redisTemplate.expire(key, 24, TimeUnit.HOURS); // 24小时过期
            
            // 同时记录用户所在的聊天室
            String userChatRoomsKey = "websocket:user:chatrooms:" + userId;
            redisTemplate.opsForSet().add(userChatRoomsKey, chatRoomId.toString());
            redisTemplate.expire(userChatRoomsKey, 24, TimeUnit.HOURS);
            
            log.debug("Added user {} to chatRoom {}", userId, chatRoomId);
            
        } catch (Exception e) {
            log.error("Failed to add user {} to chatRoom {}: {}", userId, chatRoomId, e.getMessage());
        }
    }

    /**
     * 从聊天室移除用户
     */
    public void removeUserFromChatRoom(Long chatRoomId, Long userId) {
        String key = CHATROOM_USERS_KEY + chatRoomId;
        try {
            redisTemplate.opsForSet().remove(key, userId.toString());
            
            // 同时从用户聊天室列表中移除
            String userChatRoomsKey = "websocket:user:chatrooms:" + userId;
            redisTemplate.opsForSet().remove(userChatRoomsKey, chatRoomId.toString());
            
            log.debug("Removed user {} from chatRoom {}", userId, chatRoomId);
            
        } catch (Exception e) {
            log.error("Failed to remove user {} from chatRoom {}: {}", userId, chatRoomId, e.getMessage());
        }
    }

    /**
     * 获取聊天室中的在线用户列表
     */
    @SuppressWarnings("unchecked")
    public Set<String> getChatRoomUsers(Long chatRoomId) {
        String key = CHATROOM_USERS_KEY + chatRoomId;
        try {
            return (Set<String>) redisTemplate.opsForSet().members(key);
        } catch (Exception e) {
            log.error("Failed to get users in chatRoom {}: {}", chatRoomId, e.getMessage());
            return Set.of();
        }
    }

    /**
     * 获取用户所在的聊天室列表
     */
    @SuppressWarnings("unchecked")
    public Set<String> getUserChatRooms(Long userId) {
        String key = "websocket:user:chatrooms:" + userId;
        try {
            return (Set<String>) redisTemplate.opsForSet().members(key);
        } catch (Exception e) {
            log.error("Failed to get chatRooms for user {}: {}", userId, e.getMessage());
            return Set.of();
        }
    }

    /**
     * 更新用户在线状态
     */
    public void updateUserOnlineStatus(Long userId, boolean isOnline) {
        String key = USER_STATUS_KEY + userId;
        try {
            if (isOnline) {
                redisTemplate.opsForValue().set(key, "online", 30, TimeUnit.MINUTES);
                redisTemplate.opsForSet().add(ONLINE_USERS_KEY, userId.toString());
            } else {
                redisTemplate.delete(key);
                redisTemplate.opsForSet().remove(ONLINE_USERS_KEY, userId.toString());
            }
            
            // 广播状态变更
            broadcastUserStatusChange(userId, isOnline);
            
            log.info("Updated user {} online status: {}", userId, isOnline);
            
        } catch (Exception e) {
            log.error("Failed to update user {} online status: {}", userId, e.getMessage());
        }
    }

    /**
     * 检查用户是否在线
     */
    public boolean isUserOnline(Long userId) {
        String key = USER_STATUS_KEY + userId;
        try {
            return redisTemplate.hasKey(key);
        } catch (Exception e) {
            log.error("Failed to check online status for user {}: {}", userId, e.getMessage());
            return false;
        }
    }

    /**
     * 获取所有在线用户
     */
    @SuppressWarnings("unchecked")
    public Set<String> getOnlineUsers() {
        try {
            return (Set<String>) redisTemplate.opsForSet().members(ONLINE_USERS_KEY);
        } catch (Exception e) {
            log.error("Failed to get online users: {}", e.getMessage());
            return Set.of();
        }
    }

    /**
     * 获取聊天室在线用户数量
     */
    public long getChatRoomOnlineUserCount(Long chatRoomId) {
        String key = CHATROOM_USERS_KEY + chatRoomId;
        try {
            Long count = redisTemplate.opsForSet().size(key);
            return count != null ? count : 0L;
        } catch (Exception e) {
            log.error("Failed to get online user count for chatRoom {}: {}", chatRoomId, e.getMessage());
            return 0L;
        }
    }

    /**
     * 清理过期的连接信息
     */
    public void cleanupExpiredConnections() {
        try {
            // 清理过期的用户在线状态
            Set<String> onlineUsers = getOnlineUsers();
            for (String userId : onlineUsers) {
                if (!isUserOnline(Long.parseLong(userId))) {
                    redisTemplate.opsForSet().remove(ONLINE_USERS_KEY, userId);
                }
            }
            
            log.info("Cleaned up expired WebSocket connections");
            
        } catch (Exception e) {
            log.error("Failed to cleanup expired connections: {}", e.getMessage());
        }
    }
}