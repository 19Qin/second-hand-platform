package com.fliliy.secondhand.message.consumer;

import com.fliliy.secondhand.constant.RabbitMQConstants;
import com.fliliy.secondhand.message.event.ProductDeletedEvent;
import com.fliliy.secondhand.message.event.ProductPublishedEvent;
import com.fliliy.secondhand.message.event.ProductUpdatedEvent;
import com.fliliy.secondhand.service.ElasticsearchSyncService;
import com.rabbitmq.client.Channel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * 商品事件消费者
 * 监听商品相关消息，将数据同步到Elasticsearch
 *
 * @author Claude Code
 * @date 2025-10-02
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ProductEventConsumer {

    private final ElasticsearchSyncService elasticsearchSyncService;

    /**
     * 消费商品发布消息
     * 将新发布的商品同步到ES
     *
     * @param event   商品发布事件
     * @param message 消息对象
     * @param channel 通道
     */
    @RabbitListener(queues = RabbitMQConstants.PRODUCT_PUBLISHED_QUEUE)
    public void handleProductPublished(ProductPublishedEvent event, Message message, Channel channel) {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            log.info("收到商品发布消息 - 商品ID: {}, 标题: {}", event.getProductId(), event.getTitle());

            // 同步到Elasticsearch
            elasticsearchSyncService.syncProduct(event.getProductId());

            log.info("商品发布消息处理成功 - 商品ID: {}, 已同步到ES", event.getProductId());

            // 手动ACK确认
            channel.basicAck(deliveryTag, false);

        } catch (Exception e) {
            log.error("处理商品发布消息失败 - 商品ID: {}, 错误: {}",
                    event.getProductId(), e.getMessage(), e);

            try {
                // 检查是否是 ES 解析错误或连接错误
                boolean isEsParseError = e.getMessage() != null &&
                    (e.getMessage().contains("Unable to parse response body") ||
                     e.getMessage().contains("ElasticsearchStatusException"));

                // ES解析错误不重试，直接ACK避免循环
                if (isEsParseError) {
                    log.warn("ES解析/状态错误，跳过重试 - 商品ID: {}", event.getProductId());
                    channel.basicAck(deliveryTag, false);
                } else {
                    // 其他错误，判断是否重新入队
                    boolean requeue = shouldRequeue(message);
                    channel.basicNack(deliveryTag, false, requeue);

                    if (!requeue) {
                        log.warn("商品发布消息处理失败次数过多，已发送到死信队列 - 商品ID: {}", event.getProductId());
                    }
                }
            } catch (IOException ioException) {
                log.error("消息NACK失败 - 商品ID: {}", event.getProductId(), ioException);
            }
        }
    }

    /**
     * 消费商品更新消息
     * 更新ES中的商品数据
     *
     * @param event   商品更新事件
     * @param message 消息对象
     * @param channel 通道
     */
    @RabbitListener(queues = RabbitMQConstants.PRODUCT_UPDATED_QUEUE)
    public void handleProductUpdated(ProductUpdatedEvent event, Message message, Channel channel) {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            log.info("收到商品更新消息 - 商品ID: {}", event.getProductId());

            // 同步到Elasticsearch
            elasticsearchSyncService.syncProduct(event.getProductId());

            log.info("商品更新消息处理成功 - 商品ID: {}, 已同步到ES", event.getProductId());

            // 手动ACK确认
            channel.basicAck(deliveryTag, false);

        } catch (Exception e) {
            log.error("处理商品更新消息失败 - 商品ID: {}, 错误: {}",
                    event.getProductId(), e.getMessage(), e);

            try {
                // 检查是否是 ES 解析错误或连接错误
                boolean isEsParseError = e.getMessage() != null &&
                    (e.getMessage().contains("Unable to parse response body") ||
                     e.getMessage().contains("ElasticsearchStatusException"));

                // ES解析错误不重试，直接ACK避免循环
                if (isEsParseError) {
                    log.warn("ES解析/状态错误，跳过重试 - 商品ID: {}", event.getProductId());
                    channel.basicAck(deliveryTag, false);
                } else {
                    boolean requeue = shouldRequeue(message);
                    channel.basicNack(deliveryTag, false, requeue);

                    if (!requeue) {
                        log.warn("商品更新消息处理失败次数过多，已发送到死信队列 - 商品ID: {}", event.getProductId());
                    }
                }
            } catch (IOException ioException) {
                log.error("消息NACK失败 - 商品ID: {}", event.getProductId(), ioException);
            }
        }
    }

    /**
     * 消费商品删除消息
     * 从ES中删除商品数据
     *
     * @param event   商品删除事件
     * @param message 消息对象
     * @param channel 通道
     */
    @RabbitListener(queues = RabbitMQConstants.PRODUCT_DELETED_QUEUE)
    public void handleProductDeleted(ProductDeletedEvent event, Message message, Channel channel) {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            log.info("收到商品删除消息 - 商品ID: {}", event.getProductId());

            // 从Elasticsearch删除
            elasticsearchSyncService.deleteProductFromEs(event.getProductId());

            log.info("商品删除消息处理成功 - 商品ID: {}, 已从ES删除", event.getProductId());

            // 手动ACK确认
            channel.basicAck(deliveryTag, false);

        } catch (Exception e) {
            log.error("处理商品删除消息失败 - 商品ID: {}, 错误: {}",
                    event.getProductId(), e.getMessage(), e);

            try {
                boolean requeue = shouldRequeue(message);
                channel.basicNack(deliveryTag, false, requeue);

                if (!requeue) {
                    log.warn("商品删除消息处理失败次数过多，已发送到死信队列 - 商品ID: {}", event.getProductId());
                }
            } catch (IOException ioException) {
                log.error("消息NACK失败 - 商品ID: {}", event.getProductId(), ioException);
            }
        }
    }

    /**
     * 判断消息是否应该重新入队
     * 基于消息重试次数判断
     *
     * @param message 消息对象
     * @return true-重新入队，false-不重新入队（发送到死信队列）
     */
    private boolean shouldRequeue(Message message) {
        // 获取消息重试次数
        Integer retryCount = (Integer) message.getMessageProperties().getHeaders().get("x-retry-count");
        if (retryCount == null) {
            retryCount = 0;
        }

        // 最多重试3次
        final int MAX_RETRY_COUNT = 3;
        if (retryCount >= MAX_RETRY_COUNT) {
            log.warn("消息重试次数已达上限 ({}/{}), 不再重新入队", retryCount, MAX_RETRY_COUNT);
            return false;
        }

        // 增加重试次数
        message.getMessageProperties().getHeaders().put("x-retry-count", retryCount + 1);
        log.info("消息将重新入队 - 当前重试次数: {}/{}", retryCount + 1, MAX_RETRY_COUNT);
        return true;
    }
}
