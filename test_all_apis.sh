#!/bin/bash

# ==============================================================================
# Fliliy二手平台 - 完整API测试脚本
# 测试时间: 2025-10-01
# 测试目标: 全面测试所有API接口
# ==============================================================================

BASE_URL="http://localhost:8080/api/v1"
LOG_FILE="api_test_full_report_$(date +%Y%m%d_%H%M%S).log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Token变量
ACCESS_TOKEN_BUYER=""
ACCESS_TOKEN_SELLER=""
REFRESH_TOKEN_BUYER=""
REFRESH_TOKEN_SELLER=""

# 测试数据ID
BUYER_ID=""
SELLER_ID=""
PRODUCT_ID=""
CHAT_ROOM_ID=""
TRANSACTION_ID=""
ADDRESS_ID=""

# ==============================================================================
# 工具函数
# ==============================================================================

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_section() {
    log "\n${BLUE}========================================${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}========================================${NC}\n"
}

log_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "${YELLOW}[测试 $TOTAL_TESTS] $1${NC}"
}

log_success() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log "${GREEN}✓ 通过: $1${NC}\n"
}

log_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log "${RED}✗ 失败: $1${NC}"
    log "${RED}  响应: $2${NC}\n"
}

log_skip() {
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    log "${YELLOW}⊘ 跳过: $1${NC}\n"
}

# JSON 提取函数
extract_json_value() {
    echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*:"\([^"]*\)".*/\1/'
}

extract_json_number() {
    echo "$1" | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9]*" | sed 's/.*:\([0-9]*\)/\1/'
}

extract_code() {
    echo "$1" | grep -o '"code"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:\([0-9]*\)/\1/'
}

# ==============================================================================
# 1. 用户认证模块测试
# ==============================================================================

