package com.fliliy.secondhand.dto.response;

import lombok.Data;

@Data
public class SmsResponse {
    
    private String smsId;
    private Integer expireTime; // 有效期（秒）
}