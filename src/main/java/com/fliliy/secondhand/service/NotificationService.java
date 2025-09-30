package com.fliliy.secondhand.service;

import com.fliliy.secondhand.dto.response.NotificationResponse;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.entity.UserNotification;
import com.fliliy.secondhand.repository.UserNotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    
    private final UserNotificationRepository notificationRepository;
    
    /**
     * 获取用户通知列表
     */
    public PagedResponse<NotificationResponse> getUserNotifications(
            Long userId, 
            String type, 
            String status, 
            int page, 
            int size) {
        
        UserNotification.NotificationType notificationType = null;
        if (type != null && !type.equals("all")) {
            try {
                notificationType = UserNotification.NotificationType.valueOf(type.toUpperCase());
            } catch (IllegalArgumentException e) {
                log.warn("Invalid notification type: {}", type);
            }
        }
        
        Boolean isRead = null;
        if (status != null && !status.equals("all")) {
            isRead = status.equals("read");
        }
        
        Pageable pageable = PageRequest.of(page - 1, size);
        Page<UserNotification> notificationPage = notificationRepository
                .findByUserIdAndTypeAndIsRead(userId, notificationType, isRead, pageable);
        
        List<NotificationResponse> notifications = notificationPage.getContent()
                .stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
        
        return new PagedResponse<>(
                notifications,
                page,
                size,
                notificationPage.getTotalElements(),
                notificationPage.getTotalPages(),
                notificationPage.hasNext()
        );
    }
    
    /**
     * 获取未读通知数量
     */
    public Long getUnreadCount(Long userId) {
        return notificationRepository.countUnreadByUserId(userId);
    }
    
    /**
     * 标记通知为已读
     */
    @Transactional
    public void markAsRead(Long userId, Long notificationId) {
        notificationRepository.markAsRead(notificationId, userId);
    }
    
    /**
     * 标记所有通知为已读
     */
    @Transactional
    public void markAllAsRead(Long userId) {
        notificationRepository.markAllAsRead(userId);
    }
    
    /**
     * 创建系统通知
     */
    @Transactional
    public void createSystemNotification(Long userId, String title, String content) {
        UserNotification notification = new UserNotification();
        notification.setUserId(userId);
        notification.setType(UserNotification.NotificationType.SYSTEM);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setIsRead(false);
        notification.setPushStatus(UserNotification.PushStatus.PENDING);
        
        notificationRepository.save(notification);
    }
    
    /**
     * 创建聊天通知
     */
    @Transactional
    public void createChatNotification(Long userId, String title, String content, Long chatRoomId) {
        UserNotification notification = new UserNotification();
        notification.setUserId(userId);
        notification.setType(UserNotification.NotificationType.CHAT);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setRelatedId(chatRoomId);
        notification.setRelatedType(UserNotification.RelatedType.CHAT);
        notification.setIsRead(false);
        notification.setPushStatus(UserNotification.PushStatus.PENDING);
        
        notificationRepository.save(notification);
    }
    
    /**
     * 创建交易通知
     */
    @Transactional
    public void createTransactionNotification(Long userId, String title, String content, Long transactionId) {
        UserNotification notification = new UserNotification();
        notification.setUserId(userId);
        notification.setType(UserNotification.NotificationType.TRANSACTION);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setRelatedId(transactionId);
        notification.setRelatedType(UserNotification.RelatedType.TRANSACTION);
        notification.setIsRead(false);
        notification.setPushStatus(UserNotification.PushStatus.PENDING);
        
        notificationRepository.save(notification);
    }
    
    /**
     * 创建商品通知
     */
    @Transactional
    public void createProductNotification(Long userId, String title, String content, Long productId) {
        UserNotification notification = new UserNotification();
        notification.setUserId(userId);
        notification.setType(UserNotification.NotificationType.PRODUCT);
        notification.setTitle(title);
        notification.setContent(content);
        notification.setRelatedId(productId);
        notification.setRelatedType(UserNotification.RelatedType.PRODUCT);
        notification.setIsRead(false);
        notification.setPushStatus(UserNotification.PushStatus.PENDING);
        
        notificationRepository.save(notification);
    }
    
    private NotificationResponse convertToResponse(UserNotification notification) {
        NotificationResponse response = new NotificationResponse();
        response.setId(notification.getId());
        response.setType(notification.getType());
        response.setTitle(notification.getTitle());
        response.setContent(notification.getContent());
        response.setRelatedId(notification.getRelatedId());
        response.setRelatedType(notification.getRelatedType());
        response.setIsRead(notification.getIsRead());
        response.setReadAt(notification.getReadAt());
        response.setCreatedAt(notification.getCreatedAt());
        return response;
    }
}