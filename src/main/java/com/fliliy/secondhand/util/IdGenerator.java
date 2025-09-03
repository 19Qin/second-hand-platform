package com.fliliy.secondhand.util;

import cn.hutool.core.lang.Snowflake;
import cn.hutool.core.util.IdUtil;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Random;

@Component
public class IdGenerator {
    
    private static final Snowflake snowflake = IdUtil.getSnowflake(1, 1);
    private static final Random random = new Random();
    
    /**
     * 生成用户ID（雪花算法）
     */
    public static long generateUserId() {
        return snowflake.nextId();
    }
    
    /**
     * 生成验证码ID（时间戳格式）
     */
    public static String generateSmsId() {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        return "sms_" + timestamp + "_" + random.nextInt(1000);
    }
    
    /**
     * 生成4位数字验证码
     */
    public static String generateSmsCode() {
        return String.format("%04d", random.nextInt(10000));
    }
    
    /**
     * 生成设备ID
     */
    public static String generateDeviceId() {
        return "device_" + System.currentTimeMillis() + "_" + random.nextInt(1000);
    }
}