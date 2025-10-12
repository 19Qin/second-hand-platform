package com.fliliy.secondhand.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

/**
 * 性能监控切面
 * 监控Controller和Service层方法的执行时间
 */
@Slf4j
@Aspect
@Component
public class PerformanceMonitorAspect {

    /**
     * 定义Controller层切点
     */
    @Pointcut("execution(* com.fliliy.secondhand.controller..*.*(..))")
    public void controllerPointcut() {
    }

    /**
     * 定义Service层切点
     */
    @Pointcut("execution(* com.fliliy.secondhand.service..*.*(..))")
    public void servicePointcut() {
    }

    /**
     * 监控Controller层方法执行时间
     */
    @Around("controllerPointcut()")
    public Object monitorControllerPerformance(ProceedingJoinPoint joinPoint) throws Throwable {
        return monitorPerformance(joinPoint, "Controller");
    }

    /**
     * 监控Service层方法执行时间
     */
    @Around("servicePointcut()")
    public Object monitorServicePerformance(ProceedingJoinPoint joinPoint) throws Throwable {
        return monitorPerformance(joinPoint, "Service");
    }

    /**
     * 通用性能监控方法
     *
     * @param joinPoint 切点
     * @param layer     层级名称（Controller/Service）
     * @return 方法执行结果
     * @throws Throwable 方法执行异常
     */
    private Object monitorPerformance(ProceedingJoinPoint joinPoint, String layer) throws Throwable {
        String className = joinPoint.getTarget().getClass().getSimpleName();
        String methodName = joinPoint.getSignature().getName();
        String fullMethodName = className + "." + methodName;

        long startTime = System.currentTimeMillis();

        try {
            // 执行目标方法
            Object result = joinPoint.proceed();
            long executionTime = System.currentTimeMillis() - startTime;

            // 根据执行时间记录不同级别的日志
            if (executionTime > 1000) {
                // 慢方法告警：执行时间超过1秒
                log.warn("[{}] SLOW METHOD: {} executed in {}ms", layer, fullMethodName, executionTime);
            } else if (executionTime > 500) {
                // 较慢方法：执行时间超过500ms
                log.info("[{}] {} executed in {}ms", layer, fullMethodName, executionTime);
            } else {
                // 正常方法：执行时间小于500ms
                log.debug("[{}] {} executed in {}ms", layer, fullMethodName, executionTime);
            }

            return result;

        } catch (Throwable throwable) {
            long executionTime = System.currentTimeMillis() - startTime;
            log.error("[{}] {} failed after {}ms with error: {}",
                    layer, fullMethodName, executionTime, throwable.getMessage());
            throw throwable;
        }
    }
}
