package com.fliliy.secondhand.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;
import java.util.List;

public class ChatRoomResponse {

    private Long chatRoomId;

    @Deprecated // 保留用于向后兼容，推荐使用 activeTransactions
    private Long transactionId;

    // 进行中的交易列表（PENDING或AGREED状态）
    private List<ActiveTransactionInfo> activeTransactions;

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

    @Deprecated // 保留用于向后兼容，推荐使用 activeTransactions
    private String transactionStatus;

    public ChatRoomResponse() {}

    // 进行中的交易信息
    public static class ActiveTransactionInfo {
        private String transactionId;  // 格式：tx_{id}
        private Long productId;
        private String productTitle;
        private String productImage;
        private Double productPrice;
        private String status;  // PENDING 或 AGREED
        private String role;  // BUYER 或 SELLER
        private String transactionCode;  // 只有AGREED状态且是买家时才返回

        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        private LocalDateTime codeExpiresAt;  // 交易码过期时间

        @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
        private LocalDateTime requestedAt;  // 交易发起时间

        public ActiveTransactionInfo() {}

        public String getTransactionId() {
            return transactionId;
        }

        public void setTransactionId(String transactionId) {
            this.transactionId = transactionId;
        }

        public Long getProductId() {
            return productId;
        }

        public void setProductId(Long productId) {
            this.productId = productId;
        }

        public String getProductTitle() {
            return productTitle;
        }

        public void setProductTitle(String productTitle) {
            this.productTitle = productTitle;
        }

        public String getProductImage() {
            return productImage;
        }

        public void setProductImage(String productImage) {
            this.productImage = productImage;
        }

        public Double getProductPrice() {
            return productPrice;
        }

        public void setProductPrice(Double productPrice) {
            this.productPrice = productPrice;
        }

        public String getStatus() {
            return status;
        }

        public void setStatus(String status) {
            this.status = status;
        }

        public String getRole() {
            return role;
        }

        public void setRole(String role) {
            this.role = role;
        }

        public String getTransactionCode() {
            return transactionCode;
        }

        public void setTransactionCode(String transactionCode) {
            this.transactionCode = transactionCode;
        }

        public LocalDateTime getCodeExpiresAt() {
            return codeExpiresAt;
        }

        public void setCodeExpiresAt(LocalDateTime codeExpiresAt) {
            this.codeExpiresAt = codeExpiresAt;
        }

        public LocalDateTime getRequestedAt() {
            return requestedAt;
        }

        public void setRequestedAt(LocalDateTime requestedAt) {
            this.requestedAt = requestedAt;
        }
    }
    
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

    @Deprecated
    public Long getTransactionId() {
        return transactionId;
    }

    @Deprecated
    public void setTransactionId(Long transactionId) {
        this.transactionId = transactionId;
    }

    public List<ActiveTransactionInfo> getActiveTransactions() {
        return activeTransactions;
    }

    public void setActiveTransactions(List<ActiveTransactionInfo> activeTransactions) {
        this.activeTransactions = activeTransactions;
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