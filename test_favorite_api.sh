#!/bin/bash

# 收藏功能完整测试脚本
# 测试收藏/取消收藏、查看收藏状态、获取收藏列表等功能

BASE_URL="http://localhost:8080/api/v1"
OUTPUT_DIR="favorite_test_results"
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "收藏功能测试开始"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================="
echo ""

# 测试用户信息（从数据库获取）
TEST_USER_ID="1959106057909440500"
TEST_USER_MOBILE="13800138000"
TEST_USER_PASSWORD="password123"

# 测试商品ID（从数据库获取的在售商品）
TEST_PRODUCT_ID="1968947273484341248"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 函数：打印测试结果
print_result() {
    local test_name=$1
    local result=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 函数：保存响应
save_response() {
    local filename=$1
    local content=$2
    echo "$content" > "$OUTPUT_DIR/$filename"
    echo "$content" | python3 -m json.tool 2>/dev/null || echo "$content"
}

echo "========================================="
echo "步骤1: 用户登录获取Token"
echo "========================================="

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"mobile\": \"$TEST_USER_MOBILE\",
    \"password\": \"$TEST_USER_PASSWORD\"
  }")

save_response "01_login.json" "$LOGIN_RESPONSE"

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['accessToken'])" 2>/dev/null)

if [ -n "$ACCESS_TOKEN" ]; then
    print_result "用户登录成功" "PASS"
    echo "Token: ${ACCESS_TOKEN:0:50}..."
else
    print_result "用户登录失败" "FAIL"
    echo "响应: $LOGIN_RESPONSE"
    exit 1
fi

echo ""
echo "========================================="
echo "步骤2: 获取商品详情（查看初始收藏状态）"
echo "========================================="

