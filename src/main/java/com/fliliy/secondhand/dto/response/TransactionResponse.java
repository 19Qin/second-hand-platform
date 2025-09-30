package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TransactionResponse {
    
    private String id;
    
    private String type; // BUY or SELL
    
    private String status;
    
    private String statusText;
    
    private ProductInfo product;
    
    private UserInfo counterpart;
    
    private LocalDateTime transactionTime;
    
    private MeetingInfo meetingInfo;
    
    private Boolean canRate;
    
    private Integer rating;
    
    // 详细信息字段
    private String transactionCode; // 交易验证码（仅卖家可见）
    
    private LocalDateTime codeExpiresAt; // 验证码过期时间
    
    private LocalDateTime createdAt; // 创建时间
    
    private LocalDateTime completedAt; // 完成时间
    
    private LocalDateTime cancelledAt; // 取消时间
    
    private String cancelReason; // 取消原因
    
    private String cancelType; // 取消类型
    
    private String feedback; // 评价反馈
    
    @Data
    public static class ProductInfo {
        private String id;
        
        private String title;
        
        private BigDecimal price;
        
        private String mainImage;
        
        private String description; // 商品描述
        
        private String condition; // 商品状况
    }
    
    @Data
    public static class UserInfo {
        private String id;
        
        private String username;
        
        private String avatar;
    }
    
    @Data
    public static class MeetingInfo {
        private LocalDateTime meetingTime;
        
        private String locationName;
        
        private String detailAddress; // 详细地址
        
        private String contactName; // 联系人姓名
        
        private String contactPhone; // 联系电话（脱敏）
        
        private String notes; // 会面备注
    }
}