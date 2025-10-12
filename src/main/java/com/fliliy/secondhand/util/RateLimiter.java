package com.fliliy.secondhand.util;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.concurrent.TimeUnit;

/**
 * 限流器工具类
 * 基于Redis + Lua脚本实现分布式限流
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RateLimiter {

    private final RedisTemplate<String, Object> redisTemplate;

    /**
     * 限流类型
     */
    public enum LimitType {
        /**
         * 按用户ID限流
         */
        USER,

        /**
         * 按IP地址限流
         */
        IP,

        /**
         * 全局限流（所有用户共享）
         */
        GLOBAL
    }

    /**
     * 尝试获取令牌
     *
     * @param key      限流key
     * @param maxCount 时间窗口内最大请求数
     * @param period   时间窗口（秒）
     * @return true-获取成功，false-被限流
     */
    public boolean tryAcquire(String key, int maxCount, int period) {
        try {
            // Lua脚本实现滑动窗口限流
            String luaScript =
                    "local key = KEYS[1]\n" +
                    "local maxCount = tonumber(ARGV[1])\n" +
                    "local period = tonumber(ARGV[2])\n" +
                    "local current = tonumber(redis.call('get', key) or '0')\n" +
                    "if current < maxCount then\n" +
                    "    redis.call('incr', key)\n" +
                    "    if current == 0 then\n" +
                    "        redis.call('expire', key, period)\n" +
                    "    end\n" +
                    "    return 1\n" +
                    "else\n" +
                    "    return 0\n" +
                    "end";

            DefaultRedisScript<Long> redisScript = new DefaultRedisScript<>();
            redisScript.setScriptText(luaScript);
            redisScript.setResultType(Long.class);

            Long result = redisTemplate.execute(
                    redisScript,
                    Collections.singletonList(key),
                    maxCount,
                    period
            );

            boolean allowed = result != null && result == 1;

            if (!allowed) {
                log.warn("[限流] 触发限流 - Key: {}, 最大次数: {}, 时间窗口: {}秒", key, maxCount, period);
            }

            return allowed;

        } catch (Exception e) {
            log.error("[限流] 限流器执行异常 - Key: {}, 原因: {}", key, e.getMessage(), e);
            // 异常时放行，避免影响业务
            return true;
        }
    }

    /**
     * 构建限流Key
     *
     * @param prefix     前缀（通常是接口名）
     * @param limitType  限流类型
     * @param identifier 标识符（用户ID或IP）
     * @return 限流Key
     */
    public String buildKey(String prefix, LimitType limitType, String identifier) {
        return String.format("rate_limit:%s:%s:%s", prefix, limitType.name().toLowerCase(), identifier);
    }

    /**
     * 获取剩余调用次数
     *
     * @param key 限流key
     * @return 剩余次数（-1表示无限制）
     */
    public long getRemainingCount(String key, int maxCount) {
        try {
            Object value = redisTemplate.opsForValue().get(key);
            if (value == null) {
                return maxCount;
            }
            long current = Long.parseLong(value.toString());
            return Math.max(0, maxCount - current);
        } catch (Exception e) {
            log.error("[限流] 获取剩余次数失败 - Key: {}, 原因: {}", key, e.getMessage());
            return -1;
        }
    }

    /**
     * 重置限流计数
     *
     * @param key 限流key
     */
    public void reset(String key) {
        try {
            redisTemplate.delete(key);
            log.info("[限流] 重置限流计数 - Key: {}", key);
        } catch (Exception e) {
            log.error("[限流] 重置限流计数失败 - Key: {}, 原因: {}", key, e.getMessage());
        }
    }

    /**
     * 获取限流Key的过期时间
     *
     * @param key 限流key
     * @return 过期时间（秒），-1表示永不过期，-2表示key不存在
     */
    public long getTtl(String key) {
        try {
            Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
            return ttl != null ? ttl : -2;
        } catch (Exception e) {
            log.error("[限流] 获取过期时间失败 - Key: {}, 原因: {}", key, e.getMessage());
            return -2;
        }
    }
}
