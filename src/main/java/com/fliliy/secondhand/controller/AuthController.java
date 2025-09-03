package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.request.LoginRequest;
import com.fliliy.secondhand.dto.request.RegisterRequest;
import com.fliliy.secondhand.dto.request.SendSmsRequest;
import com.fliliy.secondhand.dto.response.AuthResponse;
import com.fliliy.secondhand.dto.response.SmsResponse;
import com.fliliy.secondhand.entity.VerificationCode;
import com.fliliy.secondhand.service.AuthService;
import com.fliliy.secondhand.service.SmsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {
    
    private final AuthService authService;
    private final SmsService smsService;
    
    /**
     * 发送短信验证码
     */
    @PostMapping("/sms/send")
    public ApiResponse<SmsResponse> sendSms(@Valid @RequestBody SendSmsRequest request) {
        try {
            VerificationCode.CodeType type = VerificationCode.CodeType.valueOf(request.getType().toUpperCase());
            String smsId = smsService.sendSmsCode(request.getMobile(), type);
            
            SmsResponse response = new SmsResponse();
            response.setSmsId(smsId);
            response.setExpireTime(300); // 5分钟
            
            return ApiResponse.success("验证码发送成功", response);
        } catch (Exception e) {
            log.error("Send SMS failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 用户注册
     */
    @PostMapping("/register")
    public ApiResponse<AuthResponse> register(@Valid @RequestBody RegisterRequest request, 
                                              HttpServletRequest httpRequest) {
        try {
            AuthResponse response = authService.register(request, httpRequest);
            return ApiResponse.success("注册成功", response);
        } catch (Exception e) {
            log.error("Register failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 密码登录
     */
    @PostMapping("/login/password")
    public ApiResponse<AuthResponse> loginWithPassword(@Valid @RequestBody LoginRequest request,
                                                      HttpServletRequest httpRequest) {
        try {
            if (StringUtils.isBlank(request.getPassword())) {
                return ApiResponse.error("密码不能为空");
            }
            
            AuthResponse response = authService.loginWithPassword(request, httpRequest);
            return ApiResponse.success("登录成功", response);
        } catch (Exception e) {
            log.error("Password login failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 验证码登录
     */
    @PostMapping("/login/sms")
    public ApiResponse<AuthResponse> loginWithSms(@Valid @RequestBody LoginRequest request,
                                                 HttpServletRequest httpRequest) {
        try {
            if (StringUtils.isBlank(request.getSmsCode()) || StringUtils.isBlank(request.getSmsId())) {
                return ApiResponse.error("验证码信息不能为空");
            }
            
            AuthResponse response = authService.loginWithSms(request, httpRequest);
            return ApiResponse.success("登录成功", response);
        } catch (Exception e) {
            log.error("SMS login failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 刷新令牌
     */
    @PostMapping("/token/refresh")
    public ApiResponse<AuthResponse> refreshToken(@RequestBody Map<String, String> request,
                                                  HttpServletRequest httpRequest) {
        try {
            String refreshToken = request.get("refreshToken");
            if (StringUtils.isBlank(refreshToken)) {
                return ApiResponse.error("刷新令牌不能为空");
            }
            
            AuthResponse response = authService.refreshToken(refreshToken, httpRequest);
            return ApiResponse.success("Token刷新成功", response);
        } catch (Exception e) {
            log.error("Refresh token failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
    
    /**
     * 退出登录
     */
    @PostMapping("/logout")
    public ApiResponse<Void> logout(@RequestBody(required = false) Map<String, String> request) {
        try {
            String refreshToken = null;
            if (request != null) {
                refreshToken = request.get("refreshToken");
            }
            
            authService.logout(refreshToken);
            return ApiResponse.success("退出登录成功", null);
        } catch (Exception e) {
            log.error("Logout failed", e);
            return ApiResponse.error(e.getMessage());
        }
    }
}