test_auth_module() {
    log_section "1. 用户认证模块测试 (7个接口)"

    # 1.1 健康检查
    log_test "1.1 系统健康检查 - GET /health"
    response=$(curl -s -X GET "$BASE_URL/health")
    code=$(extract_code "$response")
    if [[ "$code" == "200" ]]; then
        log_success "系统健康检查正常"
    else
        log_fail "系统健康检查失败" "$response"
        return 1
    fi

    # 1.2 发送短信验证码（买家）
    log_test "1.2 发送短信验证码（买家） - POST /auth/sms/send"
    response=$(curl -s -X POST "$BASE_URL/auth/sms/send" \
        -H "Content-Type: application/json" \
        -d '{
            "mobile": "13800138999",
            "type": "register"
        }')
    code=$(extract_code "$response")
    SMS_ID_BUYER=$(extract_json_value "$response" "smsId")
    if [[ "$code" == "200" ]] && [[ -n "$SMS_ID_BUYER" ]]; then
        log_success "买家验证码发送成功, SMS ID: $SMS_ID_BUYER"
    else
        log_fail "买家验证码发送失败" "$response"
    fi
    sleep 2

    # 1.3 发送短信验证码（卖家）
    log_test "1.3 发送短信验证码（卖家） - POST /auth/sms/send"
    response=$(curl -s -X POST "$BASE_URL/auth/sms/send" \
        -H "Content-Type: application/json" \
        -d '{
            "mobile": "13800138000",
            "type": "login"
        }')
    code=$(extract_code "$response")
    SMS_ID_SELLER=$(extract_json_value "$response" "smsId")
    if [[ "$code" == "200" ]] && [[ -n "$SMS_ID_SELLER" ]]; then
        log_success "卖家验证码发送成功, SMS ID: $SMS_ID_SELLER"
    else
        log_fail "卖家验证码发送失败" "$response"
    fi

    # 1.4 密码登录（买家）
    log_test "1.4 密码登录（买家） - POST /auth/login/password"
    response=$(curl -s -X POST "$BASE_URL/auth/login/password" \
        -H "Content-Type: application/json" \
        -d '{
            "mobile": "13800138999",
            "password": "password123"
        }')
    code=$(extract_code "$response")
    ACCESS_TOKEN_BUYER=$(extract_json_value "$response" "accessToken")
    REFRESH_TOKEN_BUYER=$(extract_json_value "$response" "refreshToken")
    BUYER_ID=$(extract_json_value "$response" "userId")
    if [[ "$code" == "200" ]] && [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        log_success "买家登录成功, User ID: $BUYER_ID"
    else
        log_fail "买家登录失败" "$response"
        return 1
    fi

    # 1.5 密码登录（卖家）
    log_test "1.5 密码登录（卖家） - POST /auth/login/password"
    response=$(curl -s -X POST "$BASE_URL/auth/login/password" \
        -H "Content-Type: application/json" \
        -d '{
            "mobile": "13800138000",
            "password": "password123"
        }')
    code=$(extract_code "$response")
    ACCESS_TOKEN_SELLER=$(extract_json_value "$response" "accessToken")
    REFRESH_TOKEN_SELLER=$(extract_json_value "$response" "refreshToken")
    SELLER_ID=$(extract_json_value "$response" "userId")
    if [[ "$code" == "200" ]] && [[ -n "$ACCESS_TOKEN_SELLER" ]]; then
        log_success "卖家登录成功, User ID: $SELLER_ID"
    else
        log_fail "卖家登录失败" "$response"
        return 1
    fi

    # 1.6 刷新Token
    log_test "1.6 刷新Token - POST /auth/token/refresh"
    response=$(curl -s -X POST "$BASE_URL/auth/token/refresh" \
        -H "Content-Type: application/json" \
        -d "{\"refreshToken\": \"$REFRESH_TOKEN_BUYER\"}")
    code=$(extract_code "$response")
    new_access_token=$(extract_json_value "$response" "accessToken")
    if [[ "$code" == "200" ]] && [[ -n "$new_access_token" ]]; then
        ACCESS_TOKEN_BUYER="$new_access_token"
        log_success "Token刷新成功"
    else
        log_fail "Token刷新失败" "$response"
    fi

    # 1.7 验证码登录（测试）
    log_test "1.7 验证码登录测试 - POST /auth/login/sms"
    log_skip "需要真实验证码，跳过"
}

# ==============================================================================
# 2. 商品管理模块测试
# ==============================================================================

test_product_module() {
    log_section "2. 商品管理模块测试"

    # 2.1 获取商品分类
    log_test "2.1 获取商品分类 - GET /categories"
    response=$(curl -s -X GET "$BASE_URL/categories")
    code=$(extract_code "$response")
    if [[ "$code" == "200" ]]; then
        log_success "获取商品分类成功"
    else
        log_fail "获取商品分类失败" "$response"
    fi

    # 2.2 获取商品列表（无认证）
    log_test "2.2 获取商品列表 - GET /products"
    response=$(curl -s -X GET "$BASE_URL/products?page=1&size=4")
    code=$(extract_code "$response")
    if [[ "$code" == "200" ]]; then
        log_success "获取商品列表成功"
    else
        log_fail "获取商品列表失败" "$response"
    fi

    # 2.3 搜索商品
    log_test "2.3 搜索商品 - GET /products?keyword=iPhone"
    response=$(curl -s -X GET "$BASE_URL/products?keyword=iPhone&page=1&size=10")
    code=$(extract_code "$response")
    if [[ "$code" == "200" ]]; then
        log_success "搜索商品成功"
    else
        log_fail "搜索商品失败" "$response"
    fi

    # 2.4 按分类筛选商品
    log_test "2.4 按分类筛选 - GET /products?category=11"
    response=$(curl -s -X GET "$BASE_URL/products?category=11&page=1&size=10")
    code=$(extract_code "$response")
    if [[ "$code" == "200" ]]; then
        log_success "按分类筛选成功"
    else
        log_fail "按分类筛选失败" "$response"
    fi

    # 2.5 获取商品详情
    log_test "2.5 获取商品详情 - GET /products/{productId}"
    # 先获取一个商品ID
    list_response=$(curl -s -X GET "$BASE_URL/products?page=1&size=1")
    PRODUCT_ID=$(echo "$list_response" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:"\([^"]*\)".*/\1/')

    if [[ -n "$PRODUCT_ID" ]]; then
        response=$(curl -s -X GET "$BASE_URL/products/$PRODUCT_ID")
        code=$(extract_code "$response")
        if [[ "$code" == "200" ]]; then
            log_success "获取商品详情成功, Product ID: $PRODUCT_ID"
        else
            log_fail "获取商品详情失败" "$response"
        fi
    else
        log_skip "没有可用的商品ID"
    fi

    # 2.6 收藏商品
    log_test "2.6 收藏商品 - POST /products/{productId}/favorite"
    if [[ -n "$PRODUCT_ID" ]] && [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X POST "$BASE_URL/products/$PRODUCT_ID/favorite" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")
        if [[ "$code" == "200" ]]; then
            log_success "收藏商品成功"
        else
            log_fail "收藏商品失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 2.7 取消收藏商品
    log_test "2.7 取消收藏商品 - POST /products/{productId}/favorite"
    if [[ -n "$PRODUCT_ID" ]] && [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X POST "$BASE_URL/products/$PRODUCT_ID/favorite" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")
        if [[ "$code" == "200" ]]; then
            log_success "取消收藏成功"
        else
            log_fail "取消收藏失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 2.8 上传商品图片
    log_test "2.8 上传商品图片 - POST /products/upload"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]]; then
        # 创建一个测试图片
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test_image.png

        response=$(curl -s -X POST "$BASE_URL/products/upload" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER" \
            -F "file=@/tmp/test_image.png")
        code=$(extract_code "$response")
        IMAGE_URL=$(extract_json_value "$response" "url")

        if [[ "$code" == "200" ]] && [[ -n "$IMAGE_URL" ]]; then
            log_success "上传商品图片成功, URL: $IMAGE_URL"
        else
            log_fail "上传商品图片失败" "$response"
        fi
        rm -f /tmp/test_image.png
    else
        log_skip "卖家未登录"
    fi

    # 2.9 发布商品
    log_test "2.9 发布商品 - POST /products"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]] && [[ -n "$IMAGE_URL" ]]; then
        response=$(curl -s -X POST "$BASE_URL/products" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER" \
            -H "Content-Type: application/json" \
            -d "{
                \"title\": \"测试商品-$(date +%H%M%S)\",
                \"description\": \"这是一个API测试商品\",
                \"price\": 999.00,
                \"categoryId\": 11,
                \"images\": [\"$IMAGE_URL\"],
                \"condition\": \"LIKE_NEW\",
                \"location\": {
                    \"province\": \"北京市\",
                    \"city\": \"北京市\",
                    \"district\": \"朝阳区\",
                    \"detailAddress\": \"三里屯\",
                    \"longitude\": 116.404,
                    \"latitude\": 39.915
                }
            }")
        code=$(extract_code "$response")
        NEW_PRODUCT_ID=$(extract_json_value "$response" "productId")

        if [[ "$code" == "200" ]] && [[ -n "$NEW_PRODUCT_ID" ]]; then
            log_success "发布商品成功, Product ID: $NEW_PRODUCT_ID"
            PRODUCT_ID="$NEW_PRODUCT_ID"  # 更新为新商品ID
        else
            log_fail "发布商品失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi
}

