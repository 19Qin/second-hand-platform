package com.fliliy.secondhand.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chat_messages")
public class ChatMessage {
    
    @Id
    private Long id;
    
    @Column(name = "chat_room_id", nullable = false)
    private Long chatRoomId;
    
    @Column(name = "sender_id", nullable = false)
    private Long senderId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", nullable = false)
    private MessageType messageType;
    
    @Column(columnDefinition = "TEXT")
    private String content;
    
    // 文件相关字段（图片/语音）
    @Column(name = "file_url")
    private String fileUrl;
    
    @Column(name = "thumbnail_url")
    private String thumbnailUrl;
    
    @Column(name = "file_size")
    private Integer fileSize;
    
    @Column(name = "duration")
    private Integer duration; // 语音时长（秒）
    
    @Column(name = "image_width")
    private Integer imageWidth;
    
    @Column(name = "image_height")
    private Integer imageHeight;
    
    // 系统消息相关
    @Enumerated(EnumType.STRING)
    @Column(name = "system_type")
    private SystemMessageType systemType;
    
    @Column(name = "system_data", columnDefinition = "JSON")
    private String systemData;
    
    // 商品相关字段
    @Column(name = "related_product_id")
    private Long relatedProductId;
    
    @Column(name = "product_snapshot", columnDefinition = "JSON")
    private String productSnapshot;
    
    // 消息状态
    @Enumerated(EnumType.STRING)
    private MessageStatus status = MessageStatus.SENT;
    
    // 撤回相关
    @Column(name = "is_recalled")
    private Boolean isRecalled = false;
    
