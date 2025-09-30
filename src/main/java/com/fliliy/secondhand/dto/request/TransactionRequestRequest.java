package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotNull;

@Data
public class TransactionRequestRequest {
    
    @NotNull(message = "聊天室ID不能为空")
    private Long chatRoomId;
    
    @NotNull(message = "商品ID不能为空")
    private Long productId;
    
    private String message;
}