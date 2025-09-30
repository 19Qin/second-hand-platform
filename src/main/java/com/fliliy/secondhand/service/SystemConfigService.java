package com.fliliy.secondhand.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fliliy.secondhand.dto.response.SystemConfigResponse;
import com.fliliy.secondhand.entity.SystemConfig;
import com.fliliy.secondhand.repository.SystemConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class SystemConfigService {
    
    private final SystemConfigRepository systemConfigRepository;
    private final ObjectMapper objectMapper;
    
    /**
     * 获取系统配置（公开配置）
     */
    public SystemConfigResponse getSystemConfig() {
        List<SystemConfig> configs = systemConfigRepository.findPublicConfigs();
        
        SystemConfigResponse response = new SystemConfigResponse();
        response.setVersion("v2.0");
        
        // 上传配置
        SystemConfigResponse.UploadConfig uploadConfig = new SystemConfigResponse.UploadConfig();
        uploadConfig.setMaxImageCount(getIntConfig(configs, "upload.max_image_count", 20));
        uploadConfig.setMaxImageSize(formatFileSize(getLongConfig(configs, "upload.max_image_size", 10485760L)));
        uploadConfig.setMaxVoiceDuration(getIntConfig(configs, "upload.max_voice_duration", 60));
        uploadConfig.setSupportedImageFormats(getJsonArrayConfig(configs, "upload.supported_image_formats", new String[]{"jpg", "jpeg", "png", "webp"}));
        uploadConfig.setSupportedVoiceFormats(getJsonArrayConfig(configs, "upload.supported_voice_formats", new String[]{"aac", "mp3", "wav"}));
        response.setUpload(uploadConfig);
        
        // 短信配置
        SystemConfigResponse.SmsConfig smsConfig = new SystemConfigResponse.SmsConfig();
        smsConfig.setCodeLength(getIntConfig(configs, "sms.code_length", 4));
        smsConfig.setExpireMinutes(getIntConfig(configs, "sms.code_expire_minutes", 5));
        smsConfig.setDailyLimit(getIntConfig(configs, "sms.daily_limit", 10));
        response.setSms(smsConfig);
        
        // 交易配置
        SystemConfigResponse.TransactionConfig transactionConfig = new SystemConfigResponse.TransactionConfig();
        transactionConfig.setCodeLength(getIntConfig(configs, "transaction.code_length", 4));
        transactionConfig.setExpireHours(getIntConfig(configs, "transaction.code_expire_hours", 24));
        response.setTransaction(transactionConfig);
        
        // 功能开关
        SystemConfigResponse.FeaturesConfig featuresConfig = new SystemConfigResponse.FeaturesConfig();
        featuresConfig.setLocationService(getBooleanConfig(configs, "features.location_service", false));
        featuresConfig.setAiEvaluation(getBooleanConfig(configs, "features.ai_evaluation", false));
        featuresConfig.setOnlinePayment(getBooleanConfig(configs, "features.online_payment", false));
        featuresConfig.setPushNotification(getBooleanConfig(configs, "features.push_notification", true));
        response.setFeatures(featuresConfig);
        
        return response;
    }
    
    /**
     * 获取配置值
     */
    public String getConfigValue(String key, String defaultValue) {
        return systemConfigRepository.findValueByKey(key).orElse(defaultValue);
    }
    
    /**
     * 获取整数配置
     */
    public Integer getIntConfig(String key, Integer defaultValue) {
        try {
            String value = getConfigValue(key, String.valueOf(defaultValue));
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            log.warn("Invalid integer config for key: {}, using default: {}", key, defaultValue);
            return defaultValue;
        }
    }
    
    /**
     * 获取布尔配置
     */
    public Boolean getBooleanConfig(String key, Boolean defaultValue) {
        String value = getConfigValue(key, String.valueOf(defaultValue));
        return Boolean.parseBoolean(value);
    }
    
    private Integer getIntConfig(List<SystemConfig> configs, String key, Integer defaultValue) {
        return configs.stream()
                .filter(config -> config.getConfigKey().equals(key))
                .findFirst()
                .map(config -> {
                    try {
                        return Integer.parseInt(config.getConfigValue());
                    } catch (NumberFormatException e) {
                        return defaultValue;
                    }
                })
                .orElse(defaultValue);
    }
    
    private Long getLongConfig(List<SystemConfig> configs, String key, Long defaultValue) {
        return configs.stream()
                .filter(config -> config.getConfigKey().equals(key))
                .findFirst()
                .map(config -> {
                    try {
                        return Long.parseLong(config.getConfigValue());
                    } catch (NumberFormatException e) {
                        return defaultValue;
                    }
                })
                .orElse(defaultValue);
    }
    
    private Boolean getBooleanConfig(List<SystemConfig> configs, String key, Boolean defaultValue) {
        return configs.stream()
                .filter(config -> config.getConfigKey().equals(key))
                .findFirst()
                .map(config -> Boolean.parseBoolean(config.getConfigValue()))
                .orElse(defaultValue);
    }
    
    private String[] getJsonArrayConfig(List<SystemConfig> configs, String key, String[] defaultValue) {
        return configs.stream()
                .filter(config -> config.getConfigKey().equals(key))
                .findFirst()
                .map(config -> {
                    try {
                        return objectMapper.readValue(config.getConfigValue(), String[].class);
                    } catch (Exception e) {
                        log.warn("Failed to parse JSON array config for key: {}", key);
                        return defaultValue;
                    }
                })
                .orElse(defaultValue);
    }
    
    private String formatFileSize(Long bytes) {
        if (bytes < 1024) {
            return bytes + "B";
        } else if (bytes < 1024 * 1024) {
            return (bytes / 1024) + "KB";
        } else {
            return (bytes / 1024 / 1024) + "MB";
        }
    }
}