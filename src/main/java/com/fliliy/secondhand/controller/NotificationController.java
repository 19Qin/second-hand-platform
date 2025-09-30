package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.response.NotificationResponse;
import com.fliliy.secondhand.dto.response.PagedResponse;
import com.fliliy.secondhand.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/user/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {
    
    private final NotificationService notificationService;
    
    /**
     * 获取用户通知列表
     */
    @GetMapping
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<PagedResponse<NotificationResponse>> getUserNotifications(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(defaultValue = "all") String type,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            PagedResponse<NotificationResponse> notifications = notificationService
                    .getUserNotifications(userId, type, status, page, size);
            return ApiResponse.success("获取成功", notifications);
        } catch (Exception e) {
            log.error("Get user notifications failed", e);
            return ApiResponse.error("获取通知失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取未读通知数量
     */
    @GetMapping("/unread-count")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Map<String, Long>> getUnreadCount(@AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            Long unreadCount = notificationService.getUnreadCount(userId);
            Map<String, Long> response = new HashMap<>();
            response.put("unreadCount", unreadCount);
            return ApiResponse.success("获取成功", response);
        } catch (Exception e) {
            log.error("Get unread count failed", e);
            return ApiResponse.error("获取未读数量失败: " + e.getMessage());
        }
    }
    
    /**
     * 标记通知为已读
     */
    @PostMapping("/{notificationId}/read")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Object> markAsRead(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long notificationId) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            notificationService.markAsRead(userId, notificationId);
            return ApiResponse.success("标记成功");
        } catch (Exception e) {
            log.error("Mark notification as read failed", e);
            return ApiResponse.error("标记失败: " + e.getMessage());
        }
    }
    
    /**
     * 标记所有通知为已读
     */
    @PostMapping("/read-all")
    @PreAuthorize("hasRole('USER')")
    public ApiResponse<Object> markAllAsRead(@AuthenticationPrincipal UserDetails userDetails) {
        try {
            Long userId = Long.valueOf(userDetails.getUsername());
            notificationService.markAllAsRead(userId);
            return ApiResponse.success("全部标记成功");
        } catch (Exception e) {
            log.error("Mark all notifications as read failed", e);
            return ApiResponse.error("全部标记失败: " + e.getMessage());
        }
    }
}