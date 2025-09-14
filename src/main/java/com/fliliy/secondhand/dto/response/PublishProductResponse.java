package com.fliliy.secondhand.dto.response;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class PublishProductResponse {
    
    private String productId;
    private String status;
    private LocalDateTime publishTime;
}