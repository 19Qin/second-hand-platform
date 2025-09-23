package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.ChatRoom;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    
    /**
     * 根据买家和卖家查找聊天室
     */
    Optional<ChatRoom> findByBuyerIdAndSellerId(Long buyerId, Long sellerId);
    
    /**
     * 查找两个用户之间的聊天室（不区分买家卖家角色）
     */
    @Query("SELECT cr FROM ChatRoom cr WHERE " +
           "(cr.buyerId = :userId1 AND cr.sellerId = :userId2) OR " +
           "(cr.buyerId = :userId2 AND cr.sellerId = :userId1)")
    Optional<ChatRoom> findBetweenUsers(@Param("userId1") Long userId1, @Param("userId2") Long userId2);
    
    /**
     * 查找用户的所有聊天室（作为买家或卖家）
     */
    @Query(value = "SELECT * FROM chat_rooms WHERE buyer_id = :userId OR seller_id = :userId ORDER BY updated_at DESC", nativeQuery = true)
    Page<ChatRoom> findByParticipant(@Param("userId") Long userId, Pageable pageable);
    
    /**
     * 查找用户的所有聊天室列表（不分页）
     */
    @Query(value = "SELECT * FROM chat_rooms WHERE buyer_id = :userId OR seller_id = :userId ORDER BY updated_at DESC", nativeQuery = true)
    List<ChatRoom> findByParticipant(@Param("userId") Long userId);
    
    /**
     * 查找用户作为买家的聊天室
     */
    List<ChatRoom> findByBuyerIdOrderByUpdatedAtDesc(Long buyerId);
    
    /**
     * 查找用户作为卖家的聊天室
     */
    List<ChatRoom> findBySellerIdOrderByUpdatedAtDesc(Long sellerId);
    
    
    /**
     * 查找活跃的聊天室
     */
    @Query(value = "SELECT * FROM chat_rooms WHERE (buyer_id = :userId OR seller_id = :userId) AND status = 'ACTIVE' ORDER BY updated_at DESC", nativeQuery = true)
    List<ChatRoom> findActiveByParticipant(@Param("userId") Long userId);
    
    /**
     * 获取用户的总未读消息数
     */
    @Query(value = "SELECT COALESCE(SUM(CASE WHEN buyer_id = :userId THEN buyer_unread_count ELSE seller_unread_count END), 0) FROM chat_rooms WHERE buyer_id = :userId OR seller_id = :userId", nativeQuery = true)
    Long getTotalUnreadCount(@Param("userId") Long userId);
    
    /**
     * 标记聊天室为已读
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.buyerUnreadCount = 0 WHERE cr.id = :chatRoomId AND cr.buyerId = :userId")
    void markAsReadForBuyer(@Param("chatRoomId") Long chatRoomId, @Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.sellerUnreadCount = 0 WHERE cr.id = :chatRoomId AND cr.sellerId = :userId")
    void markAsReadForSeller(@Param("chatRoomId") Long chatRoomId, @Param("userId") Long userId);
    
    /**
     * 更新聊天室最后消息基本信息
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET " +
           "cr.lastMessageId = :messageId, " +
           "cr.lastMessageContent = :content, " +
           "cr.lastMessageType = :messageType, " +
           "cr.lastMessageTime = CURRENT_TIMESTAMP, " +
           "cr.lastMessageSenderId = :senderId, " +
           "cr.updatedAt = CURRENT_TIMESTAMP " +
           "WHERE cr.id = :chatRoomId")
    void updateLastMessage(@Param("chatRoomId") Long chatRoomId,
                          @Param("messageId") Long messageId,
                          @Param("content") String content,
                          @Param("messageType") ChatRoom.MessageType messageType,
                          @Param("senderId") Long senderId);
    
    /**
     * 增加消息总数
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.totalMessages = cr.totalMessages + 1 WHERE cr.id = :chatRoomId")
    void incrementTotalMessages(@Param("chatRoomId") Long chatRoomId);
    
    /**
     * 增加买家未读数（当发送者不是买家时）
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.buyerUnreadCount = cr.buyerUnreadCount + 1 WHERE cr.id = :chatRoomId AND cr.buyerId != :senderId")
    void incrementBuyerUnreadCount(@Param("chatRoomId") Long chatRoomId, @Param("senderId") Long senderId);
    
    /**
     * 增加卖家未读数（当发送者不是卖家时）
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.sellerUnreadCount = cr.sellerUnreadCount + 1 WHERE cr.id = :chatRoomId AND cr.sellerId != :senderId")
    void incrementSellerUnreadCount(@Param("chatRoomId") Long chatRoomId, @Param("senderId") Long senderId);
    
    /**
     * 检查用户是否是聊天室参与者
     */
    @Query(value = "SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM chat_rooms WHERE id = :chatRoomId AND (buyer_id = :userId OR seller_id = :userId)", nativeQuery = true)
    Integer isParticipantCount(@Param("chatRoomId") Long chatRoomId, @Param("userId") Long userId);
    
    /**
     * 检查用户是否是聊天室参与者 - 便利方法
     */
    default boolean isParticipant(Long chatRoomId, Long userId) {
        Integer count = isParticipantCount(chatRoomId, userId);
        return count != null && count > 0;
    }
    
    /**
     * 根据交易ID查找聊天室
     */
    Optional<ChatRoom> findByTransactionId(Long transactionId);
    
    /**
     * 关闭聊天室
     */
    @Modifying
    @Query("UPDATE ChatRoom cr SET cr.status = 'CLOSED' WHERE cr.id = :chatRoomId")
    void closeChatRoom(@Param("chatRoomId") Long chatRoomId);
}