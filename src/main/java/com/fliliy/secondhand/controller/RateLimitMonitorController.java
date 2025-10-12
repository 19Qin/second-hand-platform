package com.fliliy.secondhand.controller;

import com.fliliy.secondhand.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 限流监控仪表板
 * 提供限流统计、监控和管理功能
 */
@RestController
@RequestMapping("/admin/rate-limit")
@RequiredArgsConstructor
@Slf4j
public class RateLimitMonitorController {

    private final StringRedisTemplate redisTemplate;

    /**
     * 获取限流统计概览
     */
    @GetMapping("/stats/overview")
    public ApiResponse<Map<String, Object>> getOverview() {
        try {
            Map<String, Object> overview = new HashMap<>();

            // 获取所有限流键
            Set<String> keys = redisTemplate.keys("rate_limit:*");
            if (keys == null || keys.isEmpty()) {
                overview.put("totalKeys", 0);
                overview.put("activeUsers", 0);
                overview.put("activeIPs", 0);
                overview.put("topLimits", Collections.emptyList());
                return ApiResponse.success("获取成功", overview);
            }

            // 统计总键数
            overview.put("totalKeys", keys.size());

            // 统计活跃用户数（按用户ID限流的键）
            long activeUsers = keys.stream()
                    .filter(key -> key.contains(":user:"))
                    .map(key -> key.split(":user:")[1].split(":")[0])
                    .distinct()
                    .count();
            overview.put("activeUsers", activeUsers);

            // 统计活跃IP数（按IP限流的键）
            long activeIPs = keys.stream()
                    .filter(key -> key.contains(":ip:"))
                    .map(key -> key.split(":ip:")[1].split(":")[0])
                    .distinct()
                    .count();
            overview.put("activeIPs", activeIPs);

            // 获取Top 10限流键（按请求计数排序）
            List<Map<String, Object>> topLimits = keys.stream()
                    .limit(100) // 限制查询数量避免性能问题
                    .map(key -> {
                        String value = redisTemplate.opsForValue().get(key);
                        Long ttl = redisTemplate.getExpire(key);
                        Map<String, Object> item = new HashMap<>();
                        item.put("key", key);
                        item.put("count", value != null ? Integer.parseInt(value) : 0);
                        item.put("ttl", ttl);
                        return item;
                    })
                    .sorted((a, b) -> Integer.compare((int)b.get("count"), (int)a.get("count")))
                    .limit(10)
                    .collect(Collectors.toList());
            overview.put("topLimits", topLimits);

            log.info("限流统计概览 - 总键数: {}, 活跃用户: {}, 活跃IP: {}",
                    keys.size(), activeUsers, activeIPs);

            return ApiResponse.success("获取成功", overview);
        } catch (Exception e) {
            log.error("获取限流统计概览失败", e);
            return ApiResponse.error("获取失败: " + e.getMessage());
        }
    }

    /**
     * 获取指定限流键的详细信息
     */
    @GetMapping("/stats/detail")
    public ApiResponse<Map<String, Object>> getDetail(@RequestParam String prefix) {
        try {
            String pattern = "rate_limit:" + prefix + "*";
            Set<String> keys = redisTemplate.keys(pattern);

            if (keys == null || keys.isEmpty()) {
                return ApiResponse.error("未找到匹配的限流键");
            }

            List<Map<String, Object>> details = keys.stream()
                    .map(key -> {
                        String value = redisTemplate.opsForValue().get(key);
                        Long ttl = redisTemplate.getExpire(key);
                        Map<String, Object> item = new HashMap<>();
                        item.put("key", key);
                        item.put("count", value != null ? Integer.parseInt(value) : 0);
                        item.put("ttl", ttl);
                        item.put("expiresIn", ttl != null ? ttl + "秒" : "永久");
                        return item;
                    })
                    .sorted((a, b) -> Integer.compare((int)b.get("count"), (int)a.get("count")))
                    .collect(Collectors.toList());

            Map<String, Object> result = new HashMap<>();
            result.put("pattern", pattern);
            result.put("matchCount", details.size());
            result.put("details", details);

            return ApiResponse.success("获取成功", result);
        } catch (Exception e) {
            log.error("获取限流详情失败", e);
            return ApiResponse.error("获取失败: " + e.getMessage());
        }
    }

    /**
     * 获取限流规则配置列表
     */
    @GetMapping("/rules")
    public ApiResponse<List<Map<String, Object>>> getRules() {
        List<Map<String, Object>> rules = new ArrayList<>();

        // 短信验证码
        rules.add(createRule("sendSms", "短信验证码发送", "IP", 1, 60, "防止短信轰炸"));

        // 认证相关
        rules.add(createRule("register", "用户注册", "IP", 3, 300, "防止批量注册"));
        rules.add(createRule("loginPassword", "密码登录", "IP", 5, 60, "防止暴力破解"));
        rules.add(createRule("loginSms", "验证码登录", "IP", 10, 60, "防止恶意登录"));

        // 商品相关
        rules.add(createRule("publishProduct", "发布商品", "USER", 5, 60, "防止刷屏"));
        rules.add(createRule("searchProducts", "搜索商品", "USER", 60, 60, "防止爬虫"));
        rules.add(createRule("uploadProductImage", "上传商品图片", "USER", 20, 60, "防止恶意上传"));

        // 聊天相关
        rules.add(createRule("sendMessage", "发送消息", "USER", 30, 60, "防止消息轰炸"));
        rules.add(createRule("uploadChatFile", "上传聊天文件", "USER", 20, 60, "防止恶意上传"));

        return ApiResponse.success("获取成功", rules);
    }