# ==============================================================================
# 3. 聊天系统模块测试
# ==============================================================================

test_chat_module() {
    log_section "3. 聊天系统模块测试"

    # 3.1 开始商品讨论（买家发起）
    log_test "3.1 开始商品讨论 - POST /chats/product-discussion"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$PRODUCT_ID" ]]; then
        response=$(curl -s -X POST "$BASE_URL/chats/product-discussion" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d "{
                \"productId\": \"$PRODUCT_ID\",
                \"message\": \"你好，这个商品还在吗？\"
            }")
        code=$(extract_code "$response")
        CHAT_ROOM_ID=$(extract_json_value "$response" "chatRoomId")

        if [[ "$code" == "200" ]] && [[ -n "$CHAT_ROOM_ID" ]]; then
            log_success "开始商品讨论成功, Chat Room ID: $CHAT_ROOM_ID"
        else
            log_fail "开始商品讨论失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 3.2 获取聊天列表
    log_test "3.2 获取聊天列表 - GET /chats"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/chats?page=1&size=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取聊天列表成功"
        else
            log_fail "获取聊天列表失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 3.3 获取聊天记录
    log_test "3.3 获取聊天记录 - GET /chats/{chatRoomId}/messages"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$CHAT_ROOM_ID" ]]; then
        response=$(curl -s -X GET "$BASE_URL/chats/$CHAT_ROOM_ID/messages?page=1&size=20" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取聊天记录成功"
        else
            log_fail "获取聊天记录失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 3.4 发送消息
    log_test "3.4 发送消息 - POST /chats/{chatRoomId}/messages"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$CHAT_ROOM_ID" ]]; then
        response=$(curl -s -X POST "$BASE_URL/chats/$CHAT_ROOM_ID/messages" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d '{
                "messageType": "TEXT",
                "content": "这是一条测试消息"
            }')
        code=$(extract_code "$response")
        MESSAGE_ID=$(extract_json_value "$response" "messageId")

        if [[ "$code" == "200" ]] && [[ -n "$MESSAGE_ID" ]]; then
            log_success "发送消息成功, Message ID: $MESSAGE_ID"
        else
            log_fail "发送消息失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 3.5 标记消息已读
    log_test "3.5 标记消息已读 - POST /chats/{chatRoomId}/read"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]] && [[ -n "$CHAT_ROOM_ID" ]]; then
        response=$(curl -s -X POST "$BASE_URL/chats/$CHAT_ROOM_ID/read" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "标记消息已读成功"
        else
            log_fail "标记消息已读失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 3.6 获取未读消息数
    log_test "3.6 获取未读消息数 - GET /chats/unread-count"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/chats/unread-count" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取未读消息数成功"
        else
            log_fail "获取未读消息数失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi
}

