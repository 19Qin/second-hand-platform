-- ===============================================
-- 聊天系统深度分析和设计优化建议
-- 分析日期：2025-09-23
-- 分析内容：基于当前代码实现和数据库状态的深度分析
-- ===============================================

-- ===============================================
-- 1. 当前系统状态分析
-- ===============================================

/*
系统优化成果：
✅ 已成功从"商品导向"聊天室改为"用户关系导向"聊天室
✅ 数据库结构已完全重构并优化
✅ 代码层面已完全适配新的聊天室模型
✅ 聊天室唯一约束正常工作（buyer_id + seller_id）
✅ 商品关联功能完整实现（related_product_id + product_snapshot）
✅ 支持多种消息类型（TEXT, IMAGE, VOICE, SYSTEM, PRODUCT_CARD）

当前数据状态：
- 聊天室总数：5个
- 聊天消息总数：12条
- 备份表完整保存：chat_rooms_backup, chat_messages_backup
- 数据完整性：外键约束正常，数据一致性良好
*/

-- ===============================================
-- 2. 核心设计特点分析
-- ===============================================

/*
A. 聊天室设计优势：
1. 用户关系唯一性
   - 通过 UNIQUE KEY uk_buyer_seller (buyer_id, seller_id) 确保一对用户只有一个聊天室
   - 解决了原来同一商家多个聊天室的重复问题
   - 提升用户体验，聊天列表更简洁

2. 灵活的消息关联
   - related_product_id 字段支持消息与商品的关联
   - product_snapshot JSON字段保存商品历史状态
   - 支持在同一聊天室讨论多个商品

3. 完善的消息状态管理
   - 支持消息送达、已读状态
   - 撤回功能（2分钟内有效）
   - 分离的买家/卖家未读计数

4. 高级聊天功能
   - 置顶/免打扰功能
   - 消息搜索和筛选
   - 聊天记录导出
*/

-- ===============================================
-- 3. 代码实现分析
-- ===============================================

/*
A. 实体类设计 (ChatRoom.java)
优点：
- 完整的业务方法：updateLastMessage, markAsRead, isParticipant等
- 枚举类型规范：ChatRoomStatus, MessageType
- JPA生命周期方法完善
- 用户角色处理灵活（buyerId/sellerId）

B. 服务层设计 (ChatService.java)  
优点：
- 事务管理完善（@Transactional注解合理使用）
- 权限验证严格（canAccessChatRoom方法）
- 商品讨论功能完整（startProductDiscussion）
- WebSocket集成良好
- 消息类型支持全面

C. 控制器设计 (ChatController.java)
优点：
- RESTful API设计规范
- 异常处理完善
- JWT认证集成
- 支持多种创建聊天室的方式
*/

-- ===============================================
-- 4. 数据库性能优化建议
-- ===============================================

-- A. 索引优化（已实现的索引）
SHOW INDEX FROM chat_rooms;
SHOW INDEX FROM chat_messages;

-- B. 新增推荐索引（如果查询性能需要优化）
-- 聊天室复合索引优化
CREATE INDEX idx_chat_rooms_status_updated_at ON chat_rooms(status, updated_at);
CREATE INDEX idx_chat_rooms_buyer_status ON chat_rooms(buyer_id, status);
CREATE INDEX idx_chat_rooms_seller_status ON chat_rooms(seller_id, status);

-- 消息表复合索引优化
CREATE INDEX idx_chat_messages_room_status_sent ON chat_messages(chat_room_id, status, sent_at DESC);
CREATE INDEX idx_chat_messages_sender_type ON chat_messages(sender_id, message_type);
CREATE INDEX idx_chat_messages_product_sent ON chat_messages(related_product_id, sent_at DESC);

-- C. 分区建议（大数据量时）
/*
当消息量达到千万级别时，建议按时间分区：
ALTER TABLE chat_messages 
PARTITION BY RANGE (YEAR(sent_at)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
*/

-- ===============================================
-- 5. 新功能扩展建议
-- ===============================================

-- A. 消息加密支持
ALTER TABLE chat_messages ADD COLUMN encrypted_content TEXT COMMENT '加密后的消息内容';
ALTER TABLE chat_messages ADD COLUMN encryption_method VARCHAR(50) COMMENT '加密方式';

-- B. 消息引用/回复功能
ALTER TABLE chat_messages ADD COLUMN reply_to_message_id BIGINT COMMENT '回复的消息ID';
ALTER TABLE chat_messages ADD COLUMN reply_to_content TEXT COMMENT '被回复消息的内容快照';
ALTER TABLE chat_messages ADD INDEX idx_reply_to_message (reply_to_message_id);

-- C. 聊天室标签系统
CREATE TABLE chat_room_tags (
    id BIGINT PRIMARY KEY,
    chat_room_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL COMMENT '设置标签的用户ID',
    tag_name VARCHAR(50) NOT NULL COMMENT '标签名称',
    tag_color VARCHAR(20) COMMENT '标签颜色',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_room_user_tag (chat_room_id, user_id, tag_name),
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) COMMENT='聊天室用户自定义标签';

-- D. 消息模板系统
CREATE TABLE chat_message_templates (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    template_name VARCHAR(100) NOT NULL COMMENT '模板名称',
    template_content TEXT NOT NULL COMMENT '模板内容',
    usage_count INT DEFAULT 0 COMMENT '使用次数',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
) COMMENT='用户自定义消息模板';