    /**
     * 清除指定用户的限流记录
     */
    @DeleteMapping("/clear/user/{userId}")
    public ApiResponse<Map<String, Object>> clearUserLimits(@PathVariable Long userId) {
        try {
            String pattern = "rate_limit:*:user:" + userId + ":*";
            Set<String> keys = redisTemplate.keys(pattern);

            if (keys != null && !keys.isEmpty()) {
                Long deleted = redisTemplate.delete(keys);
                log.warn("清除用户限流记录 - 用户ID: {}, 删除键数: {}", userId, deleted);

                Map<String, Object> result = new HashMap<>();
                result.put("userId", userId);
                result.put("deletedKeys", deleted);
                return ApiResponse.success("清除成功", result);
            }

            return ApiResponse.error("未找到该用户的限流记录");
        } catch (Exception e) {
            log.error("清除用户限流记录失败", e);
            return ApiResponse.error("清除失败: " + e.getMessage());
        }
    }

    /**
     * 清除指定IP的限流记录
     */
    @DeleteMapping("/clear/ip/{ip}")
    public ApiResponse<Map<String, Object>> clearIPLimits(@PathVariable String ip) {
        try {
            String pattern = "rate_limit:*:ip:" + ip + ":*";
            Set<String> keys = redisTemplate.keys(pattern);

            if (keys != null && !keys.isEmpty()) {
                Long deleted = redisTemplate.delete(keys);
                log.warn("清除IP限流记录 - IP: {}, 删除键数: {}", ip, deleted);

                Map<String, Object> result = new HashMap<>();
                result.put("ip", ip);
                result.put("deletedKeys", deleted);
                return ApiResponse.success("清除成功", result);
            }

            return ApiResponse.error("未找到该IP的限流记录");
        } catch (Exception e) {
            log.error("清除IP限流记录失败", e);
            return ApiResponse.error("清除失败: " + e.getMessage());
        }
    }

    /**
     * 清除所有限流记录（谨慎使用）
     */
    @DeleteMapping("/clear/all")
    public ApiResponse<Map<String, Object>> clearAllLimits(@RequestParam(required = false) String confirm) {
        try {
            if (!"YES".equals(confirm)) {
                return ApiResponse.error("请添加参数 confirm=YES 以确认清除所有限流记录");
            }

            Set<String> keys = redisTemplate.keys("rate_limit:*");

            if (keys != null && !keys.isEmpty()) {
                Long deleted = redisTemplate.delete(keys);
                log.warn("清除所有限流记录 - 删除键数: {}", deleted);

                Map<String, Object> result = new HashMap<>();
                result.put("deletedKeys", deleted);
                return ApiResponse.success("清除成功", result);
            }

            return ApiResponse.error("未找到任何限流记录");
        } catch (Exception e) {
            log.error("清除所有限流记录失败", e);
            return ApiResponse.error("清除失败: " + e.getMessage());
        }
    }

    /**
     * 获取限流触发日志（最近的限流事件）
     */
    @GetMapping("/logs")
    public ApiResponse<List<Map<String, Object>>> getLogs(
            @RequestParam(defaultValue = "20") int limit) {
        try {
            // 从Redis获取最近的限流日志
            String logKey = "rate_limit:logs";
            List<String> logs = redisTemplate.opsForList().range(logKey, 0, limit - 1);

            if (logs == null || logs.isEmpty()) {
                return ApiResponse.success("暂无限流日志", Collections.emptyList());
            }

            List<Map<String, Object>> logList = logs.stream()
                    .map(log -> {
                        Map<String, Object> item = new HashMap<>();
                        String[] parts = log.split("\\|");
                        if (parts.length >= 4) {
                            item.put("timestamp", parts[0]);
                            item.put("key", parts[1]);
                            item.put("identifier", parts[2]);
                            item.put("message", parts[3]);
                        } else {
                            item.put("raw", log);
                        }
                        return item;
                    })
                    .collect(Collectors.toList());

            return ApiResponse.success("获取成功", logList);
        } catch (Exception e) {
            log.error("获取限流日志失败", e);
            return ApiResponse.error("获取失败: " + e.getMessage());
        }
    }

    // 辅助方法
    private Map<String, Object> createRule(String key, String name, String limitType,
                                          int maxCount, int period, String description) {
        Map<String, Object> rule = new HashMap<>();
        rule.put("key", key);
        rule.put("name", name);
        rule.put("limitType", limitType);
        rule.put("maxCount", maxCount);
        rule.put("period", period);
        rule.put("periodDisplay", period < 120 ? period + "秒" : (period / 60) + "分钟");
        rule.put("rateDisplay", maxCount + "次/" + (period < 120 ? period + "秒" : (period / 60) + "分钟"));
        rule.put("description", description);
        rule.put("enabled", true);
        return rule;
    }
}
