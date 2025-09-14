package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    
    /**
     * 根据聊天室ID查找消息（分页，按时间倒序）
     */
    Page<ChatMessage> findByChatRoomIdOrderBySentAtDesc(Long chatRoomId, Pageable pageable);
    
    /**
     * 根据聊天室ID查找消息（按时间正序）
     */
    List<ChatMessage> findByChatRoomIdOrderBySentAtAsc(Long chatRoomId);
    
    /**
     * 查找指定时间之前的消息（用于分页加载历史记录）
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId AND cm.sentAt < :beforeTime ORDER BY cm.sentAt DESC")
    Page<ChatMessage> findByChatRoomIdAndSentAtBefore(@Param("chatRoomId") Long chatRoomId, 
                                                      @Param("beforeTime") LocalDateTime beforeTime, 
                                                      Pageable pageable);
    
    /**
     * 查找指定时间之后的消息（用于实时更新）
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId AND cm.sentAt > :afterTime ORDER BY cm.sentAt ASC")
    List<ChatMessage> findByChatRoomIdAndSentAtAfter(@Param("chatRoomId") Long chatRoomId, 
                                                     @Param("afterTime") LocalDateTime afterTime);
    
    /**
     * 获取聊天室的最后一条消息（使用分页获取第一条）
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId ORDER BY cm.sentAt DESC")
    Page<ChatMessage> findLastMessagePageByChatRoomId(@Param("chatRoomId") Long chatRoomId, Pageable pageable);
    
    /**
     * 获取聊天室的最后一条消息（便利方法）
     */
    default ChatMessage findLastMessageByChatRoomId(Long chatRoomId) {
        Page<ChatMessage> page = findLastMessagePageByChatRoomId(chatRoomId, PageRequest.of(0, 1));
        return page.hasContent() ? page.getContent().get(0) : null;
    }
    
    /**
     * 统计聊天室消息总数
     */
    Long countByChatRoomId(Long chatRoomId);
    
    /**
     * 统计聊天室未读消息数（对指定用户）
     */
    @Query("SELECT COUNT(cm) FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId AND cm.senderId != :userId AND cm.status != 'READ'")
    Long countUnreadMessages(@Param("chatRoomId") Long chatRoomId, @Param("userId") Long userId);
    
    /**
     * 标记消息为已读
     */
    @Modifying
    @Query("UPDATE ChatMessage cm SET cm.status = 'read', cm.readAt = CURRENT_TIMESTAMP WHERE cm.id = :messageId")
    void markAsRead(@Param("messageId") Long messageId);
    
    /**
     * 批量标记聊天室消息为已读
     */
    @Modifying
    @Query("UPDATE ChatMessage cm SET cm.status = 'read', cm.readAt = CURRENT_TIMESTAMP " +
           "WHERE cm.chatRoomId = :chatRoomId AND cm.senderId != :userId AND cm.status != 'read'")
    void markChatRoomMessagesAsRead(@Param("chatRoomId") Long chatRoomId, @Param("userId") Long userId);
    
    /**
     * 标记消息为已送达
     */
    @Modifying
    @Query("UPDATE ChatMessage cm SET cm.status = 'delivered', cm.deliveredAt = CURRENT_TIMESTAMP WHERE cm.id = :messageId")
    void markAsDelivered(@Param("messageId") Long messageId);
    
    /**
     * 撤回消息
     */
    @Modifying
    @Query("UPDATE ChatMessage cm SET cm.isRecalled = true, cm.recalledAt = CURRENT_TIMESTAMP, cm.content = '[消息已撤回]' WHERE cm.id = :messageId")
    void recallMessage(@Param("messageId") Long messageId);
    
    /**
     * 查找可以撤回的消息（2分钟内，非系统消息）
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.id = :messageId AND cm.senderId = :userId " +
           "AND cm.isRecalled = false AND cm.messageType != 'SYSTEM' " +
           "AND cm.sentAt > :timeLimit")
    ChatMessage findRecallableMessage(@Param("messageId") Long messageId, 
                                    @Param("userId") Long userId, 
                                    @Param("timeLimit") LocalDateTime timeLimit);
    
    /**
     * 根据发送者查找消息
     */
    List<ChatMessage> findBySenderIdOrderBySentAtDesc(Long senderId);
    
    /**
     * 查找系统消息
     */
    List<ChatMessage> findByChatRoomIdAndMessageTypeOrderBySentAtDesc(Long chatRoomId, ChatMessage.MessageType messageType);
    
    /**
     * 查找文件消息（图片、语音）
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId " +
           "AND cm.messageType IN ('IMAGE', 'VOICE') AND cm.isRecalled = false " +
           "ORDER BY cm.sentAt DESC")
    List<ChatMessage> findFileMessages(@Param("chatRoomId") Long chatRoomId);
    
    /**
     * 查找图片消息
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId " +
           "AND cm.messageType = 'IMAGE' AND cm.isRecalled = false " +
           "ORDER BY cm.sentAt DESC")
    List<ChatMessage> findImageMessages(@Param("chatRoomId") Long chatRoomId);
    
    /**
     * 搜索聊天记录
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId " +
           "AND cm.messageType = 'TEXT' AND cm.isRecalled = false " +
           "AND LOWER(cm.content) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "ORDER BY cm.sentAt DESC")
    List<ChatMessage> searchMessages(@Param("chatRoomId") Long chatRoomId, @Param("keyword") String keyword);
    
    /**
     * 删除聊天室的所有消息（物理删除）
     */
    @Modifying
    @Query("DELETE FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId")
    void deleteAllByChatRoomId(@Param("chatRoomId") Long chatRoomId);
    
    /**
     * 获取用户发送的消息数量
     */
    Long countBySenderId(Long senderId);
    
    /**
     * 获取指定时间范围内的消息
     */
    @Query("SELECT cm FROM ChatMessage cm WHERE cm.chatRoomId = :chatRoomId " +
           "AND cm.sentAt BETWEEN :startTime AND :endTime " +
           "ORDER BY cm.sentAt ASC")
    List<ChatMessage> findByTimeRange(@Param("chatRoomId") Long chatRoomId, 
                                     @Param("startTime") LocalDateTime startTime, 
                                     @Param("endTime") LocalDateTime endTime);
    
    /**
     * 查找失败的消息
     */
    List<ChatMessage> findByStatusAndSenderIdOrderBySentAtDesc(ChatMessage.MessageStatus status, Long senderId);
}