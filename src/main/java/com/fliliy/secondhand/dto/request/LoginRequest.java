package com.fliliy.secondhand.dto.request;

import com.fliliy.secondhand.validation.ValidPhoneNumber;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

@Data
public class LoginRequest {

    @NotBlank(message = "手机号不能为空")
    @ValidPhoneNumber(message = "手机号格式错误")
    private String mobile;
    
    private String password;
    
    private String smsCode;
    
    private String smsId;
    
    private Boolean rememberMe = false;
}