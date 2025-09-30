package com.fliliy.secondhand.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TransactionRespondResponse {
    
    private String transactionId;
    
    private String status;
    
    private String transactionCode;
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime codeExpiresAt;
    
    private String note;
    
    private String message;
}