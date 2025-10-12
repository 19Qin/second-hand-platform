#!/bin/bash

# 综合API测试脚本 - 收集所有真实响应数据
# 用于更新API文档的响应实例

BASE_URL="http://localhost:8080/api/v1"
OUTPUT_DIR="/Users/yit/Desktop/second-hand-platform2/api_test_results"
mkdir -p "$OUTPUT_DIR"

# 从登录响应中提取token
TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxOTU5MTA2MDU3OTA5NDQwNTEyIiwibW9iaWxlIjoiMTM4MDAxMzgwMDAiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYwMTA3NjE5LCJleHAiOjE3NjAxMTQ4MTl9.mIUT5nXOaZumOCh87_fMbJMGdeADDg-WtT5SjDAD78Q"

echo "========================================="
echo "  Fliliy API 完整测试 - $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo ""

# 测试计数器
total_tests=0
passed_tests=0
failed_tests=0

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local use_auth="$5"

    total_tests=$((total_tests + 1))
    echo "[$total_tests] Testing: $name"
    echo "   Method: $method $endpoint"

    local filename="${OUTPUT_DIR}/$(echo $name | sed 's/[^a-zA-Z0-9_-]/_/g').json"

    if [ "$use_auth" = "true" ]; then
        if [ "$method" = "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}${endpoint}" \
                -H "Authorization: Bearer $TOKEN")
        elif [ "$method" = "POST" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}${endpoint}" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                -d "$data")
        elif [ "$method" = "PUT" ]; then
            response=$(curl -s -w "\n%{http_code}" -X PUT "${BASE_URL}${endpoint}" \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                -d "$data")
        elif [ "$method" = "DELETE" ]; then
            response=$(curl -s -w "\n%{http_code}" -X DELETE "${BASE_URL}${endpoint}" \
                -H "Authorization: Bearer $TOKEN")
        fi
    else
        if [ "$method" = "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" -X GET "${BASE_URL}${endpoint}")
        elif [ "$method" = "POST" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "$data")
        fi
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    echo "$body" | jq . > "$filename" 2>/dev/null

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "   ✅ SUCCESS (HTTP $http_code)"
        passed_tests=$((passed_tests + 1))
    else
        echo "   ❌ FAILED (HTTP $http_code)"
        failed_tests=$((failed_tests + 1))
    fi

    echo "   Response saved to: $filename"
    echo ""
}

echo "==================== 1. 用户认证模块 ===================="
test_api "健康检查" "GET" "/health" "" "false"
test_api "获取商品分类" "GET" "/categories" "" "false"
test_api "获取当前用户信息" "GET" "/user/profile" "" "true"

echo "==================== 2. 商品管理模块 ===================="
test_api "获取商品列表" "GET" "/products?page=0&size=10" "" "false"
test_api "搜索商品" "GET" "/products/search?keyword=iPhone&page=0&size=10" "" "false"
test_api "获取商品详情" "GET" "/products/1959111623732256768" "" "false"
test_api "获取我发布的商品" "GET" "/user/products/published?page=0&size=10" "" "true"

echo "==================== 3. 聊天模块 ===================="
test_api "获取聊天列表" "GET" "/chats?page=0&size=20" "" "true"
test_api "获取聊天详情" "GET" "/chats/1962949887999311872" "" "true"
test_api "获取聊天消息" "GET" "/chats/1962949887999311872/messages?page=0&size=50" "" "true"
test_api "获取未读消息数" "GET" "/chats/unread-count" "" "true"

echo "==================== 4. 交易模块 ===================="
test_api "获取交易列表" "GET" "/transactions?page=0&size=10" "" "true"
test_api "获取交易详情" "GET" "/transactions/1962949904768880640" "" "true"
test_api "获取活跃交易" "GET" "/transactions/active" "" "true"

echo "==================== 5. 收藏模块 ===================="
test_api "获取我的收藏" "GET" "/user/favorites?page=0&size=10" "" "true"

echo "==================== 6. 地址模块 ===================="
test_api "获取收货地址列表" "GET" "/user/addresses" "" "true"

echo "==================== 7. 通知模块 ===================="
test_api "获取通知列表" "GET" "/notifications?page=0&size=20" "" "true"
test_api "获取未读通知数" "GET" "/notifications/unread-count" "" "true"

echo "==================== 8. 系统模块 ===================="
test_api "获取统计信息" "GET" "/system/statistics" "" "true"

echo ""
echo "========================================="
echo "  测试完成"
echo "========================================="
echo "总测试数: $total_tests"
echo "通过: $passed_tests ($(awk "BEGIN {printf \"%.1f\", $passed_tests/$total_tests*100}")%)"
echo "失败: $failed_tests ($(awk "BEGIN {printf \"%.1f\", $failed_tests/$total_tests*100}")%)"
echo ""
echo "所有响应已保存到: $OUTPUT_DIR"
echo "========================================="
