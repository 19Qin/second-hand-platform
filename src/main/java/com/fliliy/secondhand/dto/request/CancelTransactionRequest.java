package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Data
public class CancelTransactionRequest {
    
    @NotBlank(message = "取消原因不能为空")
    @Size(max = 255, message = "取消原因不能超过255个字符")
    private String reason;
    
    @NotBlank(message = "取消类型不能为空")
    @Pattern(regexp = "^(BUYER_CANCEL|SELLER_CANCEL)$", message = "取消类型必须是BUYER_CANCEL或SELLER_CANCEL")
    private String cancelType;
}