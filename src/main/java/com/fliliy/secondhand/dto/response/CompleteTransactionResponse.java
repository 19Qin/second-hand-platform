package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CompleteTransactionResponse {
    
    private String transactionId;
    
    private String status;
    
    private LocalDateTime completedAt;
    
    private String productStatus;
}