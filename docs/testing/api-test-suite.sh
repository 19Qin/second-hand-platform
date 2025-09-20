#!/bin/bash

# API测试套件
echo "🧪 Fliliy二手平台 - API接口测试"
echo "================================="

BASE_URL="http://localhost:8080/api/v1"
ACCESS_TOKEN=""
USER_ID=""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 通用测试函数
test_api() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_code="$5"
    local headers="$6"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${BLUE}🔍 测试: $name${NC}"
    echo "   请求: $method $url"
    
    if [ -n "$data" ]; then
        echo "   数据: $data"
    fi
    
    # 构建curl命令
    local curl_cmd="curl -s -w '\n%{http_code}' -X $method"
    
    if [ -n "$headers" ]; then
        curl_cmd="$curl_cmd -H '$headers'"
    fi
    
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    curl_cmd="$curl_cmd $BASE_URL$url"
    
    # 执行请求
    response=$(eval $curl_cmd)
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    echo "   响应码: $http_code"
    echo "   响应体: $response_body"
    
    # 检查结果
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "   ${GREEN}✅ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # 提取token（如果是登录接口）
        if [[ "$name" == *"登录"* ]] && [ "$http_code" = "200" ]; then
            ACCESS_TOKEN=$(echo "$response_body" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
            USER_ID=$(echo "$response_body" | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
            echo "   🔑 已获取Token: ${ACCESS_TOKEN:0:20}..."
        fi
    else
        echo -e "   ${RED}❌ 失败 (期望: $expected_code, 实际: $http_code)${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "\n${YELLOW}📋 开始API测试...${NC}"
echo "服务地址: $BASE_URL"

# ================================
# 1. 健康检查测试
# ================================
echo -e "\n${YELLOW}=== 1. 基础健康检查 ===${NC}"

test_api "健康检查" "GET" "/health" "" "200" ""

# ================================
# 2. 用户认证测试
# ================================
echo -e "\n${YELLOW}=== 2. 用户认证系统 ===${NC}"

# 生成随机手机号
RANDOM_MOBILE="138$(date +%s | tail -c 8)"
echo "测试手机号: $RANDOM_MOBILE"

# 2.1 发送验证码
test_api "发送注册验证码" "POST" "/auth/sms/send" \
    '{"mobile":"'$RANDOM_MOBILE'","type":"register"}' "200" ""

sleep 2

# 2.2 用户注册（使用固定验证码进行测试）
echo -e "\n${BLUE}💡 提示: 请查看控制台日志获取验证码，或使用测试验证码 1234${NC}"
read -p "请输入验证码 (直接回车使用1234): " SMS_CODE
SMS_CODE=${SMS_CODE:-1234}

test_api "用户注册" "POST" "/auth/register" \
    '{"username":"测试用户'$(date +%s)'","mobile":"'$RANDOM_MOBILE'","password":"password123","confirmPassword":"password123","smsCode":"'$SMS_CODE'","smsId":"test","agreeTerms":true}' "200" ""

# 2.3 密码登录
test_api "密码登录" "POST" "/auth/login/password" \
    '{"mobile":"'$RANDOM_MOBILE'","password":"password123"}' "200" ""

# ================================
# 3. 商品分类测试
# ================================
echo -e "\n${YELLOW}=== 3. 商品分类系统 ===${NC}"

test_api "获取商品分类" "GET" "/categories" "" "200" ""

# ================================
# 4. 商品管理测试（需要认证）
# ================================
echo -e "\n${YELLOW}=== 4. 商品管理系统 ===${NC}"

if [ -n "$ACCESS_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"
    
    # 4.1 获取商品列表
    test_api "获取商品列表" "GET" "/products?page=1&size=10" "" "200" "$AUTH_HEADER"
    
    # 4.2 商品搜索
    test_api "商品搜索" "GET" "/products?keyword=手机&page=1&size=5" "" "200" "$AUTH_HEADER"
    
else
    echo -e "${RED}⚠️ 跳过商品管理测试 - 未获取到访问令牌${NC}"
fi

# ================================
# 5. 文件上传测试
# ================================
echo -e "\n${YELLOW}=== 5. 文件上传系统 ===${NC}"

# 创建一个测试文件
echo "This is a test file for upload" > test_upload.txt

if [ -n "$ACCESS_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"
    
    echo -e "\n${BLUE}🔍 测试: 文件上传${NC}"
    echo "   请求: POST /products/upload"
    
    upload_response=$(curl -s -w '\n%{http_code}' -X POST \
        -H "$AUTH_HEADER" \
        -F "file=@test_upload.txt" \
        "$BASE_URL/products/upload")
    
    upload_code=$(echo "$upload_response" | tail -n1)
    upload_body=$(echo "$upload_response" | sed '$d')
    
    echo "   响应码: $upload_code"
    echo "   响应体: $upload_body"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$upload_code" = "200" ]; then
        echo -e "   ${GREEN}✅ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "   ${RED}❌ 失败${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
else
    echo -e "${RED}⚠️ 跳过文件上传测试 - 未获取到访问令牌${NC}"
fi

# 清理测试文件
rm -f test_upload.txt

# ================================
# 6. 聊天系统测试（需要认证）
# ================================
echo -e "\n${YELLOW}=== 6. 聊天系统 ===${NC}"

if [ -n "$ACCESS_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"
    
    # 6.1 获取聊天列表
    test_api "获取聊天列表" "GET" "/chat/rooms?page=1&size=10" "" "200" "$AUTH_HEADER"
    
else
    echo -e "${RED}⚠️ 跳过聊天系统测试 - 未获取到访问令牌${NC}"
fi

# ================================
# 测试报告
# ================================
echo -e "\n${YELLOW}=================================${NC}"
echo -e "${YELLOW}📊 测试报告${NC}"
echo -e "================================="
echo "总测试数: $TOTAL_TESTS"
echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！API接口运行正常${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️ 有 $FAILED_TESTS 个测试失败，请检查相关接口${NC}"
    exit 1
fi