package com.fliliy.secondhand.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.util.Arrays;

/**
 * 审计日志切面
 * 记录敏感操作的审计日志
 */
@Slf4j
@Aspect
@Component
public class AuditLogAspect {

    /**
     * 用户注册审计
     */
    @Pointcut("execution(* com.fliliy.secondhand.service.AuthService.register(..))")
    public void registerPointcut() {
    }

    /**
     * 用户登录审计
     */
    @Pointcut("execution(* com.fliliy.secondhand.service.AuthService.loginWith*(..))")
    public void loginPointcut() {
    }

    /**
     * 交易完成审计
     */
    @Pointcut("execution(* com.fliliy.secondhand.service.TransactionService.completeTransaction(..))")
    public void transactionCompletePointcut() {
    }

    /**
     * 商品删除审计
     */
    @Pointcut("execution(* com.fliliy.secondhand.service.ProductService.deleteProduct(..))")
    public void productDeletePointcut() {
    }

    /**
     * 记录注册审计日志
     */
    @AfterReturning(pointcut = "registerPointcut()", returning = "result")
    public void auditRegister(JoinPoint joinPoint, Object result) {
        try {
            Object[] args = joinPoint.getArgs();
            String clientIp = getClientIp();
            String userAgent = getUserAgent();

            log.info("[审计日志-注册] 操作: 用户注册, 时间: {}, IP: {}, UserAgent: {}, 参数: {}",
                    LocalDateTime.now(), clientIp, userAgent, maskSensitiveData(args));
        } catch (Exception e) {
            log.error("[审计日志] 记录注册审计日志失败", e);
        }
    }

    /**
     * 记录登录审计日志
     */
    @AfterReturning(pointcut = "loginPointcut()", returning = "result")
    public void auditLogin(JoinPoint joinPoint, Object result) {
        try {
            String methodName = joinPoint.getSignature().getName();
            String loginType = methodName.contains("Password") ? "密码登录" : "验证码登录";
            Object[] args = joinPoint.getArgs();
            String clientIp = getClientIp();
            String userAgent = getUserAgent();

            log.info("[审计日志-登录] 操作: {}, 时间: {}, IP: {}, UserAgent: {}, 状态: 成功",
                    loginType, LocalDateTime.now(), clientIp, userAgent);
        } catch (Exception e) {
            log.error("[审计日志] 记录登录审计日志失败", e);
        }
    }

    /**
     * 记录登录失败审计日志
     */
    @AfterThrowing(pointcut = "loginPointcut()", throwing = "exception")
    public void auditLoginFailure(JoinPoint joinPoint, Exception exception) {
        try {
            String methodName = joinPoint.getSignature().getName();
            String loginType = methodName.contains("Password") ? "密码登录" : "验证码登录";
            String clientIp = getClientIp();
            String userAgent = getUserAgent();

            log.warn("[审计日志-登录失败] 操作: {}, 时间: {}, IP: {}, UserAgent: {}, 失败原因: {}",
                    loginType, LocalDateTime.now(), clientIp, userAgent, exception.getMessage());
        } catch (Exception e) {
            log.error("[审计日志] 记录登录失败审计日志失败", e);
        }
    }

    /**
     * 记录交易完成审计日志
     */
    @AfterReturning(pointcut = "transactionCompletePointcut()", returning = "result")
    public void auditTransactionComplete(JoinPoint joinPoint, Object result) {
        try {
            Object[] args = joinPoint.getArgs();
            String clientIp = getClientIp();

            log.info("[审计日志-交易完成] 操作: 确认交易完成, 时间: {}, IP: {}, 参数: {}",
                    LocalDateTime.now(), clientIp, Arrays.toString(args));
        } catch (Exception e) {
            log.error("[审计日志] 记录交易完成审计日志失败", e);
        }
    }

    /**
     * 记录商品删除审计日志
     */
    @AfterReturning(pointcut = "productDeletePointcut()")
    public void auditProductDelete(JoinPoint joinPoint) {
        try {
            Object[] args = joinPoint.getArgs();
            String clientIp = getClientIp();

            log.info("[审计日志-商品删除] 操作: 删除商品, 时间: {}, IP: {}, 商品ID: {}",
                    LocalDateTime.now(), clientIp, args.length > 0 ? args[0] : "unknown");
        } catch (Exception e) {
            log.error("[审计日志] 记录商品删除审计日志失败", e);
        }
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
     * 获取UserAgent
     */
    private String getUserAgent() {
        try {
            ServletRequestAttributes attributes =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                String userAgent = request.getHeader("User-Agent");
                return userAgent != null ? userAgent : "unknown";
            }
        } catch (Exception e) {
            log.debug("获取UserAgent失败", e);
        }
        return "unknown";
    }

    /**
     * 脱敏处理敏感数据
     */
    private String maskSensitiveData(Object[] args) {
        if (args == null || args.length == 0) {
            return "[]";
        }
        // 简单处理：隐藏密码等敏感信息
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < args.length; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            Object arg = args[i];
            if (arg != null) {
                String argStr = arg.toString();
                // 隐藏密码字段
                if (argStr.contains("password")) {
                    sb.append("***sensitive data***");
                } else {
                    sb.append(arg.getClass().getSimpleName());
                }
            } else {
                sb.append("null");
            }
        }
        sb.append("]");
        return sb.toString();
    }
}
