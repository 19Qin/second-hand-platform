package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import com.fliliy.secondhand.dto.response.SystemConfigResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/system")
@RequiredArgsConstructor
@Slf4j
public class SystemController {
    
    /**
     * 获取系统配置（公开配置）
     */
    @GetMapping("/config")
    public ApiResponse<SystemConfigResponse> getSystemConfig() {
        try {
            SystemConfigResponse config = new SystemConfigResponse();
            config.setVersion("v2.0");
            
            // 上传配置
            SystemConfigResponse.UploadConfig uploadConfig = new SystemConfigResponse.UploadConfig();
            uploadConfig.setMaxImageCount(20);
            uploadConfig.setMaxImageSize("10MB");
            uploadConfig.setMaxVoiceDuration(60);
            uploadConfig.setSupportedImageFormats(new String[]{"jpg", "jpeg", "png", "webp"});
            uploadConfig.setSupportedVoiceFormats(new String[]{"aac", "mp3", "wav"});
            config.setUpload(uploadConfig);
            
            // 短信配置
            SystemConfigResponse.SmsConfig smsConfig = new SystemConfigResponse.SmsConfig();
            smsConfig.setCodeLength(4);
            smsConfig.setExpireMinutes(5);
            smsConfig.setDailyLimit(10);
            config.setSms(smsConfig);
            
            // 交易配置
            SystemConfigResponse.TransactionConfig transactionConfig = new SystemConfigResponse.TransactionConfig();
            transactionConfig.setCodeLength(4);
            transactionConfig.setExpireHours(24);
            config.setTransaction(transactionConfig);
            
            // 功能开关
            SystemConfigResponse.FeaturesConfig featuresConfig = new SystemConfigResponse.FeaturesConfig();
            featuresConfig.setLocationService(false);
            featuresConfig.setAiEvaluation(false);
            featuresConfig.setOnlinePayment(false);
            featuresConfig.setPushNotification(true);
            config.setFeatures(featuresConfig);
            
            return ApiResponse.success("获取成功", config);
        } catch (Exception e) {
            log.error("Get system config failed", e);
            return ApiResponse.error("获取系统配置失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取应用版本信息
     */
    @GetMapping("/version")
    public ApiResponse<Object> getVersion() {
        try {
            Object versionInfo = new Object() {
                public final String version = "v2.0";
                public final String buildTime = "2025-09-26";
                public final String environment = "production";
                public final String[] features = {
                    "用户认证系统",
                    "商品管理",
                    "聊天系统", 
                    "交易管理",
                    "文件上传",
                    "地址管理",
                    "消息通知"
                };
            };
            return ApiResponse.success("获取成功", versionInfo);
        } catch (Exception e) {
            log.error("Get version info failed", e);
            return ApiResponse.error("获取版本信息失败: " + e.getMessage());
        }
    }
}