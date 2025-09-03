package com.fliliy.secondhand.service;

import com.fliliy.secondhand.common.ErrorCode;
import com.fliliy.secondhand.entity.VerificationCode;
import com.fliliy.secondhand.entity.SmsRecord;
import com.fliliy.secondhand.repository.VerificationCodeRepository;
import com.fliliy.secondhand.repository.SmsRecordRepository;
import com.fliliy.secondhand.util.IdGenerator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class SmsService {
    
    private final VerificationCodeRepository verificationCodeRepository;
    private final SmsRecordRepository smsRecordRepository;
    private final StringRedisTemplate redisTemplate;
    
    private static final int CODE_EXPIRE_MINUTES = 5;
    private static final int RATE_LIMIT_SECONDS = 60;
    private static final int DAILY_LIMIT = 10;
    private static final String RATE_LIMIT_PREFIX = "sms:rate:";
    private static final String DAILY_COUNT_PREFIX = "sms:daily:";
    
    /**
     * 发送短信验证码
     */
    public String sendSmsCode(String mobile, VerificationCode.CodeType type) {
        // 检查发送频率限制
        checkRateLimit(mobile);
        
        // 检查每日发送次数限制
        checkDailyLimit(mobile, type);
        
        // 使之前未使用的验证码失效
        verificationCodeRepository.markUsedByMobileAndType(mobile, type);
        
        // 生成新的验证码
        String smsId = IdGenerator.generateSmsId();
        String code = IdGenerator.generateSmsCode();
        
        VerificationCode verificationCode = new VerificationCode();
        verificationCode.setId(smsId);
        verificationCode.setMobile(mobile);
        verificationCode.setCode(code);
        verificationCode.setType(type);
        verificationCode.setExpiresAt(LocalDateTime.now().plusMinutes(CODE_EXPIRE_MINUTES));
        
        log.info("Saving verification code - Mobile: {}, Type: {}, Enum name: {}", 
                mobile, type, type.name());
        
        verificationCodeRepository.save(verificationCode);
        
        // 保存短信发送记录
        saveSmsRecord(mobile, code, type, smsId);
        
        // TODO: 调用第三方短信服务发送验证码
        sendSmsToThirdParty(mobile, code, type);
        
        // 设置频率限制
        setRateLimit(mobile);
        
        // 增加每日计数
        incrementDailyCount(mobile, type);
        
        log.info("SMS code sent to mobile: {}, type: {}, code: {}", mobile, type, code);
        
        return smsId;
    }
    
    /**
     * 验证短信验证码
     */
    public boolean verifySmsCode(String mobile, String code, String smsId, VerificationCode.CodeType type) {
        Optional<VerificationCode> optionalCode = verificationCodeRepository.findById(smsId);
        
        if (!optionalCode.isPresent()) {
            return false;
        }
        
        VerificationCode verificationCode = optionalCode.get();
        
        // 检查验证码是否已过期
        if (verificationCode.getExpiresAt().isBefore(LocalDateTime.now())) {
            return false;
        }
        
        // 检查验证码是否已使用
        if (verificationCode.getUsed()) {
            return false;
        }
        
        // 检查尝试次数
        if (verificationCode.getAttempts() >= verificationCode.getMaxAttempts()) {
            return false;
        }
        
        // 检查手机号和类型是否匹配
        if (!mobile.equals(verificationCode.getMobile()) || !type.equals(verificationCode.getType())) {
            verificationCodeRepository.incrementAttempts(smsId);
            return false;
        }
        
        // 检查验证码是否正确
        if (!code.equals(verificationCode.getCode())) {
            verificationCodeRepository.incrementAttempts(smsId);
            return false;
        }
        
        // 验证成功，标记为已使用
        verificationCode.setUsed(true);
        verificationCodeRepository.save(verificationCode);
        
        return true;
    }
    
    private void checkRateLimit(String mobile) {
        String key = RATE_LIMIT_PREFIX + mobile;
        if (Boolean.TRUE.equals(redisTemplate.hasKey(key))) {
            throw new RuntimeException("短信发送过于频繁，请稍后再试");
        }
    }
    
    private void setRateLimit(String mobile) {
        String key = RATE_LIMIT_PREFIX + mobile;
        redisTemplate.opsForValue().set(key, "1", RATE_LIMIT_SECONDS, TimeUnit.SECONDS);
    }
    
    private void checkDailyLimit(String mobile, VerificationCode.CodeType type) {
        LocalDateTime todayStart = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0).withNano(0);
        long todayCount = verificationCodeRepository.countByMobileAndTypeAndCreatedAtAfter(mobile, type, todayStart);
        
        if (todayCount >= DAILY_LIMIT) {
            throw new RuntimeException("今日短信发送次数已达上限");
        }
    }
    
    private void incrementDailyCount(String mobile, VerificationCode.CodeType type) {
        // TODO: 暂时跳过每日计数
        // String key = DAILY_COUNT_PREFIX + mobile + ":" + type;
        // String count = redisTemplate.opsForValue().get(key);
        // if (count == null) {
        //     redisTemplate.opsForValue().set(key, "1", 24, TimeUnit.HOURS);
        // } else {
        //     redisTemplate.opsForValue().increment(key);
        // }
    }
    
    private void saveSmsRecord(String mobile, String code, VerificationCode.CodeType type, String smsId) {
        SmsRecord smsRecord = new SmsRecord();
        smsRecord.setMobile(mobile);
        smsRecord.setCode(code);
        // 直接根据枚举名称映射，两个枚举定义相同
        SmsRecord.SmsType smsType = SmsRecord.SmsType.valueOf(type.name());
        smsRecord.setType(smsType);
        smsRecord.setTemplateCode("TEMPLATE_" + type.name());
        smsRecord.setSendStatus(SmsRecord.SendStatus.SUCCESS);
        smsRecord.setProvider("mock");
        smsRecord.setProviderMsgId(smsId);
        smsRecord.setSentAt(LocalDateTime.now());
        
        smsRecordRepository.save(smsRecord);
        
        log.info("SMS record saved - Mobile: {}, Type: {}, SmsType name: {}", 
                mobile, type, smsRecord.getType().name());
    }
    
    private void sendSmsToThirdParty(String mobile, String code, VerificationCode.CodeType type) {
        // TODO: 集成阿里云短信服务
        log.info("Sending SMS to {}: Your verification code is {}", mobile, code);
    }
}