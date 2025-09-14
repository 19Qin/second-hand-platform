package com.fliliy.secondhand.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;

public class ChatRoomResponse {
    
    private Long chatRoomId;
    private Long transactionId;
    
    // 商品信息
    private ProductInfo product;
    
    // 聊天对象信息
    private ParticipantInfo participant;
    
    // 最后消息信息
    private LastMessageInfo lastMessage;
    
    private Integer unreadCount;
    private Integer totalMessages;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    
    private String transactionStatus;
    
    public ChatRoomResponse() {}
    
    // 内部类
    public static class ProductInfo {
        private Long id;
        private String title;
        private Double price;
        private String mainImage;
        private String status;
        
        public ProductInfo() {}
        
        public Long getId() {
            return id;
        }
        
        public void setId(Long id) {
            this.id = id;
        }
        
        public String getTitle() {
            return title;
        }
        
        public void setTitle(String title) {
            this.title = title;
        }
        
        public Double getPrice() {
            return price;
        }
        
        public void setPrice(Double price) {
            this.price = price;
        }
        
        public String getMainImage() {
            return mainImage;
        }
        
        public void setMainImage(String mainImage) {
            this.mainImage = mainImage;
        }
        
        public String getStatus() {
            return status;
        }
        
        public void setStatus(String status) {
            this.status = status;
        }
    }
    
    public static class ParticipantInfo {
        private Long id;
        private String username;
        private String avatar;
        private Boolean isOnline;
        
        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        private LocalDateTime lastSeenAt;
        
        public ParticipantInfo() {}
        
        public Long getId() {
            return id;
        }
        
        public void setId(Long id) {
            this.id = id;
        }
        
        public String getUsername() {
            return username;
        }
        
        public void setUsername(String username) {
            this.username = username;
        }
        
        public String getAvatar() {
            return avatar;
        }
        
        public void setAvatar(String avatar) {
            this.avatar = avatar;
        }
        
        public Boolean getIsOnline() {
            return isOnline;
        }
        
        public void setIsOnline(Boolean isOnline) {
            this.isOnline = isOnline;
        }
        
        public LocalDateTime getLastSeenAt() {
            return lastSeenAt;
        }
        
        public void setLastSeenAt(LocalDateTime lastSeenAt) {
            this.lastSeenAt = lastSeenAt;
        }
    }
    
    public static class LastMessageInfo {
        private Long id;
        private String content;
        private String type;
        
        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        private LocalDateTime sentAt;
        
        private String senderName;
        private Boolean isFromMe;
        
        public LastMessageInfo() {}
        
        public Long getId() {
            return id;
        }
        
        public void setId(Long id) {
            this.id = id;
        }
        
        public String getContent() {
            return content;
        }
        
        public void setContent(String content) {
            this.content = content;
        }
        
        public String getType() {
            return type;
        }
        
        public void setType(String type) {
            this.type = type;
        }
        
        public LocalDateTime getSentAt() {
            return sentAt;
        }
        
        public void setSentAt(LocalDateTime sentAt) {
            this.sentAt = sentAt;
        }
        
        public String getSenderName() {
            return senderName;
        }
        
        public void setSenderName(String senderName) {
            this.senderName = senderName;
        }
        
        public Boolean getIsFromMe() {
            return isFromMe;
        }
        
        public void setIsFromMe(Boolean isFromMe) {
            this.isFromMe = isFromMe;
        }
    }
    
    // Getter和Setter方法
    public Long getChatRoomId() {
        return chatRoomId;
    }
    
    public void setChatRoomId(Long chatRoomId) {
        this.chatRoomId = chatRoomId;
    }
    
    public Long getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(Long transactionId) {
        this.transactionId = transactionId;
    }
    
    public ProductInfo getProduct() {
        return product;
    }
    
    public void setProduct(ProductInfo product) {
        this.product = product;
    }
    
    public ParticipantInfo getParticipant() {
        return participant;
    }
    
    public void setParticipant(ParticipantInfo participant) {
        this.participant = participant;
    }
    
    public LastMessageInfo getLastMessage() {
        return lastMessage;
    }
    
    public void setLastMessage(LastMessageInfo lastMessage) {
        this.lastMessage = lastMessage;
    }
    
    public Integer getUnreadCount() {
        return unreadCount;
    }
    
    public void setUnreadCount(Integer unreadCount) {
        this.unreadCount = unreadCount;
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
    
    public String getTransactionStatus() {
        return transactionStatus;
    }
    
    public void setTransactionStatus(String transactionStatus) {
        this.transactionStatus = transactionStatus;
    }
}