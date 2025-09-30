package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Data
public class TransactionRespondRequest {
    
    @NotBlank(message = "响应动作不能为空")
    @Pattern(regexp = "AGREE|REJECT", message = "响应动作必须是AGREE或REJECT")
    private String action;
    
    private String reason;
}