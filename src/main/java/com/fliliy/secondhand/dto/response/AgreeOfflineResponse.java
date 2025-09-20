package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AgreeOfflineResponse {
    
    private String transactionCode;
    
    private LocalDateTime expiresAt;
    
    private MeetingInfo meetingInfo;
    
    @Data
    public static class MeetingInfo {
        private LocalDateTime meetingTime;
        
        private String locationName;
        
        private String contactName;
        
        private String contactPhone;
    }
}