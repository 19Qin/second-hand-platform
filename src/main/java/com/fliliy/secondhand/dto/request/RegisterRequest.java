package com.fliliy.secondhand.dto.request;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

@Data
public class RegisterRequest {
    
    @NotBlank(message = "用户昵称不能为空")
    @Size(min = 1, max = 50, message = "用户昵称长度应在1-50字符之间")
    private String username;
    
    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式错误")
    private String mobile;
    
    @NotBlank(message = "密码不能为空")
    @Size(min = 8, max = 20, message = "密码长度应在8-20字符之间")
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$", 
             message = "密码必须包含字母和数字，长度至少8位")
    private String password;
    
    @NotBlank(message = "确认密码不能为空")
    private String confirmPassword;
    
    @NotBlank(message = "短信验证码不能为空")
    @Pattern(regexp = "^\\d{4}$", message = "验证码格式错误")
    private String smsCode;
    
    @NotBlank(message = "短信ID不能为空")
    private String smsId;
    
    private Boolean agreeTerms = false;
}