package com.fliliy.secondhand.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fliliy.secondhand.constant.RabbitMQConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

/**
 * RabbitMQ 配置类
 * 定义交换机、队列、绑定关系和消息转换器
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Slf4j
@Configuration
public class RabbitMQConfig {

    // ==================== 消息转换器 ====================

    /**
     * JSON消息转换器
     * 使用Jackson将对象转换为JSON格式的消息
     * 支持Java 8日期时间类型
     */
    @Bean
    public MessageConverter jsonMessageConverter() {
        ObjectMapper objectMapper = new ObjectMapper();
        // 注册Java 8日期时间模块
        objectMapper.registerModule(new JavaTimeModule());
        // 禁用将日期写为时间戳
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        return new Jackson2JsonMessageConverter(objectMapper);
    }

    /**
     * RabbitTemplate配置
     * 配置消息发送模板，支持发送确认和返回
     */
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter());

        // 消息发送到exchange后的确认回调
        template.setConfirmCallback((correlationData, ack, cause) -> {
            if (ack) {
                log.debug("消息发送到Exchange成功: {}", correlationData);
            } else {
                log.error("消息发送到Exchange失败: {}, 原因: {}", correlationData, cause);
            }
        });

        // 消息从exchange路由到queue失败的回调
        template.setReturnsCallback(returned -> {
            log.error("消息路由到队列失败 - 消息: {}, 回复码: {}, 回复文本: {}, 交换机: {}, 路由键: {}",
                    returned.getMessage(),
                    returned.getReplyCode(),
                    returned.getReplyText(),
                    returned.getExchange(),
                    returned.getRoutingKey());
        });

        return template;
    }

    /**
     * 监听器容器工厂配置
     * 配置消息监听器的行为
     */
    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(jsonMessageConverter());
        return factory;
    }

    // ==================== 死信队列配置 ====================

    /**
     * 死信交换机
     */
    @Bean
    public DirectExchange dlxExchange() {
        return new DirectExchange(RabbitMQConstants.DLX_EXCHANGE, true, false);
    }

    /**
     * 死信队列
     */
    @Bean
    public Queue dlxQueue() {
        return QueueBuilder.durable(RabbitMQConstants.DLX_QUEUE).build();
    }

    /**
     * 绑定死信队列到死信交换机
     */
    @Bean
    public Binding dlxBinding() {
        return BindingBuilder.bind(dlxQueue()).to(dlxExchange()).with(RabbitMQConstants.DLX_ROUTING_KEY);
    }

    // ==================== 商品交换机和队列 ====================

    /**
     * 商品Topic交换机
     */
    @Bean
    public TopicExchange productExchange() {
        return new TopicExchange(RabbitMQConstants.PRODUCT_EXCHANGE, true, false);
    }

    /**
     * 商品发布队列（带死信队列配置）
     */
    @Bean
    public Queue productPublishedQueue() {
        Map<String, Object> args = new HashMap<>();
        // 配置死信交换机
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.PRODUCT_PUBLISHED_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 商品更新队列（带死信队列配置）
     */
    @Bean
    public Queue productUpdatedQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.PRODUCT_UPDATED_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 商品删除队列（带死信队列配置）
     */
    @Bean
    public Queue productDeletedQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.PRODUCT_DELETED_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 绑定商品发布队列
     */
    @Bean
    public Binding productPublishedBinding() {
        return BindingBuilder.bind(productPublishedQueue())
                .to(productExchange())
                .with(RabbitMQConstants.PRODUCT_PUBLISHED_ROUTING_KEY);
    }

    /**
     * 绑定商品更新队列
     */
    @Bean
    public Binding productUpdatedBinding() {
        return BindingBuilder.bind(productUpdatedQueue())
                .to(productExchange())
                .with(RabbitMQConstants.PRODUCT_UPDATED_ROUTING_KEY);
    }

    /**
     * 绑定商品删除队列
     */
    @Bean
    public Binding productDeletedBinding() {
        return BindingBuilder.bind(productDeletedQueue())
                .to(productExchange())
                .with(RabbitMQConstants.PRODUCT_DELETED_ROUTING_KEY);
    }

    // ==================== 交易交换机和队列 ====================

    /**
     * 交易Topic交换机
     */
    @Bean
    public TopicExchange transactionExchange() {
        return new TopicExchange(RabbitMQConstants.TRANSACTION_EXCHANGE, true, false);
    }

    /**
     * 交易完成队列
     */
    @Bean
    public Queue transactionCompletedQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.TRANSACTION_COMPLETED_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 交易取消队列
     */
    @Bean
    public Queue transactionCancelledQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.TRANSACTION_CANCELLED_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 绑定交易完成队列
     */
    @Bean
    public Binding transactionCompletedBinding() {
        return BindingBuilder.bind(transactionCompletedQueue())
                .to(transactionExchange())
                .with(RabbitMQConstants.TRANSACTION_COMPLETED_ROUTING_KEY);
    }

    /**
     * 绑定交易取消队列
     */
    @Bean
    public Binding transactionCancelledBinding() {
        return BindingBuilder.bind(transactionCancelledQueue())
                .to(transactionExchange())
                .with(RabbitMQConstants.TRANSACTION_CANCELLED_ROUTING_KEY);
    }

    // ==================== 通知交换机和队列 ====================

    /**
     * 通知Fanout交换机（广播模式）
     */
    @Bean
    public FanoutExchange notificationExchange() {
        return new FanoutExchange(RabbitMQConstants.NOTIFICATION_EXCHANGE, true, false);
    }

    /**
     * 应用内通知队列
     */
    @Bean
    public Queue notificationAppQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.NOTIFICATION_APP_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 短信通知队列
     */
    @Bean
    public Queue notificationSmsQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put(RabbitMQConstants.X_DEAD_LETTER_EXCHANGE, RabbitMQConstants.DLX_EXCHANGE);
        args.put(RabbitMQConstants.X_DEAD_LETTER_ROUTING_KEY, RabbitMQConstants.DLX_ROUTING_KEY);
        return QueueBuilder.durable(RabbitMQConstants.NOTIFICATION_SMS_QUEUE)
                .withArguments(args)
                .build();
    }

    /**
     * 绑定应用内通知队列（Fanout交换机不需要路由键）
     */
    @Bean
    public Binding notificationAppBinding() {
        return BindingBuilder.bind(notificationAppQueue()).to(notificationExchange());
    }

    /**
     * 绑定短信通知队列（Fanout交换机不需要路由键）
     */
    @Bean
    public Binding notificationSmsBinding() {
        return BindingBuilder.bind(notificationSmsQueue()).to(notificationExchange());
    }
}
