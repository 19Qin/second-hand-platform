package com.fliliy.secondhand.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class UserProfileResponse {
    
    private Long id;
    
    private String username;
    
    private String mobile; // 脱敏显示
    
    private String email; // 脱敏显示
    
    private String avatar;
    
    private Integer gender; // 0未知, 1男, 2女
    
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate birthday;
    
    private String location;
    
    private String bio;
    
    private Boolean verified;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime registeredAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastLoginAt;
    
    private UserStatsResponse stats;
    
    private UserPreferencesResponse preferences;
    
    @Data
    public static class UserStatsResponse {
        private Long publishedCount; // 发布商品数
        private Long activeCount;    // 在售商品数
        private Long soldCount;      // 已售出数
        private Long boughtCount;    // 购买数
        private Long favoriteCount;  // 收藏数
        private Long chatCount;      // 聊天数
        private Integer points = 0;     // 积分（预留）
        private Integer credits = 100;  // 信用分（预留）
    }
    
    @Data
    public static class UserPreferencesResponse {
        private Boolean pushNotification = true;
        private Boolean emailNotification = false;
        private Boolean showMobile = false;
        private Boolean showLocation = true;
    }
}