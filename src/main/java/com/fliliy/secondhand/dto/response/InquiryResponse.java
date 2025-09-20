package com.fliliy.secondhand.dto.response;

import lombok.Data;

@Data
public class InquiryResponse {
    
    private String transactionId;
    
    private Long chatRoomId;
    
    private String status;
}