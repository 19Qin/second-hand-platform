package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Data
public class SendSmsRequest {
    
    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^(1[3-9]\\d{9}|0[4-5]\\d{8})$", message = "手机号格式错误")
    private String mobile;
    
    @NotBlank(message = "验证码类型不能为空")
    @Pattern(regexp = "^(register|login|reset|bind)$", message = "验证码类型错误")
    private String type;
}