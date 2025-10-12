package com.fliliy.secondhand.annotation;

import com.fliliy.secondhand.util.RateLimiter;

import java.lang.annotation.*;

/**
 * 限流注解
 * 用于标注需要限流的接口方法
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RateLimit {

    /**
     * 限流key的前缀（通常使用接口名）
     * 默认为空，使用方法名作为key
     */
    String key() default "";

    /**
     * 限流类型
     * USER: 按用户ID限流
     * IP: 按IP地址限流
     * GLOBAL: 全局限流
     */
    RateLimiter.LimitType limitType() default RateLimiter.LimitType.USER;

    /**
     * 时间窗口内最大请求次数
     */
    int maxCount() default 100;

    /**
     * 时间窗口大小（秒）
     */
    int period() default 60;

    /**
     * 限流提示信息
     */
    String message() default "访问过于频繁，请稍后再试";
}
