#!/bin/bash

OUTPUT_DIR="/Users/yit/Desktop/second-hand-platform2/api_test_results"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMTA3NjE5LCJleHAiOjE3NjAxMTQ4MTl9.mIUT5nXOaZumOCh87_fMbJMGdeADDg-WtT5SjDAD78Q"

echo "============================================"
echo "  完整API测试 - 收集真实响应数据"
echo "============================================"
echo ""

# ==================== 1. 认证模块 ====================
echo "【1. 认证模块】"

curl -s http://localhost:8080/api/v1/health | jq . > "$OUTPUT_DIR/01_health.json"
echo "✅ 健康检查"

# ==================== 2. 商品模块 ====================
echo ""
echo "【2. 商品模块】"

curl -s http://localhost:8080/api/v1/categories | jq . > "$OUTPUT_DIR/02_categories.json"
echo "✅ 商品分类"

curl -s "http://localhost:8080/api/v1/products?page=0&size=10&status=ACTIVE" | jq . > "$OUTPUT_DIR/03_products_list.json"
echo "✅ 商品列表"

curl -s http://localhost:8080/api/v1/products/1968947273484341248 | jq . > "$OUTPUT_DIR/04_product_detail.json"
echo "✅ 商品详情"

curl -s "http://localhost:8080/api/v1/products/search?keyword=MacBook&page=0&size=10" | jq . > "$OUTPUT_DIR/05_product_search.json"
echo "✅ 商品搜索"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/products/1968947273484341248/similar?limit=5" | jq . > "$OUTPUT_DIR/06_similar_products.json"
echo "✅ 相似商品"

# ==================== 3. 用户模块 ====================
echo ""
echo "【3. 用户模块】"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/profile | jq . > "$OUTPUT_DIR/07_user_profile.json"
echo "✅ 用户资料"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/addresses | jq . > "$OUTPUT_DIR/08_user_addresses.json"
echo "✅ 收货地址"

curl -s http://localhost:8080/api/v1/user/1959106057909440512/profile | jq . > "$OUTPUT_DIR/09_public_profile.json"
echo "✅ 公开资料"

# ==================== 4. 聊天模块 ====================
echo ""
echo "【4. 聊天模块】"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats?page=1&size=20" | jq . > "$OUTPUT_DIR/10_chats_list.json"
echo "✅ 聊天列表"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats/1970366144393121792 | jq . > "$OUTPUT_DIR/11_chat_detail.json"
echo "✅ 聊天详情"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats/1970366144393121792/messages?page=1&size=50" | jq . > "$OUTPUT_DIR/12_chat_messages.json"
echo "✅ 聊天消息"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats/unread-count | jq . > "$OUTPUT_DIR/13_chats_unread.json"
echo "✅ 未读消息"

# ==================== 5. 交易模块 ====================
echo ""
echo "【5. 交易模块】"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?page=1&size=10" | jq . > "$OUTPUT_DIR/14_transactions_list.json"
echo "✅ 交易列表"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/transactions/1971547214497058816 | jq . > "$OUTPUT_DIR/15_transaction_detail.json"
echo "✅ 交易详情"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/transactions/active | jq . > "$OUTPUT_DIR/16_transactions_active.json"
echo "✅ 活跃交易"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions/history?page=1&size=10" | jq . > "$OUTPUT_DIR/17_transactions_history.json"
echo "✅ 历史交易"

# ==================== 6. 收藏模块 ====================
echo ""
echo "【6. 收藏模块】"

curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/user/favorites?page=1&size=10&sortBy=createdAt" | jq . > "$OUTPUT_DIR/18_favorites.json"
echo "✅ 收藏列表"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/favorites/1968947273484341248/status | jq . > "$OUTPUT_DIR/19_favorite_status.json"
echo "✅ 收藏状态"

# ==================== 7. 评价模块 ====================
echo ""
echo "【7. 评价模块】"

curl -s "http://localhost:8080/api/v1/user/1959106057909440512/ratings?page=1&size=10" | jq . > "$OUTPUT_DIR/20_user_ratings.json"
echo "✅ 用户评价"

# ==================== 8. 文件模块 ====================
echo ""
echo "【8. 其他模块】"

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/system/config | jq . > "$OUTPUT_DIR/21_system_config.json"
echo "✅ 系统配置"

echo ""
echo "============================================"
echo "  测试完成！共收集 21 个API响应"
echo "============================================"
echo "结果保存在: $OUTPUT_DIR"