    @Column(name = "recalled_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime recalledAt;
    
    // 时间字段
    @Column(name = "sent_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime sentAt;
    
    @Column(name = "delivered_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime deliveredAt;
    
    @Column(name = "read_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime readAt;
    
    // 关联实体
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chat_room_id", insertable = false, updatable = false)
    private ChatRoom chatRoom;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", insertable = false, updatable = false)
    private User sender;
    
    // 交易相关字段
    @Column(name = "transaction_id")
    private Long transactionId;
    
    @Column(name = "inquiry_type", length = 20)
    private String inquiryType;
    
    // 枚举定义
    public enum MessageType {
        TEXT, IMAGE, VOICE, SYSTEM, PRODUCT_CARD, TRANSACTION_REQUEST, TRANSACTION_RESPONSE
    }
    
    public enum MessageStatus {
        SENDING,     // 发送中
        SENT,        // 已发送
        DELIVERED,   // 已送达
        READ,        // 已读
        FAILED       // 发送失败
    }
    
    public enum SystemMessageType {
        TRANSACTION_AGREED,
        TRANSACTION_COMPLETED,
        TRANSACTION_CANCELLED,
        PRODUCT_SOLD,
        TRANSACTION_REQUESTED,
        TRANSACTION_REJECTED
    }
    
    // 构造函数
    public ChatMessage() {}
    
    public ChatMessage(Long chatRoomId, Long senderId, MessageType messageType, String content) {
        this.chatRoomId = chatRoomId;
        this.senderId = senderId;
        this.messageType = messageType;
        this.content = content;
        this.status = MessageStatus.SENT;
        this.sentAt = LocalDateTime.now();
    }
    
    // 静态工厂方法
    public static ChatMessage createTextMessage(Long chatRoomId, Long senderId, String content) {
        return new ChatMessage(chatRoomId, senderId, MessageType.TEXT, content);
    }
    
    public static ChatMessage createImageMessage(Long chatRoomId, Long senderId, String fileUrl, 
                                               String thumbnailUrl, Integer width, Integer height, Integer fileSize) {
        ChatMessage message = new ChatMessage(chatRoomId, senderId, MessageType.IMAGE, fileUrl);
        message.setFileUrl(fileUrl);
        message.setThumbnailUrl(thumbnailUrl);
        message.setImageWidth(width);
        message.setImageHeight(height);
        message.setFileSize(fileSize);
        return message;
    }
    
    public static ChatMessage createVoiceMessage(Long chatRoomId, Long senderId, String fileUrl, 
                                               Integer duration, Integer fileSize) {
        ChatMessage message = new ChatMessage(chatRoomId, senderId, MessageType.VOICE, fileUrl);
        message.setFileUrl(fileUrl);
        message.setDuration(duration);
        message.setFileSize(fileSize);
        return message;
    }
    
    public static ChatMessage createSystemMessage(Long chatRoomId, SystemMessageType systemType, 
                                                String content, String systemData) {
        ChatMessage message = new ChatMessage(chatRoomId, null, MessageType.SYSTEM, content);
        message.setSystemType(systemType);
        message.setSystemData(systemData);
        return message;
    }
    
    public static ChatMessage createProductCardMessage(Long chatRoomId, Long senderId, 
                                                     Long productId, String productSnapshot) {
        ChatMessage message = new ChatMessage(chatRoomId, senderId, MessageType.PRODUCT_CARD, "分享了商品");
        message.setRelatedProductId(productId);
        message.setProductSnapshot(productSnapshot);
        return message;
    }
    
    // JPA生命周期方法
    @PrePersist
    protected void onCreate() {
        if (sentAt == null) {
            sentAt = LocalDateTime.now();
        }
    }
    
    // 业务方法
    public void markAsRead() {
        this.status = MessageStatus.READ;
        this.readAt = LocalDateTime.now();
    }
    
    public void markAsDelivered() {
        if (this.status == MessageStatus.SENT) {
            this.status = MessageStatus.DELIVERED;
            this.deliveredAt = LocalDateTime.now();
        }
    }
    
    public void recall() {
        this.isRecalled = true;
        this.recalledAt = LocalDateTime.now();
        this.content = "[消息已撤回]";
    }
    
    public boolean canRecall() {
        // 只能撤回2分钟内的消息，且不是系统消息
        return !isRecalled && 
               messageType != MessageType.SYSTEM &&
               sentAt != null &&
               sentAt.isAfter(LocalDateTime.now().minusMinutes(2));
    }
    
    public boolean isFromSystem() {
        return messageType == MessageType.SYSTEM;
    }
    
    public String getDisplayContent() {
        if (isRecalled) {
            return "[消息已撤回]";
        }
        
        switch (messageType) {
            case TEXT:
                return content;
            case IMAGE:
                return "[图片]";
            case VOICE:
                return "[语音]";
            case SYSTEM:
                return content;
            case PRODUCT_CARD:
                return "[商品卡片]";
            default:
                return content;
        }
    }
    
    // Getter和Setter方法
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getChatRoomId() {
        return chatRoomId;
    }
    
    public void setChatRoomId(Long chatRoomId) {
        this.chatRoomId = chatRoomId;
    }
    
    public Long getSenderId() {
        return senderId;
    }
    
    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }
    
    public MessageType getMessageType() {
        return messageType;
    }
    
    public void setMessageType(MessageType messageType) {
        this.messageType = messageType;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public String getFileUrl() {
        return fileUrl;
    }
    
    public void setFileUrl(String fileUrl) {
        this.fileUrl = fileUrl;
    }
    
    public String getThumbnailUrl() {
        return thumbnailUrl;
    }
    
    public void setThumbnailUrl(String thumbnailUrl) {
        this.thumbnailUrl = thumbnailUrl;
    }
    
    public Integer getFileSize() {
        return fileSize;
    }
    
    public void setFileSize(Integer fileSize) {
        this.fileSize = fileSize;
    }
    
    public Integer getDuration() {
        return duration;
    }
    
    public void setDuration(Integer duration) {
        this.duration = duration;
    }
    
    public Integer getImageWidth() {
        return imageWidth;
    }
    
    public void setImageWidth(Integer imageWidth) {
        this.imageWidth = imageWidth;
    }
    
    public Integer getImageHeight() {
        return imageHeight;
    }
    
    public void setImageHeight(Integer imageHeight) {
        this.imageHeight = imageHeight;
    }
    
    public SystemMessageType getSystemType() {
        return systemType;
    }
    
    public void setSystemType(SystemMessageType systemType) {
        this.systemType = systemType;
    }
    
    public String getSystemData() {
        return systemData;
    }
    
    public void setSystemData(String systemData) {
        this.systemData = systemData;
    }
    
    public MessageStatus getStatus() {
        return status;
    }
    
    public void setStatus(MessageStatus status) {
        this.status = status;
    }
    
    public Boolean getIsRecalled() {
        return isRecalled;
    }
    
    public void setIsRecalled(Boolean isRecalled) {
        this.isRecalled = isRecalled;
    }
    
    public LocalDateTime getRecalledAt() {
        return recalledAt;
    }
    
    public void setRecalledAt(LocalDateTime recalledAt) {
        this.recalledAt = recalledAt;
    }
    
    public LocalDateTime getSentAt() {
        return sentAt;
    }
    
    public void setSentAt(LocalDateTime sentAt) {
        this.sentAt = sentAt;
    }
    
    public LocalDateTime getDeliveredAt() {
        return deliveredAt;
    }
    
    public void setDeliveredAt(LocalDateTime deliveredAt) {
        this.deliveredAt = deliveredAt;
    }
    
    public LocalDateTime getReadAt() {
        return readAt;
    }
    
    public void setReadAt(LocalDateTime readAt) {
        this.readAt = readAt;
    }
    
    public ChatRoom getChatRoom() {
        return chatRoom;
    }
    
    public void setChatRoom(ChatRoom chatRoom) {
        this.chatRoom = chatRoom;
    }
    
    public User getSender() {
        return sender;
    }
    
    public void setSender(User sender) {
        this.sender = sender;
    }
    
    public Long getRelatedProductId() {
        return relatedProductId;
    }
    
    public void setRelatedProductId(Long relatedProductId) {
        this.relatedProductId = relatedProductId;
    }
    
    public String getProductSnapshot() {
        return productSnapshot;
    }
    
    public void setProductSnapshot(String productSnapshot) {
        this.productSnapshot = productSnapshot;
    }
    
    public Long getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(Long transactionId) {
        this.transactionId = transactionId;
    }
    
    public String getInquiryType() {
        return inquiryType;
    }
    
    public void setInquiryType(String inquiryType) {
        this.inquiryType = inquiryType;
    }
}