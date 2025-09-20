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
    
    @Data
    public static class ProductInfo {
        private String id;
        
        private String title;
        
        private BigDecimal price;
        
        private String mainImage;
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
    }
}