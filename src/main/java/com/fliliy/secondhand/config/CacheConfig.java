package com.fliliy.secondhand.config;

import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableCaching
public class CacheConfig {

    @Autowired
    private ObjectMapper objectMapper;

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory redisConnectionFactory) {
        // 创建专门用于缓存的ObjectMapper，启用类型信息
        ObjectMapper cacheMapper = objectMapper.copy();
        cacheMapper.activateDefaultTyping(
            LaissezFaireSubTypeValidator.instance,
            ObjectMapper.DefaultTyping.NON_FINAL,
            JsonTypeInfo.As.PROPERTY
        );

        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofHours(1)) // 默认缓存1小时
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer(cacheMapper)))
                .disableCachingNullValues(); // 不缓存null值

        // 不同缓存的配置
        Map<String, RedisCacheConfiguration> cacheConfigurations = new HashMap<>();

        // 分类缓存（缓存6小时 - 很少变化）
        cacheConfigurations.put("categories", defaultConfig.entryTtl(Duration.ofHours(6)));

        // 商品详情缓存（缓存5分钟 - 变化较频繁）
        cacheConfigurations.put("products", defaultConfig.entryTtl(Duration.ofMinutes(5)));

        // 商品列表缓存（缓存1分钟 - 实时性要求高）
        cacheConfigurations.put("product-lists", defaultConfig.entryTtl(Duration.ofMinutes(1)));

        // 用户信息缓存（缓存30分钟 - 较稳定）
        cacheConfigurations.put("users", defaultConfig.entryTtl(Duration.ofMinutes(30)));

        // 聊天室列表缓存（缓存30秒 - 实时性要求高）
        cacheConfigurations.put("chat-rooms", defaultConfig.entryTtl(Duration.ofSeconds(30)));

        // 计数器缓存（缓存5分钟 - 浏览量、收藏数等）
        cacheConfigurations.put("counters", defaultConfig.entryTtl(Duration.ofMinutes(5)));

        return RedisCacheManager.builder(redisConnectionFactory)
                .cacheDefaults(defaultConfig)
                .withInitialCacheConfigurations(cacheConfigurations)
                .transactionAware()
                .build();
    }
}