-- E. 聊天室统计表
CREATE TABLE chat_room_statistics (
    chat_room_id BIGINT PRIMARY KEY,
    total_messages INT DEFAULT 0 COMMENT '总消息数',
    total_images INT DEFAULT 0 COMMENT '图片消息数',
    total_voices INT DEFAULT 0 COMMENT '语音消息数',
    total_products_discussed INT DEFAULT 0 COMMENT '讨论的商品数',
    avg_response_time INT COMMENT '平均响应时间（秒）',
    last_active_date DATE COMMENT '最后活跃日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id)
) COMMENT='聊天室统计信息';

-- ===============================================
-- 6. API接口增强建议
-- ===============================================

/*
A. 新增批量操作接口
- POST /chats/batch/mark-read - 批量标记多个聊天室为已读
- POST /chats/batch/archive - 批量归档聊天室
- GET /chats/statistics - 获取用户聊天统计信息

B. 增强搜索功能
- GET /chats/search - 全局搜索所有聊天记录
- GET /chats/{roomId}/search/advanced - 高级搜索（按时间、类型、商品等）

C. 导出功能增强
- GET /chats/{roomId}/export/pdf - 导出为PDF格式
- GET /chats/{roomId}/export/excel - 导出为Excel格式
- POST /chats/export/multiple - 批量导出多个聊天室

D. 实时状态接口
- GET /chats/online-users - 获取在线用户列表
- POST /chats/{roomId}/typing - 发送正在输入状态
- GET /chats/{roomId}/read-receipts - 获取消息阅读回执
*/

-- ===============================================
-- 7. 性能监控查询
-- ===============================================

-- A. 聊天室活跃度分析
SELECT 
    DATE(updated_at) as date,
    COUNT(*) as active_rooms,
    AVG(total_messages) as avg_messages_per_room,
    SUM(buyer_unread_count + seller_unread_count) as total_unread
FROM chat_rooms 
WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(updated_at)
ORDER BY date DESC;

-- B. 消息类型分布统计
SELECT 
    message_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM chat_messages), 2) as percentage
FROM chat_messages 
WHERE sent_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY message_type
ORDER BY count DESC;

-- C. 商品讨论热度排行
SELECT 
    related_product_id as product_id,
    COUNT(*) as discussion_count,
    COUNT(DISTINCT chat_room_id) as room_count,
    MAX(sent_at) as last_discussed
FROM chat_messages 
WHERE related_product_id IS NOT NULL
  AND sent_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY related_product_id
ORDER BY discussion_count DESC
LIMIT 20;

-- D. 用户聊天活跃度分析
SELECT 
    sender_id as user_id,
    COUNT(*) as sent_messages,
    COUNT(DISTINCT chat_room_id) as active_rooms,
    MAX(sent_at) as last_message_time,
    AVG(LENGTH(content)) as avg_message_length
FROM chat_messages 
WHERE sent_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND message_type = 'TEXT'
GROUP BY sender_id
ORDER BY sent_messages DESC
LIMIT 20;

-- ===============================================
-- 8. 数据维护脚本
-- ===============================================

-- A. 清理过期的撤回消息（保留1个月）
DELETE FROM chat_messages 
WHERE is_recalled = 1 
  AND recalled_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- B. 更新聊天室统计信息
UPDATE chat_rooms cr SET 
    total_messages = (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.chat_room_id = cr.id 
          AND cm.is_recalled = 0
    ),
    buyer_unread_count = (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.chat_room_id = cr.id 
          AND cm.sender_id = cr.seller_id 
          AND cm.status != 'READ'
          AND cm.is_recalled = 0
    ),
    seller_unread_count = (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.chat_room_id = cr.id 
          AND cm.sender_id = cr.buyer_id 
          AND cm.status != 'read'
          AND cm.is_recalled = 0
    );

-- C. 归档超过6个月无活动的聊天室
UPDATE chat_rooms 
SET status = 'CLOSED' 
WHERE status = 'ACTIVE' 
  AND updated_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- ===============================================
-- 9. 安全性增强建议
-- ===============================================

/*
A. 消息内容过滤
- 实现敏感词过滤
- 添加消息内容审核
- 支持举报和屏蔽功能

B. 权限控制增强
- 添加聊天室访问日志
- 实现API调用频率限制
- 增加用户行为审计

C. 数据加密
- 敏感消息内容加密存储
- 文件传输加密
- 数据库连接加密
*/

-- ===============================================
-- 10. 系统优化总结
-- ===============================================

/*
当前聊天系统已达到生产级别要求：

核心功能完整性：✅
- 用户关系导向的聊天室模型
- 多商品讨论支持
- 完整的消息类型支持
- 实时通信（WebSocket）
- 消息状态管理

数据设计优化：✅
- 合理的数据库结构
- 完善的索引策略
- 数据完整性约束
- 商品快照机制

代码质量优秀：✅
- 清晰的分层架构
- 完善的异常处理
- 事务管理规范
- 权限验证严格

性能考虑周全：✅
- 查询优化
- 分页支持
- 缓存策略
- 数据归档

后续发展方向：
1. 增强用户体验（消息模板、标签系统）
2. 提升性能监控（统计分析、报表）
3. 强化安全防护（内容过滤、行为审计）
4. 扩展高级功能（智能推荐、AI助手）

这套聊天系统设计已经非常成熟，完全满足二手交易平台的业务需求。
*/