# ==============================================================================
# 4. 交易管理模块测试
# ==============================================================================

test_transaction_module() {
    log_section "4. 交易管理模块测试"

    # 4.1 发起交易申请
    log_test "4.1 发起交易申请 - POST /transactions/request"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$CHAT_ROOM_ID" ]] && [[ -n "$PRODUCT_ID" ]]; then
        response=$(curl -s -X POST "$BASE_URL/transactions/request" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d "{
                \"chatRoomId\": $CHAT_ROOM_ID,
                \"productId\": \"$PRODUCT_ID\",
                \"message\": \"我想购买这个商品\"
            }")
        code=$(extract_code "$response")
        TRANSACTION_ID=$(extract_json_value "$response" "transactionId")

        if [[ "$code" == "200" ]] && [[ -n "$TRANSACTION_ID" ]]; then
            log_success "发起交易申请成功, Transaction ID: $TRANSACTION_ID"
        else
            log_fail "发起交易申请失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 4.2 同意交易申请
    log_test "4.2 同意交易申请 - POST /transactions/{transactionId}/respond"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]] && [[ -n "$TRANSACTION_ID" ]]; then
        response=$(curl -s -X POST "$BASE_URL/transactions/$TRANSACTION_ID/respond" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER" \
            -H "Content-Type: application/json" \
            -d '{
                "action": "AGREE"
            }')
        code=$(extract_code "$response")
        TRANSACTION_CODE=$(extract_json_value "$response" "transactionCode")

        if [[ "$code" == "200" ]] && [[ -n "$TRANSACTION_CODE" ]]; then
            log_success "同意交易申请成功, Transaction Code: $TRANSACTION_CODE"
        else
            log_fail "同意交易申请失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 4.3 获取交易记录
    log_test "4.3 获取交易记录 - GET /transactions"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/transactions?page=1&size=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取交易记录成功"
        else
            log_fail "获取交易记录失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 4.4 获取交易详情
    log_test "4.4 获取交易详情 - GET /transactions/{transactionId}"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$TRANSACTION_ID" ]]; then
        response=$(curl -s -X GET "$BASE_URL/transactions/$TRANSACTION_ID" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取交易详情成功"
        else
            log_fail "获取交易详情失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 4.5 完成交易
    log_test "4.5 完成交易 - POST /transactions/{transactionId}/complete"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]] && [[ -n "$TRANSACTION_ID" ]] && [[ -n "$TRANSACTION_CODE" ]]; then
        response=$(curl -s -X POST "$BASE_URL/transactions/$TRANSACTION_ID/complete" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER" \
            -H "Content-Type: application/json" \
            -d "{
                \"transactionCode\": \"$TRANSACTION_CODE\",
                \"rating\": 5,
                \"feedback\": \"非常好的买家！\"
            }")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "完成交易成功"
        else
            log_fail "完成交易失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi
}

