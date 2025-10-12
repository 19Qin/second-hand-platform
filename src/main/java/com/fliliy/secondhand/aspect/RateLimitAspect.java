package com.fliliy.secondhand.aspect;

import com.fliliy.secondhand.annotation.RateLimit;
import com.fliliy.secondhand.exception.BusinessException;
import com.fliliy.secondhand.exception.ErrorCode;
import com.fliliy.secondhand.util.RateLimiter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.lang.reflect.Method;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 限流切面
 * 拦截带有@RateLimit注解的方法，执行限流逻辑
 */
@Slf4j
@Aspect
@Component
@RequiredArgsConstructor
public class RateLimitAspect {

    private final RateLimiter rateLimiter;
    private final StringRedisTemplate redisTemplate;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Around("@annotation(com.fliliy.secondhand.annotation.RateLimit)")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        RateLimit rateLimit = method.getAnnotation(RateLimit.class);

        if (rateLimit == null) {
            return joinPoint.proceed();
        }

        // 构建限流key
        String key = buildRateLimitKey(rateLimit, method);

        // 尝试获取令牌
        boolean allowed = rateLimiter.tryAcquire(key, rateLimit.maxCount(), rateLimit.period());

        if (!allowed) {
            // 触发限流
            String identifier = getIdentifier(rateLimit.limitType());
            log.warn("[限流拦截] 接口: {}, 限流类型: {}, 标识: {}, 最大次数: {}/{}秒",
                    method.getName(), rateLimit.limitType(), identifier,
                    rateLimit.maxCount(), rateLimit.period());

            // 记录限流日志到Redis（用于监控仪表板）
            recordRateLimitLog(key, identifier, rateLimit.message());

            throw new BusinessException(ErrorCode.RATE_LIMIT_EXCEEDED, rateLimit.message());
        }

        // 放行
        return joinPoint.proceed();
    }

    /**
     * 构建限流key
     */
    private String buildRateLimitKey(RateLimit rateLimit, Method method) {
        String prefix = rateLimit.key();
        if (prefix == null || prefix.isEmpty()) {
            prefix = method.getDeclaringClass().getSimpleName() + "." + method.getName();
        }

        String identifier = getIdentifier(rateLimit.limitType());
        return rateLimiter.buildKey(prefix, rateLimit.limitType(), identifier);
    }

    /**
     * 获取限流标识符
     */
    private String getIdentifier(RateLimiter.LimitType limitType) {
        switch (limitType) {
            case USER:
                return getUserId();
            case IP:
                return getClientIp();
            case GLOBAL:
                return "global";
            default:
                return "unknown";
        }
    }

    /**
     * 获取当前用户ID
     */
    private String getUserId() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated()) {
                Object principal = authentication.getPrincipal();
                if (principal instanceof String) {
                    return (String) principal;
                }
            }
        } catch (Exception e) {
            log.debug("获取用户ID失败", e);
        }
        return "anonymous";
    }

    /**
     * 获取客户端IP
     */
    private String getClientIp() {
        try {
            ServletRequestAttributes attributes =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                String xForwardedFor = request.getHeader("X-Forwarded-For");
                if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
                    return xForwardedFor.split(",")[0].trim();
                }
                String xRealIp = request.getHeader("X-Real-IP");
                if (xRealIp != null && !xRealIp.isEmpty()) {
                    return xRealIp;
                }
                return request.getRemoteAddr();
            }
        } catch (Exception e) {
            log.debug("获取客户端IP失败", e);
        }
        return "unknown";
    }

    /**
     * 记录限流日志到Redis
     */
    private void recordRateLimitLog(String key, String identifier, String message) {
        try {
            String timestamp = LocalDateTime.now().format(FORMATTER);
            String logEntry = String.format("%s|%s|%s|%s", timestamp, key, identifier, message);

            // 使用Redis List存储日志，保留最近100条
            redisTemplate.opsForList().leftPush("rate_limit:logs", logEntry);
            redisTemplate.opsForList().trim("rate_limit:logs", 0, 99);
        } catch (Exception e) {
            log.debug("记录限流日志失败", e);
        }
    }
}
