package com.fliliy.secondhand.entity;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {
    
    @Id
    @Column(name = "id")
    private Long id;
    
    @Column(name = "buyer_id", nullable = false)
    private Long buyerId;
    
    @Column(name = "seller_id", nullable = false)
    private Long sellerId;
    
    @Column(name = "product_id", nullable = false)
    private Long productId;
    
    @Column(name = "chat_room_id")
    private Long chatRoomId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TransactionStatus status;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "inquiry_type", length = 20)
    private InquiryType inquiryType;
    
    @Column(name = "transaction_price", precision = 10, scale = 2)
    private BigDecimal transactionPrice;
    
    @Column(name = "transaction_code", length = 4)
    private String transactionCode;
    
    @Column(name = "code_expires_at")
    private LocalDateTime codeExpiresAt;
    
    @Column(name = "meeting_time")
    private LocalDateTime meetingTime;
    
    @Column(name = "contact_name", length = 50)
    private String contactName;
    
    @Column(name = "contact_phone", length = 20)
    private String contactPhone;
    
    @Column(name = "meeting_location_name", length = 100)
    private String meetingLocationName;
    
    @Column(name = "meeting_detail_address", length = 255)
    private String meetingDetailAddress;
    
    @Column(name = "meeting_longitude", precision = 11, scale = 8)
    private BigDecimal meetingLongitude;
    
    @Column(name = "meeting_latitude", precision = 10, scale = 8)
    private BigDecimal meetingLatitude;
    
    @Column(name = "meeting_notes", columnDefinition = "TEXT")
    private String meetingNotes;
    
    @Column(name = "cancel_reason", length = 255)
    private String cancelReason;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "cancel_type", length = 20)
    private CancelType cancelType;
    
    @Column(name = "cancelled_by")
    private Long cancelledBy;
    
    @Column(name = "feedback", columnDefinition = "TEXT")
    private String feedback;
    
    @Column(name = "rating")
    private Integer rating;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @Column(name = "completed_at")
    private LocalDateTime completedAt;
    
    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;
    
    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    public enum TransactionStatus {
        INQUIRY,      // 咨询中
        AGREED,       // 已同意线下交易
        COMPLETED,    // 交易完成
        CANCELLED     // 已取消
    }
    
    public enum InquiryType {
        PURCHASE,     // 购买咨询
        INFO          // 信息咨询
    }
    
    public enum CancelType {
        BUYER_CANCEL,   // 买家取消
        SELLER_CANCEL   // 卖家取消
    }
}