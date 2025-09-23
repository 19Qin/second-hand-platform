-- ===============================================
-- 生产环境数据库更新脚本
-- 聊天系统优化 - 从商品导向改为用户关系导向
-- 执行日期: 2025-09-23
-- ===============================================

-- 注意: 在生产环境执行前请先备份数据库！
-- 备份命令: mysqldump -u [username] -p [database_name] > backup_$(date +%Y%m%d_%H%M%S).sql

START TRANSACTION;

-- ===============================================
-- 第一步：备份现有数据
-- ===============================================

-- 备份原始聊天室表
CREATE TABLE chat_rooms_backup_20250923 AS SELECT * FROM chat_rooms;

-- 备份原始消息表  
CREATE TABLE chat_messages_backup_20250923 AS SELECT * FROM chat_messages;

-- ===============================================
-- 第二步：更新 chat_rooms 表结构
-- ===============================================

-- 检查当前表结构
-- DESCRIBE chat_rooms;

-- 1. 删除原有的 product_id 相关约束和索引（如果存在）
-- ALTER TABLE chat_rooms DROP FOREIGN KEY IF EXISTS fk_chat_rooms_product_id;
-- ALTER TABLE chat_rooms DROP INDEX IF EXISTS idx_product_id;

-- 2. 删除 product_id 字段（如果存在）
-- ALTER TABLE chat_rooms DROP COLUMN IF EXISTS product_id;

-- 3. 添加买家卖家唯一约束（核心优化）
ALTER TABLE chat_rooms ADD CONSTRAINT uk_buyer_seller UNIQUE (buyer_id, seller_id);

-- 4. 添加聊天室设置字段（如果不存在）
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS buyer_muted TINYINT(1) DEFAULT 0 COMMENT '买家是否免打扰';
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS seller_muted TINYINT(1) DEFAULT 0 COMMENT '卖家是否免打扰';
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS buyer_pinned TINYINT(1) DEFAULT 0 COMMENT '买家是否置顶';
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS seller_pinned TINYINT(1) DEFAULT 0 COMMENT '卖家是否置顶';

-- 5. 添加新的索引优化
ALTER TABLE chat_rooms ADD INDEX IF NOT EXISTS idx_buyer_updated (buyer_id, updated_at DESC);
ALTER TABLE chat_rooms ADD INDEX IF NOT EXISTS idx_seller_updated (seller_id, updated_at DESC);

-- ===============================================
-- 第三步：更新 chat_messages 表结构
-- ===============================================

-- 1. 添加商品关联字段（核心优化）
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS related_product_id BIGINT COMMENT '关联商品ID';
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS product_snapshot JSON COMMENT '商品快照数据';

-- 2. 确保消息类型支持 PRODUCT_CARD
ALTER TABLE chat_messages MODIFY COLUMN message_type ENUM('TEXT', 'IMAGE', 'VOICE', 'SYSTEM', 'PRODUCT_CARD') NOT NULL COMMENT '消息类型';

-- 3. 添加商品相关索引
ALTER TABLE chat_messages ADD INDEX IF NOT EXISTS idx_related_product (related_product_id);
ALTER TABLE chat_messages ADD INDEX IF NOT EXISTS idx_chat_room_product (chat_room_id, related_product_id);

-- 4. 添加外键约束（如果不存在）
-- ALTER TABLE chat_messages ADD CONSTRAINT fk_messages_product_id FOREIGN KEY (related_product_id) REFERENCES products(id);

-- ===============================================
-- 第四步：数据迁移和清理
-- ===============================================

-- 1. 迁移基于商品的聊天室到基于用户关系的聊天室
-- 注意：此步骤需要根据实际数据情况调整

-- 查找重复的买家-卖家聊天室
SELECT buyer_id, seller_id, COUNT(*) as room_count 
FROM chat_rooms 
GROUP BY buyer_id, seller_id 
HAVING COUNT(*) > 1;

-- 如果发现重复聊天室，需要手动处理或使用以下逻辑：
-- （保留最新的聊天室，将老聊天室的消息迁移过去）

-- 2. 将原来基于商品的消息关联转移到新的 related_product_id 字段
-- 这个步骤需要根据您原有的数据结构进行调整

-- 3. 更新商品快照数据（为已有的商品关联消息）
UPDATE chat_messages cm
LEFT JOIN products p ON cm.related_product_id = p.id
SET cm.product_snapshot = JSON_OBJECT(
    'id', p.id,
    'title', p.title,
    'price', p.price,
    'imageUrl', IFNULL(
        (SELECT pi.image_url FROM product_images pi WHERE pi.product_id = p.id AND pi.sort_order = 0 LIMIT 1),
        'https://cdn.fliliy.com/products/default.png'
    ),
    'status', p.status,
    'sellerId', p.seller_id,
    'snapshotTime', NOW()
)
WHERE cm.message_type = 'PRODUCT_CARD' 
AND cm.related_product_id IS NOT NULL 
AND cm.product_snapshot IS NULL;

