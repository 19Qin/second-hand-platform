#!/bin/bash

BASE_URL="http://localhost:8080/api/v1"
TOKEN1="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMDk3Mzk0LCJleHAiOjE3NjAxMDQ1OTR9.cpoJXGajDe5lsUdfPG0g4YF2YK_L4p_ngFdVDkEmRhU"
REFRESH_TOKEN1="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwidHlwZSI6InJlZnJlc2giLCJpYXQiOjE3NjAwOTczOTUsImV4cCI6MTc2MTM5MzM5NX0.jgLC2xL3g4pAoBcac33xVauaAI3Mcc5J6srRJ3cYva8"

echo "====== API测试开始 ======"
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 认证模块测试
echo "===== 1. 认证模块测试 ====="

echo "1.1 刷新Token"
curl -s -X POST "$BASE_URL/auth/token/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN1\"}" | jq . > /tmp/test_refresh_token.json
cat /tmp/test_refresh_token.json
echo ""

# 2. 商品模块测试
echo "===== 2. 商品模块测试 ====="

echo "2.1 获取商品列表"
curl -s "$BASE_URL/products?page=1&size=5" | jq . > /tmp/test_products_list.json
cat /tmp/test_products_list.json
echo ""

echo "2.2 获取商品详情"
curl -s "$BASE_URL/products/1968947273484341200" | jq . > /tmp/test_product_detail.json
cat /tmp/test_product_detail.json
echo ""

echo "2.3 商品搜索"
curl -s "$BASE_URL/products/search?keyword=MacBook&page=1&size=10" | jq . > /tmp/test_product_search.json
cat /tmp/test_product_search.json
echo ""

echo "2.4 搜索建议"
curl -s "$BASE_URL/products/search/suggest?prefix=Mac&size=5" | jq . > /tmp/test_search_suggest.json
cat /tmp/test_search_suggest.json
echo ""

echo "2.5 收藏商品"
curl -s -X POST "$BASE_URL/products/1968947273484341200/favorite" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_favorite.json
cat /tmp/test_favorite.json
echo ""

# 3. 用户中心测试
echo "===== 3. 用户中心测试 ====="

echo "3.1 获取用户资料"
curl -s "$BASE_URL/user/profile" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_user_profile.json
cat /tmp/test_user_profile.json
echo ""

echo "3.2 获取用户收藏"
curl -s "$BASE_URL/user/favorites?page=1&size=10" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_user_favorites.json
cat /tmp/test_user_favorites.json
echo ""

echo "3.3 获取用户商品"
curl -s "$BASE_URL/user/products?page=1&size=10" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_user_products.json
cat /tmp/test_user_products.json
echo ""

# 4. 地址管理测试
echo "===== 4. 地址管理测试 ====="

echo "4.1 获取地址列表"
curl -s "$BASE_URL/user/addresses" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_addresses.json
cat /tmp/test_addresses.json
echo ""

# 5. 交易模块测试
echo "===== 5. 交易模块测试 ====="

echo "5.1 获取交易列表"
curl -s "$BASE_URL/transactions?page=1&size=10" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_transactions.json
cat /tmp/test_transactions.json
echo ""

# 6. 聊天模块测试
echo "===== 6. 聊天模块测试 ====="

echo "6.1 获取聊天列表"
curl -s "$BASE_URL/chats?page=1&size=20" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_chats.json
cat /tmp/test_chats.json
echo ""

echo "6.2 获取未读消息数"
curl -s "$BASE_URL/chats/unread-count" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_unread_count.json
cat /tmp/test_unread_count.json
echo ""

# 7. 通知模块测试
echo "===== 7. 通知模块测试 ====="

echo "7.1 获取通知列表"
curl -s "$BASE_URL/user/notifications?page=1&size=20" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_notifications.json
cat /tmp/test_notifications.json
echo ""

echo "7.2 获取未读通知数"
curl -s "$BASE_URL/user/notifications/unread-count" \
  -H "Authorization: Bearer $TOKEN1" | jq . > /tmp/test_notification_unread.json
cat /tmp/test_notification_unread.json
echo ""

echo ""
echo "====== API测试完成 ======"
echo "所有结果已保存到 /tmp/test_*.json"
