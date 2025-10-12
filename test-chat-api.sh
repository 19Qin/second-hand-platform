#!/bin/bash

# 测试聊天消息API是否返回transactionId

echo "========================================="
echo "测试聊天消息API - 验证transactionId字段"
echo "========================================="
echo ""

# 配置
BASE_URL="http://localhost:8080"
API_PATH="/chats"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查服务是否启动
echo "1. 检查服务状态..."
if curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/actuator/health" 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ 服务正在运行${NC}"
else
    echo -e "${RED}✗ 服务未启动${NC}"
    echo -e "${YELLOW}请先启动应用: mvn spring-boot:run${NC}"
    exit 1
fi

echo ""

# 提示输入测试数据
echo "2. 准备测试数据..."
echo -e "${YELLOW}请提供以下测试数据：${NC}"
echo ""

read -p "请输入Access Token: " ACCESS_TOKEN
read -p "请输入Chat Room ID: " CHAT_ROOM_ID

echo ""
echo "3. 测试获取聊天消息API..."
echo "请求URL: GET ${BASE_URL}${API_PATH}/${CHAT_ROOM_ID}/messages?page=1&size=20"
echo ""

# 发送请求
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${BASE_URL}${API_PATH}/${CHAT_ROOM_ID}/messages?page=1&size=20")

# 分离响应体和状态码
HTTP_BODY=$(echo "$RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo "HTTP状态码: $HTTP_STATUS"
echo ""

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ 请求成功${NC}"
    echo ""

    # 检查响应中是否包含transactionId
    echo "4. 验证响应数据..."
    echo ""

    # 美化JSON输出
    echo "响应数据:"
    echo "$HTTP_BODY" | python3 -m json.tool 2>/dev/null || echo "$HTTP_BODY"
    echo ""

    # 检查是否有transactionId字段
    if echo "$HTTP_BODY" | grep -q "transactionId"; then
        echo -e "${GREEN}✓✓✓ 成功！响应包含 transactionId 字段${NC}"
        echo ""

        # 提取并显示transactionId
        echo "找到的 transactionId:"
        echo "$HTTP_BODY" | grep -o '"transactionId":[0-9]*' | head -5
        echo ""

        # 检查是否有relatedProductId
        if echo "$HTTP_BODY" | grep -q "relatedProductId"; then
            echo -e "${GREEN}✓ 响应也包含 relatedProductId 字段${NC}"
        fi

        # 检查是否有inquiryType
        if echo "$HTTP_BODY" | grep -q "inquiryType"; then
            echo -e "${GREEN}✓ 响应也包含 inquiryType 字段${NC}"
        fi

        echo ""
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}     修复验证成功！${NC}"
        echo -e "${GREEN}=========================================${NC}"

    else
        echo -e "${RED}✗✗✗ 失败！响应不包含 transactionId 字段${NC}"
        echo -e "${YELLOW}可能的原因:${NC}"
        echo "1. 应用未重启（修改后需要重启）"
        echo "2. 聊天室中没有交易消息"
        echo "3. 代码修改未生效"
        exit 1
    fi

else
    echo -e "${RED}✗ 请求失败 (HTTP ${HTTP_STATUS})${NC}"
    echo ""
    echo "响应内容:"
    echo "$HTTP_BODY"
    exit 1
fi