-- ===============================================
-- 第五步：验证数据完整性
-- ===============================================

-- 1. 检查唯一约束是否生效
SELECT buyer_id, seller_id, COUNT(*) as count 
FROM chat_rooms 
GROUP BY buyer_id, seller_id 
HAVING COUNT(*) > 1;

-- 2. 检查商品关联消息数量
SELECT 
    COUNT(*) as total_messages,
    COUNT(related_product_id) as product_related_messages,
    COUNT(CASE WHEN message_type = 'PRODUCT_CARD' THEN 1 END) as product_card_messages
FROM chat_messages;

-- 3. 检查商品快照数据
SELECT 
    COUNT(*) as product_cards_with_snapshot
FROM chat_messages 
WHERE message_type = 'PRODUCT_CARD' 
AND product_snapshot IS NOT NULL;

-- 4. 验证外键约束
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME IN ('chat_rooms', 'chat_messages');

-- ===============================================
-- 第六步：更新统计信息
-- ===============================================

-- 1. 重新计算每个聊天室的消息总数
UPDATE chat_rooms cr
SET total_messages = (
    SELECT COUNT(*) 
    FROM chat_messages cm 
    WHERE cm.chat_room_id = cr.id
);

-- 2. 重新计算未读消息数（可选，根据业务逻辑调整）
UPDATE chat_rooms cr
SET buyer_unread_count = (
    SELECT COUNT(*) 
    FROM chat_messages cm 
    WHERE cm.chat_room_id = cr.id 
    AND cm.sender_id = cr.seller_id 
    AND cm.read_at IS NULL
),
seller_unread_count = (
    SELECT COUNT(*) 
    FROM chat_messages cm 
    WHERE cm.chat_room_id = cr.id 
    AND cm.sender_id = cr.buyer_id 
    AND cm.read_at IS NULL
);

-- 3. 更新最后消息信息
UPDATE chat_rooms cr
JOIN (
    SELECT 
        chat_room_id,
        id as last_message_id,
        content as last_message_content,
        message_type as last_message_type,
        sent_at as last_message_time,
        sender_id as last_message_sender_id
    FROM chat_messages cm1
    WHERE cm1.sent_at = (
        SELECT MAX(cm2.sent_at) 
        FROM chat_messages cm2 
        WHERE cm2.chat_room_id = cm1.chat_room_id
    )
) lm ON cr.id = lm.chat_room_id
SET 
    cr.last_message_id = lm.last_message_id,
    cr.last_message_content = lm.last_message_content,
    cr.last_message_type = lm.last_message_type,
    cr.last_message_time = lm.last_message_time,
    cr.last_message_sender_id = lm.last_message_sender_id,
    cr.updated_at = lm.last_message_time;

-- ===============================================
-- 最终验证
-- ===============================================

-- 输出更新后的统计信息
SELECT 
    '聊天室总数' as metric,
    COUNT(*) as value
FROM chat_rooms
UNION ALL
SELECT 
    '消息总数' as metric,
    COUNT(*) as value
FROM chat_messages
UNION ALL
SELECT 
    '商品关联消息数' as metric,
    COUNT(*) as value
FROM chat_messages 
WHERE related_product_id IS NOT NULL
UNION ALL
SELECT 
    '商品卡片消息数' as metric,
    COUNT(*) as value
FROM chat_messages 
WHERE message_type = 'PRODUCT_CARD';

-- 如果所有验证都通过，提交事务
COMMIT;

-- 如果有问题，回滚事务
-- ROLLBACK;

-- ===============================================
-- 执行后清理（可选）
-- ===============================================

-- 成功更新后，可以删除备份表（建议保留一段时间）
-- DROP TABLE IF EXISTS chat_rooms_backup_20250923;
-- DROP TABLE IF EXISTS chat_messages_backup_20250923;

-- ===============================================
-- 执行说明
-- ===============================================

/*
⚠️  执行前准备:
1. 完整备份数据库
2. 在测试环境先执行一遍
3. 选择业务低峰期执行
4. 准备回滚方案

✅ 执行步骤:
1. 备份当前数据库
2. 在测试环境执行此脚本
3. 验证功能是否正常
4. 在生产环境执行
5. 验证应用功能正常

🔍 执行后验证:
1. 检查聊天室唯一约束生效
2. 验证商品关联功能正常
3. 测试API接口功能
4. 确认数据完整性
5. 监控应用性能

📊 预期效果:
- 聊天室数量减少（合并重复的买家-卖家聊天室）
- 支持商品关联消息功能
- 聊天列表按用户关系显示
- API响应性能提升
*/