PRODUCT_DETAIL=$(curl -s -X GET "$BASE_URL/products/$TEST_PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "02_product_detail_before.json" "$PRODUCT_DETAIL"

INITIAL_FAVORITED=$(echo "$PRODUCT_DETAIL" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['stats']['isFavorited'])" 2>/dev/null)
INITIAL_FAVORITE_COUNT=$(echo "$PRODUCT_DETAIL" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['stats']['favoriteCount'])" 2>/dev/null)

echo "初始收藏状态: $INITIAL_FAVORITED"
echo "初始收藏数量: $INITIAL_FAVORITE_COUNT"

if [ -n "$INITIAL_FAVORITED" ]; then
    print_result "查看商品详情成功" "PASS"
else
    print_result "查看商品详情失败" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤3: 收藏商品（Toggle - 第一次）"
echo "========================================="

FAVORITE_RESPONSE=$(curl -s -X POST "$BASE_URL/products/$TEST_PRODUCT_ID/favorite" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "03_toggle_favorite_1.json" "$FAVORITE_RESPONSE"

IS_FAVORITED=$(echo "$FAVORITE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['isFavorited'])" 2>/dev/null)
FAVORITE_COUNT=$(echo "$FAVORITE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['favoriteCount'])" 2>/dev/null)

echo "收藏后状态: $IS_FAVORITED"
echo "收藏后数量: $FAVORITE_COUNT"

if [ "$IS_FAVORITED" = "True" ] || [ "$IS_FAVORITED" = "true" ]; then
    print_result "收藏商品成功" "PASS"
else
    # 如果初始已经是收藏状态，这次是取消收藏
    if [ "$INITIAL_FAVORITED" = "True" ] || [ "$INITIAL_FAVORITED" = "true" ]; then
        echo -e "${YELLOW}注意: 初始已收藏，此操作为取消收藏${NC}"
        print_result "取消收藏成功" "PASS"
    else
        print_result "收藏操作失败" "FAIL"
    fi
fi

echo ""
echo "========================================="
echo "步骤4: 取消收藏（Toggle - 第二次）"
echo "========================================="

sleep 1

UNFAVORITE_RESPONSE=$(curl -s -X POST "$BASE_URL/products/$TEST_PRODUCT_ID/favorite" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "04_toggle_favorite_2.json" "$UNFAVORITE_RESPONSE"

IS_UNFAVORITED=$(echo "$UNFAVORITE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['isFavorited'])" 2>/dev/null)
UNFAVORITE_COUNT=$(echo "$UNFAVORITE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['favoriteCount'])" 2>/dev/null)

echo "取消后状态: $IS_UNFAVORITED"
echo "取消后数量: $UNFAVORITE_COUNT"

if [ "$IS_UNFAVORITED" = "False" ] || [ "$IS_UNFAVORITED" = "false" ]; then
    print_result "取消收藏成功" "PASS"
else
    print_result "取消收藏操作异常" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤5: 再次收藏（确保测试数据一致）"
echo "========================================="

sleep 1

REFAVORITE_RESPONSE=$(curl -s -X POST "$BASE_URL/products/$TEST_PRODUCT_ID/favorite" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "05_refavorite.json" "$REFAVORITE_RESPONSE"

IS_REFAVORITED=$(echo "$REFAVORITE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['isFavorited'])" 2>/dev/null)

if [ "$IS_REFAVORITED" = "True" ] || [ "$IS_REFAVORITED" = "true" ]; then
    print_result "再次收藏成功" "PASS"
else
    print_result "再次收藏失败" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤6: 查询收藏状态"
echo "========================================="

FAVORITE_STATUS=$(curl -s -X GET "$BASE_URL/products/$TEST_PRODUCT_ID/favorite/status" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "06_favorite_status.json" "$FAVORITE_STATUS"

STATUS_FAVORITED=$(echo "$FAVORITE_STATUS" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['isFavorited'])" 2>/dev/null)

echo "当前收藏状态: $STATUS_FAVORITED"

if [ "$STATUS_FAVORITED" = "True" ] || [ "$STATUS_FAVORITED" = "true" ]; then
    print_result "查询收藏状态正确" "PASS"
else
    print_result "查询收藏状态错误" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤7: 获取用户收藏列表"
echo "========================================="

FAVORITES_LIST=$(curl -s -X GET "$BASE_URL/user/favorites?page=1&size=10&sort=time_desc" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "07_favorites_list.json" "$FAVORITES_LIST"

FAVORITES_COUNT=$(echo "$FAVORITES_LIST" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data['data']['content']) if 'content' in data['data'] else 0)" 2>/dev/null)

echo "收藏列表商品数量: $FAVORITES_COUNT"

if [ -n "$FAVORITES_COUNT" ] && [ "$FAVORITES_COUNT" -gt 0 ]; then
    print_result "获取收藏列表成功" "PASS"

    # 显示收藏列表详情
    echo ""
    echo "收藏商品列表:"
    echo "$FAVORITES_LIST" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    products = data['data']['content']
    for i, p in enumerate(products[:5], 1):
        print(f\"{i}. {p['title']} - ¥{p['price']} - {p['stats']['isFavorited']}\")
except:
    pass
" 2>/dev/null
else
    print_result "获取收藏列表失败或列表为空" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤8: 使用DELETE方法取消收藏"
echo "========================================="

DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/products/$TEST_PRODUCT_ID/favorite" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "08_delete_favorite.json" "$DELETE_RESPONSE"

DELETE_FAVORITED=$(echo "$DELETE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['isFavorited'])" 2>/dev/null)

echo "DELETE后状态: $DELETE_FAVORITED"

if [ "$DELETE_FAVORITED" = "False" ] || [ "$DELETE_FAVORITED" = "false" ]; then
    print_result "DELETE取消收藏成功" "PASS"
else
    print_result "DELETE取消收藏失败" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤9: 验证商品详情中的收藏状态"
echo "========================================="

FINAL_PRODUCT_DETAIL=$(curl -s -X GET "$BASE_URL/products/$TEST_PRODUCT_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

save_response "09_product_detail_after.json" "$FINAL_PRODUCT_DETAIL"

FINAL_FAVORITED=$(echo "$FINAL_PRODUCT_DETAIL" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['stats']['isFavorited'])" 2>/dev/null)

echo "最终收藏状态: $FINAL_FAVORITED"

if [ "$FINAL_FAVORITED" = "False" ] || [ "$FINAL_FAVORITED" = "false" ]; then
    print_result "商品详情收藏状态同步正确" "PASS"
else
    print_result "商品详情收藏状态同步错误" "FAIL"
fi

echo ""
echo "========================================="
echo "步骤10: 查看数据库收藏记录"
echo "========================================="

echo "正在查询数据库..."
echo "注意: 需要通过MCP或直接数据库查询验证"

echo ""
echo "=================================="
echo "测试结果汇总"
echo "=================================="
echo "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

SUCCESS_RATE=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
echo "成功率: ${SUCCESS_RATE}%"

echo ""
echo "详细测试结果已保存到: $OUTPUT_DIR/"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！收藏功能运行正常！${NC}"
    exit 0
else
    echo -e "${RED}✗ 部分测试失败，请检查详细日志${NC}"
    exit 1
fi
