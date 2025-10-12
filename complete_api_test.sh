#!/bin/bash

OUTPUT_DIR="/Users/yit/Desktop/second-hand-platform2/api_test_results"
mkdir -p "$OUTPUT_DIR"

TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMTA3NjE5LCJleHAiOjE3NjAxMTQ4MTl9.mIUT5nXOaZumOCh87_fMbJMGdeADDg-WtT5SjDAD78Q"

echo "============================================"
echo "  完整API测试 - 修正版"
echo "============================================"
echo ""

# 1. 健康检查
echo "✅ 01. 健康检查"
curl -s http://localhost:8080/api/v1/health | jq . > "$OUTPUT_DIR/01_health.json"

# 2. 商品分类
echo "✅ 02. 商品分类"
curl -s http://localhost:8080/api/v1/categories | jq . > "$OUTPUT_DIR/02_categories.json"

# 3. 商品列表 - 修正: 页码从1开始
echo "✅ 03. 商品列表 (ACTIVE状态)"
curl -s "http://localhost:8080/api/v1/products?page=1&size=10&status=ACTIVE" | jq . > "$OUTPUT_DIR/03_products_list.json"

# 4. 商品详情
echo "✅ 04. 商品详情"
curl -s http://localhost:8080/api/v1/products/1968947273484341248 | jq . > "$OUTPUT_DIR/04_product_detail.json"

# 5. 商品搜索
echo "✅ 05. 商品搜索"
curl -s "http://localhost:8080/api/v1/products/search?keyword=MacBook&page=1&size=10" | jq . > "$OUTPUT_DIR/05_product_search.json"

# 6. 相似商品
echo "✅ 06. 相似商品推荐"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/products/1968947273484341248/similar?limit=5" | jq . > "$OUTPUT_DIR/06_similar_products.json"

# 7. 用户资料 - 先测试看是否有后端bug
echo "⚠️  07. 用户资料 (可能有bug)"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/profile | jq . > "$OUTPUT_DIR/07_user_profile.json"

# 8. 收货地址
echo "✅ 08. 收货地址"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/addresses | jq . > "$OUTPUT_DIR/08_user_addresses.json"

# 9. 公开用户资料
echo "✅ 09. 公开用户资料"
curl -s http://localhost:8080/api/v1/user/1959106057909440512/profile | jq . > "$OUTPUT_DIR/09_public_profile.json"

# 10. 聊天列表
echo "✅ 10. 聊天列表"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats?page=1&size=20" | jq . > "$OUTPUT_DIR/10_chats_list.json"

# 11. 聊天详情
echo "✅ 11. 聊天详情"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats/1970366144393121792 | jq . > "$OUTPUT_DIR/11_chat_detail.json"

# 12. 聊天消息
echo "✅ 12. 聊天消息"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats/1970366144393121792/messages?page=1&size=50" | jq . > "$OUTPUT_DIR/12_chat_messages.json"

# 13. 未读消息数
echo "✅ 13. 未读消息数"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats/unread-count | jq . > "$OUTPUT_DIR/13_chats_unread.json"

# 14. 交易列表 (所有交易)
echo "✅ 14. 交易列表"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?page=1&size=10" | jq . > "$OUTPUT_DIR/14_transactions_list.json"

# 15. 交易详情
echo "✅ 15. 交易详情"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/transactions/tx_1971547214497058816 | jq . > "$OUTPUT_DIR/15_transaction_detail.json"

# 16. 活跃交易 - 修正: 使用status参数
echo "✅ 16. 活跃交易 (PENDING+AGREED)"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?status=PENDING&page=1&size=10" | jq . > "$OUTPUT_DIR/16a_transactions_pending.json"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?status=AGREED&page=1&size=10" | jq . > "$OUTPUT_DIR/16b_transactions_agreed.json"

# 17. 历史交易
echo "✅ 17. 历史交易 (COMPLETED+CANCELLED)"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?status=COMPLETED&page=1&size=10" | jq . > "$OUTPUT_DIR/17a_transactions_completed.json"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?status=CANCELLED&page=1&size=10" | jq . > "$OUTPUT_DIR/17b_transactions_cancelled.json"

# 18. 收藏列表
echo "✅ 18. 收藏列表"
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/user/favorites?page=1&size=10&sortBy=createdAt" | jq . > "$OUTPUT_DIR/18_favorites.json"

# 19. 收藏状态
echo "✅ 19. 收藏状态"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/favorites/1968947273484341248/status | jq . > "$OUTPUT_DIR/19_favorite_status.json"

# 20. 用户评价
echo "✅ 20. 用户评价"
curl -s "http://localhost:8080/api/v1/user/1959106057909440512/ratings?page=1&size=10" | jq . > "$OUTPUT_DIR/20_user_ratings.json"

# 21. 系统配置
echo "✅ 21. 系统配置"
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/system/config | jq . > "$OUTPUT_DIR/21_system_config.json"

echo ""
echo "============================================"
echo "  测试完成！"
echo "============================================"
echo "结果保存在: $OUTPUT_DIR"
echo ""
echo "检查结果..."
for file in "$OUTPUT_DIR"/*.json; do
    filename=$(basename "$file")
    code=$(jq -r '.code // "N/A"' "$file" 2>/dev/null)
    if [ "$code" = "200" ]; then
        echo "✅ $filename"
    elif [ "$code" = "N/A" ]; then
        echo "⚠️  $filename (无code字段)"
    else
        msg=$(jq -r '.message // "未知错误"' "$file" 2>/dev/null)
        echo "❌ $filename (code: $code, msg: $msg)"
    fi
done
