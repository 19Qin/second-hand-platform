package com.fliliy.secondhand.repository;

import com.fliliy.secondhand.entity.UserNotification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserNotificationRepository extends JpaRepository<UserNotification, Long> {
    
    @Query("SELECT un FROM UserNotification un WHERE un.userId = :userId " +
           "AND (:type IS NULL OR un.type = :type) " +
           "AND (:isRead IS NULL OR un.isRead = :isRead) " +
           "ORDER BY un.createdAt DESC")
    Page<UserNotification> findByUserIdAndTypeAndIsRead(
            @Param("userId") Long userId,
            @Param("type") UserNotification.NotificationType type,
            @Param("isRead") Boolean isRead,
            Pageable pageable
    );
    
    @Query("SELECT COUNT(un) FROM UserNotification un WHERE un.userId = :userId AND un.isRead = false")
    Long countUnreadByUserId(@Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE UserNotification un SET un.isRead = true, un.readAt = CURRENT_TIMESTAMP WHERE un.id = :notificationId AND un.userId = :userId")
    void markAsRead(@Param("notificationId") Long notificationId, @Param("userId") Long userId);
    
    @Modifying
    @Query("UPDATE UserNotification un SET un.isRead = true, un.readAt = CURRENT_TIMESTAMP WHERE un.userId = :userId AND un.isRead = false")
    void markAllAsRead(@Param("userId") Long userId);
}