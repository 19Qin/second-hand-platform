-- ===============================================
-- 聊天室重复数据清理脚本
-- 解决用户对角色反向导致的重复聊天室问题
-- ===============================================

-- 1. 查看当前重复的聊天室
SELECT 
    LEAST(buyer_id, seller_id) as user1,
    GREATEST(buyer_id, seller_id) as user2,
    COUNT(*) as room_count,
    GROUP_CONCAT(id) as room_ids,
    GROUP_CONCAT(total_messages) as message_counts
FROM chat_rooms 
GROUP BY LEAST(buyer_id, seller_id), GREATEST(buyer_id, seller_id)
HAVING COUNT(*) > 1;

-- 2. 创建临时表保存需要合并的聊天室信息
CREATE TEMPORARY TABLE temp_duplicate_rooms AS
SELECT 
    LEAST(buyer_id, seller_id) as user1,
    GREATEST(buyer_id, seller_id) as user2,
    MIN(id) as keep_room_id,
    MAX(id) as merge_room_id,
    MIN(created_at) as earliest_created,
    MAX(updated_at) as latest_updated,
    SUM(total_messages) as total_msg_count,
    SUM(buyer_unread_count) as total_buyer_unread,
    SUM(seller_unread_count) as total_seller_unread
FROM chat_rooms 
GROUP BY LEAST(buyer_id, seller_id), GREATEST(buyer_id, seller_id)
HAVING COUNT(*) > 1;

-- 3. 备份重复的聊天室数据
CREATE TABLE chat_rooms_duplicate_backup AS
SELECT cr.* 
FROM chat_rooms cr
INNER JOIN temp_duplicate_rooms tdr ON cr.id = tdr.merge_room_id;

-- 4. 备份需要迁移的消息
CREATE TABLE chat_messages_migration_backup AS
SELECT cm.* 
FROM chat_messages cm
INNER JOIN temp_duplicate_rooms tdr ON cm.chat_room_id = tdr.merge_room_id;

-- 5. 更新消息到保留的聊天室
UPDATE chat_messages cm
INNER JOIN temp_duplicate_rooms tdr ON cm.chat_room_id = tdr.merge_room_id
SET cm.chat_room_id = tdr.keep_room_id;

-- 6. 更新保留聊天室的统计信息
UPDATE chat_rooms cr
INNER JOIN temp_duplicate_rooms tdr ON cr.id = tdr.keep_room_id
SET 
    cr.total_messages = tdr.total_msg_count,
    cr.created_at = tdr.earliest_created,
    cr.updated_at = tdr.latest_updated;

-- 7. 更新未读数（需要重新计算正确的未读数）
UPDATE chat_rooms cr
INNER JOIN temp_duplicate_rooms tdr ON cr.id = tdr.keep_room_id
SET 
    cr.buyer_unread_count = (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.chat_room_id = cr.id 
        AND cm.sender_id != cr.buyer_id 
        AND cm.status != 'read'
    ),
    cr.seller_unread_count = (
        SELECT COUNT(*) 
        FROM chat_messages cm 
        WHERE cm.chat_room_id = cr.id 
        AND cm.sender_id != cr.seller_id 
        AND cm.status != 'read'
    );

-- 8. 更新最后消息信息
UPDATE chat_rooms cr
INNER JOIN temp_duplicate_rooms tdr ON cr.id = tdr.keep_room_id
INNER JOIN (
    SELECT 
        chat_room_id,
        id as last_msg_id,
        content as last_content,
        message_type as last_type,
        sender_id as last_sender_id,
        sent_at as last_time
    FROM chat_messages 
    WHERE chat_room_id IN (SELECT keep_room_id FROM temp_duplicate_rooms)
    ORDER BY sent_at DESC
    LIMIT 1
) last_msg ON last_msg.chat_room_id = cr.id
SET 
    cr.last_message_id = last_msg.last_msg_id,
    cr.last_message_content = last_msg.last_content,
    cr.last_message_type = last_msg.last_type,
    cr.last_message_sender_id = last_msg.last_sender_id,
    cr.last_message_time = last_msg.last_time;

-- 9. 删除重复的聊天室
DELETE cr FROM chat_rooms cr
INNER JOIN temp_duplicate_rooms tdr ON cr.id = tdr.merge_room_id;

-- 10. 验证清理结果
SELECT 
    'After cleanup' as status,
    LEAST(buyer_id, seller_id) as user1,
    GREATEST(buyer_id, seller_id) as user2,
    COUNT(*) as room_count
FROM chat_rooms 
GROUP BY LEAST(buyer_id, seller_id), GREATEST(buyer_id, seller_id)
HAVING COUNT(*) > 1;

-- 11. 清理临时表
DROP TEMPORARY TABLE temp_duplicate_rooms;

-- 总结报告
SELECT 
    (SELECT COUNT(*) FROM chat_rooms_duplicate_backup) as deleted_rooms,
    (SELECT COUNT(*) FROM chat_messages_migration_backup) as migrated_messages,
    (SELECT COUNT(*) FROM chat_rooms) as current_total_rooms;