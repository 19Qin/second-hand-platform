-- ===============================================
-- 聊天系统优化 - 数据迁移脚本
-- 将基于商品的聊天室改为基于用户关系的聊天室
-- ===============================================

-- 步骤1：备份原始数据
CREATE TABLE chat_rooms_backup AS SELECT * FROM chat_rooms;
CREATE TABLE chat_messages_backup AS SELECT * FROM chat_messages;

-- 步骤2：创建新的聊天室表结构
CREATE TABLE chat_rooms_new (
    id BIGINT PRIMARY KEY,
    transaction_id BIGINT,
    buyer_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    last_message_id BIGINT,
    last_message_content TEXT,
    last_message_type VARCHAR(20),
    last_message_time TIMESTAMP,
    last_message_sender_id BIGINT,
    buyer_unread_count INT DEFAULT 0,
    seller_unread_count INT DEFAULT 0,
    total_messages INT DEFAULT 0,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    
    -- 唯一约束：一个买家和一个卖家只能有一个聊天室
    UNIQUE KEY uk_buyer_seller (buyer_id, seller_id),
    
    -- 外键约束
    FOREIGN KEY (buyer_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES users(id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- 步骤3：数据迁移 - 合并相同买家-卖家的聊天室
INSERT INTO chat_rooms_new (
    id, buyer_id, seller_id, status, 
    last_message_time, total_messages, created_at, updated_at
)
SELECT 
    MIN(cr.id) as id,
    cr.buyer_id,
    cr.seller_id,
    'ACTIVE' as status,
    MAX(cr.last_message_time) as last_message_time,
    SUM(COALESCE(cr.total_messages, 0)) as total_messages,
    MIN(cr.created_at) as created_at,
    MAX(cr.updated_at) as updated_at
FROM chat_rooms cr
GROUP BY cr.buyer_id, cr.seller_id;

-- 步骤4：更新聊天室的最后消息信息
UPDATE chat_rooms_new crn
SET 
    last_message_id = (
        SELECT cm.id 
        FROM chat_messages cm 
        JOIN chat_rooms cr ON cm.chat_room_id = cr.id
        WHERE cr.buyer_id = crn.buyer_id AND cr.seller_id = crn.seller_id
        ORDER BY cm.sent_at DESC 
        LIMIT 1
    ),
    last_message_content = (
        SELECT cm.content 
        FROM chat_messages cm 
        JOIN chat_rooms cr ON cm.chat_room_id = cr.id
        WHERE cr.buyer_id = crn.buyer_id AND cr.seller_id = crn.seller_id
        ORDER BY cm.sent_at DESC 
        LIMIT 1
    ),
    last_message_type = (
        SELECT cm.message_type 
        FROM chat_messages cm 
        JOIN chat_rooms cr ON cm.chat_room_id = cr.id
        WHERE cr.buyer_id = crn.buyer_id AND cr.seller_id = crn.seller_id
        ORDER BY cm.sent_at DESC 
        LIMIT 1
    ),
    last_message_sender_id = (
        SELECT cm.sender_id 
        FROM chat_messages cm 
        JOIN chat_rooms cr ON cm.chat_room_id = cr.id
        WHERE cr.buyer_id = crn.buyer_id AND cr.seller_id = crn.seller_id
        ORDER BY cm.sent_at DESC 
        LIMIT 1
    );

-- 步骤5：扩展消息表结构
ALTER TABLE chat_messages 
ADD COLUMN related_product_id BIGINT,
ADD COLUMN product_snapshot JSON;

-- 步骤6：将原聊天室的商品ID作为消息的商品关联
UPDATE chat_messages cm 
JOIN chat_rooms cr ON cm.chat_room_id = cr.id 
SET cm.related_product_id = cr.product_id;

-- 步骤7：创建商品快照数据
UPDATE chat_messages cm 
JOIN chat_rooms cr ON cm.chat_room_id = cr.id
JOIN products p ON cr.product_id = p.id
SET cm.product_snapshot = JSON_OBJECT(
    'id', p.id,
    'title', p.title,
    'price', p.price,
    'imageUrl', p.main_image_url,
    'status', p.status,
    'sellerId', p.seller_id
)
WHERE cm.related_product_id IS NOT NULL;

-- 步骤8：更新消息的聊天室关联
-- 创建聊天室ID映射表
CREATE TEMPORARY TABLE room_mapping AS
SELECT 
    cr_old.id as old_room_id,
    crn.id as new_room_id
FROM chat_rooms cr_old
JOIN chat_rooms_new crn ON cr_old.buyer_id = crn.buyer_id AND cr_old.seller_id = crn.seller_id;

-- 更新消息表中的聊天室ID
UPDATE chat_messages cm
JOIN room_mapping rm ON cm.chat_room_id = rm.old_room_id
SET cm.chat_room_id = rm.new_room_id;

-- 步骤9：重新计算未读消息数
UPDATE chat_rooms_new crn
SET buyer_unread_count = (
    SELECT COUNT(*) 
    FROM chat_messages cm 
    WHERE cm.chat_room_id = crn.id 
    AND cm.sender_id = crn.seller_id 
    AND cm.status != 'READ'
),
seller_unread_count = (
    SELECT COUNT(*) 
    FROM chat_messages cm 
    WHERE cm.chat_room_id = crn.id 
    AND cm.sender_id = crn.buyer_id 
    AND cm.status != 'read'
);

-- 步骤10：添加商品卡片消息
-- 为每个聊天室的第一次商品讨论添加商品卡片消息
INSERT INTO chat_messages (
    id, chat_room_id, sender_id, message_type, content, 
    related_product_id, product_snapshot, status, sent_at
)
SELECT 
    cm.id + 1000000000 as id, -- 确保ID不重复
    cm.chat_room_id,
    cm.sender_id,
    'PRODUCT_CARD' as message_type,
    '分享了商品' as content,
    cm.related_product_id,
    cm.product_snapshot,
    'SENT' as status,
    cm.sent_at - INTERVAL 1 SECOND as sent_at -- 比第一条消息早1秒
FROM (
    SELECT 
        cm.*,
        ROW_NUMBER() OVER (PARTITION BY cm.chat_room_id, cm.related_product_id ORDER BY cm.sent_at) as rn
    FROM chat_messages cm
    WHERE cm.related_product_id IS NOT NULL
) cm
WHERE cm.rn = 1; -- 只为每个商品的第一次讨论添加卡片

-- 步骤11：替换表和清理
DROP TABLE chat_rooms;
RENAME TABLE chat_rooms_new TO chat_rooms;

-- 删除临时表
DROP TEMPORARY TABLE room_mapping;

-- 步骤12：创建索引优化查询性能
CREATE INDEX idx_chat_rooms_buyer_seller ON chat_rooms(buyer_id, seller_id);
CREATE INDEX idx_chat_rooms_updated_at ON chat_rooms(updated_at DESC);
CREATE INDEX idx_chat_messages_related_product ON chat_messages(related_product_id);
CREATE INDEX idx_chat_messages_chat_room_sent_at ON chat_messages(chat_room_id, sent_at DESC);

-- 步骤13：更新统计信息
ANALYZE TABLE chat_rooms;
ANALYZE TABLE chat_messages;

-- ===============================================
-- 验证数据完整性
-- ===============================================

-- 检查聊天室数量变化
SELECT 
    '迁移前聊天室数量' as description,
    COUNT(*) as count
FROM chat_rooms_backup
UNION ALL
SELECT 
    '迁移后聊天室数量' as description,
    COUNT(*) as count
FROM chat_rooms;

-- 检查消息数量是否一致
SELECT 
    '迁移前消息数量' as description,
    COUNT(*) as count
FROM chat_messages_backup
UNION ALL
SELECT 
    '迁移后消息数量（包含新增商品卡片）' as description,
    COUNT(*) as count
FROM chat_messages;

-- 检查是否有孤立的消息
SELECT 
    '孤立消息数量' as description,
    COUNT(*) as count
FROM chat_messages cm
LEFT JOIN chat_rooms cr ON cm.chat_room_id = cr.id
WHERE cr.id IS NULL;

-- 检查重复的买家-卖家组合
SELECT 
    '重复的买家-卖家组合' as description,
    COUNT(*) as count
FROM (
    SELECT buyer_id, seller_id, COUNT(*) as cnt
    FROM chat_rooms
    GROUP BY buyer_id, seller_id
    HAVING cnt > 1
) duplicates;

-- ===============================================
-- 回滚脚本（如果需要）
-- ===============================================
/*
-- 如果迁移出现问题，可以使用以下脚本回滚：

DROP TABLE chat_rooms;
DROP TABLE chat_messages;

RENAME TABLE chat_rooms_backup TO chat_rooms;
RENAME TABLE chat_messages_backup TO chat_messages;

-- 移除新增的字段
ALTER TABLE chat_messages 
DROP COLUMN related_product_id,
DROP COLUMN product_snapshot;
*/

-- ===============================================
-- 迁移完成后的清理工作
-- ===============================================

-- 在确认迁移成功后，可以删除备份表：
-- DROP TABLE chat_rooms_backup;
-- DROP TABLE chat_messages_backup;

COMMIT;