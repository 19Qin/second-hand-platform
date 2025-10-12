#!/bin/bash

OUTPUT_DIR="/Users/yit/Desktop/second-hand-platform2/api_test_results"
mkdir -p "$OUTPUT_DIR"

TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMTA3NjE5LCJleHAiOjE3NjAxMTQ4MTl9.mIUT5nXOaZumOCh87_fMbJMGdeADDg-WtT5SjDAD78Q"

echo "收集API真实响应数据..."

# 1. 健康检查
curl -s http://localhost:8080/api/v1/health | jq . > "$OUTPUT_DIR/01_health.json"
echo "✅ 01_health.json"

# 2. 商品分类
curl -s http://localhost:8080/api/v1/categories | jq . > "$OUTPUT_DIR/02_categories.json"
echo "✅ 02_categories.json"

# 3. 用户信息
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/profile | jq . > "$OUTPUT_DIR/03_user_profile.json"
echo "✅ 03_user_profile.json"

# 4. 商品列表
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/products?page=0&size=10&status=ON_SALE" | jq . > "$OUTPUT_DIR/04_products_list.json"
echo "✅ 04_products_list.json"

# 5. 商品详情
curl -s http://localhost:8080/api/v1/products/1959111623732256768 | jq . > "$OUTPUT_DIR/05_product_detail.json"
echo "✅ 05_product_detail.json"

# 6. 商品搜索
curl -s "http://localhost:8080/api/v1/products/search?keyword=MacBook&page=0&size=10" | jq . > "$OUTPUT_DIR/06_product_search.json"
echo "✅ 06_product_search.json"

# 7. 聊天列表
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats?page=0&size=20" | jq . > "$OUTPUT_DIR/07_chats_list.json"
echo "✅ 07_chats_list.json"

# 8. 未读消息数
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats/unread-count | jq . > "$OUTPUT_DIR/08_chats_unread.json"
echo "✅ 08_chats_unread.json"

# 9. 聊天消息
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/chats/1962949887999311872/messages?page=0&size=50" | jq . > "$OUTPUT_DIR/09_chat_messages.json"
echo "✅ 09_chat_messages.json"

# 10. 交易列表
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/transactions?page=0&size=10" | jq . > "$OUTPUT_DIR/10_transactions_list.json"
echo "✅ 10_transactions_list.json"

# 11. 交易详情
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/transactions/1962949904768880640 | jq . > "$OUTPUT_DIR/11_transaction_detail.json"
echo "✅ 11_transaction_detail.json"

# 12. 活跃交易
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/transactions/active | jq . > "$OUTPUT_DIR/12_transactions_active.json"
echo "✅ 12_transactions_active.json"

# 13. 收货地址列表
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/addresses | jq . > "$OUTPUT_DIR/13_addresses.json"
echo "✅ 13_addresses.json"

# 14. 收藏列表
curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080/api/v1/user/favorites?page=0&size=10&sortBy=createdAt" | jq . > "$OUTPUT_DIR/14_favorites.json"
echo "✅ 14_favorites.json"

echo ""
echo "所有响应已保存到: $OUTPUT_DIR"
echo "共收集 14 个API的真实响应数据"
