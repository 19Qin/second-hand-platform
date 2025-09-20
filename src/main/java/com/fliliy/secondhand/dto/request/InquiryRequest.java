package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Data
public class InquiryRequest {
    
    @NotNull(message = "商品ID不能为空")
    private Long productId;
    
    @NotNull(message = "卖家ID不能为空")
    private Long sellerId;
    
    @NotBlank(message = "咨询内容不能为空")
    @Size(max = 500, message = "咨询内容不能超过500个字符")
    private String message;
    
    @NotBlank(message = "咨询类型不能为空")
    @Pattern(regexp = "^(PURCHASE|INFO)$", message = "咨询类型必须是PURCHASE或INFO")
    private String inquiryType;
}