package com.fliliy.secondhand.entity;

import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "user_notifications")
public class UserNotification {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private Long userId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private NotificationType type;
    
    @Column(name = "title", nullable = false, length = 200)
    private String title;
    
    @Column(name = "content", columnDefinition = "TEXT")
    private String content;
    
    @Column(name = "related_id")
    private Long relatedId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "related_type")
    private RelatedType relatedType;
    
    @Column(name = "is_read")
    private Boolean isRead = false;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "push_status")
    private PushStatus pushStatus = PushStatus.PENDING;
    
    @Column(name = "push_at")
    private LocalDateTime pushAt;
    
    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    public enum NotificationType {
        SYSTEM, CHAT, TRANSACTION, PRODUCT, PROMOTION
    }
    
    public enum RelatedType {
        PRODUCT, TRANSACTION, CHAT, USER
    }
    
    public enum PushStatus {
        PENDING, SENT, FAILED
    }
}