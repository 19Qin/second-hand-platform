package com.fliliy.secondhand.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

/**
 * Redis健康检查指示器
 * 检查Redis连接状态和响应时间
 */
@Component
public class RedisHealthIndicator implements HealthIndicator {

    private final RedisTemplate<String, Object> redisTemplate;

    public RedisHealthIndicator(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    public Health health() {
        try {
            long startTime = System.currentTimeMillis();

            // 执行PING命令测试Redis连接
            String pong = redisTemplate.execute((RedisConnection connection) -> {
                return connection.ping();
            });

            long responseTime = System.currentTimeMillis() - startTime;

            if ("PONG".equals(pong)) {
                return Health.up()
                        .withDetail("cache", "Redis")
                        .withDetail("responseTime", responseTime + "ms")
                        .withDetail("status", "Connected")
                        .build();
            }

            return Health.down()
                    .withDetail("cache", "Redis")
                    .withDetail("error", "PING command failed")
                    .build();

        } catch (Exception e) {
            return Health.down()
                    .withDetail("cache", "Redis")
                    .withDetail("error", e.getMessage())
                    .build();
        }
    }
}