# ==============================================================================
# 5. 用户中心模块测试
# ==============================================================================

test_user_module() {
    log_section "5. 用户中心模块测试"

    # 5.1 获取用户信息
    log_test "5.1 获取用户信息 - GET /user/profile"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/profile" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取用户信息成功"
        else
            log_fail "获取用户信息失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 5.2 更新用户信息
    log_test "5.2 更新用户信息 - PUT /user/profile"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X PUT "$BASE_URL/user/profile" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d '{
                "username": "API测试买家",
                "bio": "这是一个测试账号"
            }')
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "更新用户信息成功"
        else
            log_fail "更新用户信息失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 5.3 获取用户发布的商品
    log_test "5.3 获取用户发布的商品 - GET /user/products"
    if [[ -n "$ACCESS_TOKEN_SELLER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/products?page=1&size=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN_SELLER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取用户发布的商品成功"
        else
            log_fail "获取用户发布的商品失败" "$response"
        fi
    else
        log_skip "卖家未登录"
    fi

    # 5.4 获取用户收藏的商品
    log_test "5.4 获取用户收藏的商品 - GET /user/favorites"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/favorites?page=1&size=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取用户收藏的商品成功"
        else
            log_fail "获取用户收藏的商品失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi
}

# ==============================================================================
# 6. 地址管理模块测试
# ==============================================================================

test_address_module() {
    log_section "6. 地址管理模块测试"

    # 6.1 获取收货地址列表
    log_test "6.1 获取收货地址列表 - GET /user/addresses"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/addresses" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取收货地址列表成功"
        else
            log_fail "获取收货地址列表失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 6.2 添加收货地址
    log_test "6.2 添加收货地址 - POST /user/addresses"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X POST "$BASE_URL/user/addresses" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d '{
                "receiverName": "张三",
                "mobile": "13800138999",
                "province": "北京市",
                "city": "北京市",
                "district": "朝阳区",
                "detailAddress": "三里屯SOHO 5号楼1001室",
                "isDefault": true
            }')
        code=$(extract_code "$response")
        ADDRESS_ID=$(extract_json_value "$response" "addressId")

        if [[ "$code" == "200" ]] && [[ -n "$ADDRESS_ID" ]]; then
            log_success "添加收货地址成功, Address ID: $ADDRESS_ID"
        else
            log_fail "添加收货地址失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 6.3 更新收货地址
    log_test "6.3 更新收货地址 - PUT /user/addresses/{addressId}"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$ADDRESS_ID" ]]; then
        response=$(curl -s -X PUT "$BASE_URL/user/addresses/$ADDRESS_ID" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER" \
            -H "Content-Type: application/json" \
            -d '{
                "receiverName": "张三（已更新）",
                "mobile": "13800138999",
                "province": "北京市",
                "city": "北京市",
                "district": "朝阳区",
                "detailAddress": "三里屯SOHO 5号楼1002室"
            }')
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "更新收货地址成功"
        else
            log_fail "更新收货地址失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi

    # 6.4 设置默认地址
    log_test "6.4 设置默认地址 - PUT /user/addresses/{addressId}/default"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]] && [[ -n "$ADDRESS_ID" ]]; then
        response=$(curl -s -X PUT "$BASE_URL/user/addresses/$ADDRESS_ID/default" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "设置默认地址成功"
        else
            log_fail "设置默认地址失败" "$response"
        fi
    else
        log_skip "缺少必要参数"
    fi
}

