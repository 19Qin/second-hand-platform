package com.fliliy.secondhand.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_rooms", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"buyer_id", "seller_id"}))
public class ChatRoom {
    
    @Id
    private Long id;
    
    @Column(name = "transaction_id")
    private Long transactionId;
    
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;
    
    @Column(name = "seller_id", nullable = false)
    private Long sellerId;
    
    @Enumerated(EnumType.STRING)
    private ChatRoomStatus status = ChatRoomStatus.ACTIVE;
    
    @Column(name = "last_message_id")
    private Long lastMessageId;
    
    @Column(name = "last_message_content", columnDefinition = "TEXT")
    private String lastMessageContent;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "last_message_type")
    private MessageType lastMessageType;
    
    @Column(name = "last_message_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastMessageTime;
    
    @Column(name = "last_message_sender_id")
    private Long lastMessageSenderId;
    
    @Column(name = "buyer_unread_count")
    private Integer buyerUnreadCount = 0;
    
    @Column(name = "seller_unread_count")
    private Integer sellerUnreadCount = 0;
    
    @Column(name = "total_messages")
    private Integer totalMessages = 0;
    
    // 高级功能字段
    @Column(name = "buyer_pinned")
    private Boolean buyerPinned = false;
    
    @Column(name = "seller_pinned")
    private Boolean sellerPinned = false;
    
    @Column(name = "buyer_muted")
    private Boolean buyerMuted = false;
    
    @Column(name = "seller_muted")
    private Boolean sellerMuted = false;
    
    @Column(name = "created_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    
    // 关联实体
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id", insertable = false, updatable = false)
    private User buyer;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", insertable = false, updatable = false)
    private User seller;
    
    // 枚举定义
    public enum ChatRoomStatus {
        ACTIVE, CLOSED, BLOCKED
    }
    
    public enum MessageType {
        TEXT, IMAGE, VOICE, SYSTEM, PRODUCT_CARD
    }
    
    // 构造函数
    public ChatRoom() {}
    
    public ChatRoom(Long buyerId, Long sellerId) {
        this.buyerId = buyerId;
        this.sellerId = sellerId;
        this.status = ChatRoomStatus.ACTIVE;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
    
    // JPA生命周期方法
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // 业务方法
    public void updateLastMessage(Long messageId, String content, MessageType type, Long senderId) {
        this.lastMessageId = messageId;
        this.lastMessageContent = content;
        this.lastMessageType = type;
        this.lastMessageTime = LocalDateTime.now();
        this.lastMessageSenderId = senderId;
        this.totalMessages++;
        
        // 更新未读计数
        if (senderId.equals(buyerId)) {
            this.sellerUnreadCount++;
        } else {
            this.buyerUnreadCount++;
        }
    }
    
    public void markAsRead(Long userId) {
        if (userId.equals(buyerId)) {
            this.buyerUnreadCount = 0;
        } else if (userId.equals(sellerId)) {
            this.sellerUnreadCount = 0;
        }
    }
    
    public boolean isParticipant(Long userId) {
        return userId.equals(buyerId) || userId.equals(sellerId);
    }
    
    public Long getOtherParticipant(Long currentUserId) {
        if (currentUserId.equals(buyerId)) {
            return sellerId;
        } else if (currentUserId.equals(sellerId)) {
            return buyerId;
        }
        return null;
    }
    
    public Integer getUnreadCount(Long userId) {
        if (userId.equals(buyerId)) {
            return buyerUnreadCount;
        } else if (userId.equals(sellerId)) {
            return sellerUnreadCount;
        }
        return 0;
    }
    
    public boolean isPinned(Long userId) {
        if (userId.equals(buyerId)) {
            return buyerPinned != null && buyerPinned;
        } else if (userId.equals(sellerId)) {
            return sellerPinned != null && sellerPinned;
        }
        return false;
    }
    
    public boolean isMuted(Long userId) {
        if (userId.equals(buyerId)) {
            return buyerMuted != null && buyerMuted;
        } else if (userId.equals(sellerId)) {
            return sellerMuted != null && sellerMuted;
        }
        return false;
    }
    
    public void setPinned(Long userId, boolean pinned) {
        if (userId.equals(buyerId)) {
            this.buyerPinned = pinned;
        } else if (userId.equals(sellerId)) {
            this.sellerPinned = pinned;
        }
    }
    
    public void setMuted(Long userId, boolean muted) {
        if (userId.equals(buyerId)) {
            this.buyerMuted = muted;
        } else if (userId.equals(sellerId)) {
            this.sellerMuted = muted;
        }
    }
    
    // Getter和Setter方法
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(Long transactionId) {
        this.transactionId = transactionId;
    }
    
    
    public Long getBuyerId() {
        return buyerId;
    }
    
    public void setBuyerId(Long buyerId) {
        this.buyerId = buyerId;
    }
    
    public Long getSellerId() {
        return sellerId;
    }
    
    public void setSellerId(Long sellerId) {
        this.sellerId = sellerId;
    }
    
    public ChatRoomStatus getStatus() {
        return status;
    }
    
    public void setStatus(ChatRoomStatus status) {
        this.status = status;
    }
    
    public Long getLastMessageId() {
        return lastMessageId;
    }
    
    public void setLastMessageId(Long lastMessageId) {
        this.lastMessageId = lastMessageId;
    }
    
    public String getLastMessageContent() {
        return lastMessageContent;
    }
    
    public void setLastMessageContent(String lastMessageContent) {
        this.lastMessageContent = lastMessageContent;
    }
    
    public MessageType getLastMessageType() {
        return lastMessageType;
    }
    
    public void setLastMessageType(MessageType lastMessageType) {
        this.lastMessageType = lastMessageType;
    }
    
    public LocalDateTime getLastMessageTime() {
        return lastMessageTime;
    }
    
    public void setLastMessageTime(LocalDateTime lastMessageTime) {
        this.lastMessageTime = lastMessageTime;
    }
    
    public Long getLastMessageSenderId() {
        return lastMessageSenderId;
    }
    
    public void setLastMessageSenderId(Long lastMessageSenderId) {
        this.lastMessageSenderId = lastMessageSenderId;
    }
    
    public Integer getBuyerUnreadCount() {
        return buyerUnreadCount;
    }
    
    public void setBuyerUnreadCount(Integer buyerUnreadCount) {
        this.buyerUnreadCount = buyerUnreadCount;
    }
    
    public Integer getSellerUnreadCount() {
        return sellerUnreadCount;
    }
    
    public void setSellerUnreadCount(Integer sellerUnreadCount) {
        this.sellerUnreadCount = sellerUnreadCount;
    }
    
    public Integer getTotalMessages() {
        return totalMessages;
    }
    
    public void setTotalMessages(Integer totalMessages) {
        this.totalMessages = totalMessages;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    
    public User getBuyer() {
        return buyer;
    }
    
    public void setBuyer(User buyer) {
        this.buyer = buyer;
    }
    
    public User getSeller() {
        return seller;
    }
    
    public void setSeller(User seller) {
        this.seller = seller;
    }
}