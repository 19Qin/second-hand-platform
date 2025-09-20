package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Data
public class CompleteTransactionRequest {
    
    @NotBlank(message = "交易验证码不能为空")
    @Pattern(regexp = "^\\d{4}$", message = "交易验证码必须是4位数字")
    private String transactionCode;
    
    @Size(max = 500, message = "评价内容不能超过500个字符")
    private String feedback;
    
    @Min(value = 1, message = "评分不能低于1星")
    @Max(value = 5, message = "评分不能高于5星")
    private Integer rating;
}