# ==============================================================================
# 7. 消息通知模块测试
# ==============================================================================

test_notification_module() {
    log_section "7. 消息通知模块测试"

    # 7.1 获取消息通知
    log_test "7.1 获取消息通知 - GET /user/notifications"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/notifications?page=1&size=10" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取消息通知成功"
        else
            log_fail "获取消息通知失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 7.2 获取未读通知数量
    log_test "7.2 获取未读通知数量 - GET /user/notifications/unread-count"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X GET "$BASE_URL/user/notifications/unread-count" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "获取未读通知数量成功"
        else
            log_fail "获取未读通知数量失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi

    # 7.3 标记所有通知为已读
    log_test "7.3 标记所有通知为已读 - POST /user/notifications/read-all"
    if [[ -n "$ACCESS_TOKEN_BUYER" ]]; then
        response=$(curl -s -X POST "$BASE_URL/user/notifications/read-all" \
            -H "Authorization: Bearer $ACCESS_TOKEN_BUYER")
        code=$(extract_code "$response")

        if [[ "$code" == "200" ]]; then
            log_success "标记所有通知为已读成功"
        else
            log_fail "标记所有通知为已读失败" "$response"
        fi
    else
        log_skip "买家未登录"
    fi
}

# ==============================================================================
# 8. 系统配置模块测试
# ==============================================================================

test_system_module() {
    log_section "8. 系统配置模块测试"

    # 8.1 获取系统配置
    log_test "8.1 获取系统配置 - GET /system/config"
    response=$(curl -s -X GET "$BASE_URL/system/config")
    code=$(extract_code "$response")

    if [[ "$code" == "200" ]]; then
        log_success "获取系统配置成功"
    else
        log_fail "获取系统配置失败" "$response"
    fi

    # 8.2 获取应用版本信息
    log_test "8.2 获取应用版本信息 - GET /system/version"
    response=$(curl -s -X GET "$BASE_URL/system/version")
    code=$(extract_code "$response")

    if [[ "$code" == "200" ]]; then
        log_success "获取应用版本信息成功"
    else
        log_fail "获取应用版本信息失败" "$response"
    fi
}

# ==============================================================================
# 主测试流程
# ==============================================================================

main() {
    log_section "Fliliy二手平台 - 完整API测试开始"
    log "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log "Base URL: $BASE_URL"
    log "日志文件: $LOG_FILE\n"

    # 执行各模块测试
    test_auth_module
    test_product_module
    test_chat_module
    test_transaction_module
    test_user_module
    test_address_module
    test_notification_module
    test_system_module

    # 输出测试报告
    log_section "测试报告"
    log "总测试数: $TOTAL_TESTS"
    log "${GREEN}通过: $PASSED_TESTS${NC}"
    log "${RED}失败: $FAILED_TESTS${NC}"
    log "${YELLOW}跳过: $SKIPPED_TESTS${NC}"

    success_rate=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS / $TOTAL_TESTS) * 100}")
    log "\n成功率: ${success_rate}%"

    if [[ $FAILED_TESTS -eq 0 ]]; then
        log "\n${GREEN}🎉 所有测试通过！${NC}"
        exit 0
    else
        log "\n${RED}⚠️  有测试失败，请查看日志文件: $LOG_FILE${NC}"
        exit 1
    fi
}

# 运行主函数
main
