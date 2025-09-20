package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Data
public class LoginRequest {
    
    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^(1[3-9]\\d{9}|0[4-5]\\d{8})$", message = "手机号格式错误")
    private String mobile;
    
    private String password;
    
    private String smsCode;
    
    private String smsId;
    
    private Boolean rememberMe = false;
}