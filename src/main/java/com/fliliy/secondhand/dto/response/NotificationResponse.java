package com.fliliy.secondhand.dto.response;

import com.fliliy.secondhand.entity.UserNotification;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class NotificationResponse {
    
    private Long id;
    private UserNotification.NotificationType type;
    private String title;
    private String content;
    private Long relatedId;
    private UserNotification.RelatedType relatedType;
    private Boolean isRead;
    private LocalDateTime readAt;
    private LocalDateTime createdAt;
}