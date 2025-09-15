#!/bin/bash

# Fliliy二手交易平台 WebSocket功能测试脚本
# 测试WebSocket实时聊天系统的完整功能

# 颜色输出配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务配置
BASE_URL="http://localhost:8080/api/v1"
WS_URL="ws://localhost:8080/ws"

echo -e "${BLUE}🚀 开始测试Fliliy二手交易平台WebSocket功能${NC}"
echo "========================================"

# 检查服务是否运行
echo -e "${YELLOW}1. 检查服务状态...${NC}"
if curl -s "${BASE_URL}/health" > /dev/null; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
else
    echo -e "${RED}❌ 服务未运行，请先启动应用${NC}"
    echo "启动命令: mvn spring-boot:run"
    exit 1
fi

# 获取JWT令牌
echo -e "\n${YELLOW}2. 获取JWT访问令牌...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/auth/login/password" \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "13800138001",
    "password": "password123"
  }')

if [ $? -eq 0 ]; then
    JWT_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    if [ -n "$JWT_TOKEN" ]; then
        echo -e "${GREEN}✅ JWT令牌获取成功${NC}"
        echo "Token: ${JWT_TOKEN:0:20}..."
    else
        echo -e "${RED}❌ JWT令牌获取失败${NC}"
        echo "响应: $LOGIN_RESPONSE"
        exit 1
    fi
else
    echo -e "${RED}❌ 登录请求失败${NC}"
    exit 1
fi

# 创建或获取聊天室
echo -e "\n${YELLOW}3. 创建测试聊天室...${NC}"
CHATROOM_RESPONSE=$(curl -s -X POST "${BASE_URL}/chats/rooms?productId=1963907136069177344" \
  -H "Authorization: Bearer $JWT_TOKEN")

if [ $? -eq 0 ]; then
    CHAT_ROOM_ID=$(echo $CHATROOM_RESPONSE | grep -o '"chatRoomId":"[^"]*' | cut -d'"' -f4)
    if [ -n "$CHAT_ROOM_ID" ]; then
        echo -e "${GREEN}✅ 聊天室创建成功${NC}"
        echo "聊天室ID: $CHAT_ROOM_ID"
    else
        echo -e "${YELLOW}⚠️ 可能聊天室已存在，尝试获取聊天列表${NC}"
        CHATLIST_RESPONSE=$(curl -s -X GET "${BASE_URL}/chats" \
          -H "Authorization: Bearer $JWT_TOKEN")
        CHAT_ROOM_ID=$(echo $CHATLIST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        if [ -n "$CHAT_ROOM_ID" ]; then
            echo -e "${GREEN}✅ 获取到现有聊天室${NC}"
            echo "聊天室ID: $CHAT_ROOM_ID"
        else
            echo -e "${RED}❌ 无法获取聊天室ID${NC}"
            echo "响应: $CHATROOM_RESPONSE"
            exit 1
        fi
    fi
else
    echo -e "${RED}❌ 聊天室创建失败${NC}"
    exit 1
fi

# 测试HTTP聊天接口
echo -e "\n${YELLOW}4. 测试HTTP聊天接口...${NC}"

# 发送测试消息
MESSAGE_RESPONSE=$(curl -s -X POST "${BASE_URL}/chats/${CHAT_ROOM_ID}/messages" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "TEXT",
    "content": "🧪 WebSocket功能测试消息 - ' $(date '+%H:%M:%S') '"
  }')

if [ $? -eq 0 ]; then
    MESSAGE_ID=$(echo $MESSAGE_RESPONSE | grep -o '"messageId":"[^"]*' | cut -d'"' -f4)
    if [ -n "$MESSAGE_ID" ]; then
        echo -e "${GREEN}✅ HTTP消息发送成功${NC}"
        echo "消息ID: $MESSAGE_ID"
    else
        echo -e "${RED}❌ HTTP消息发送失败${NC}"
        echo "响应: $MESSAGE_RESPONSE"
    fi
else
    echo -e "${RED}❌ HTTP消息发送请求失败${NC}"
fi

# 获取聊天记录
echo -e "\n${YELLOW}5. 获取聊天记录...${NC}"
MESSAGES_RESPONSE=$(curl -s -X GET "${BASE_URL}/chats/${CHAT_ROOM_ID}/messages?page=1&size=5" \
  -H "Authorization: Bearer $JWT_TOKEN")

if [ $? -eq 0 ]; then
    MESSAGE_COUNT=$(echo $MESSAGES_RESPONSE | grep -o '"id":' | wc -l)
    echo -e "${GREEN}✅ 聊天记录获取成功${NC}"
    echo "消息数量: $MESSAGE_COUNT"
else
    echo -e "${RED}❌ 聊天记录获取失败${NC}"
    echo "响应: $MESSAGES_RESPONSE"
fi

# WebSocket连接测试信息
echo -e "\n${YELLOW}6. WebSocket连接测试说明${NC}"
echo "========================================"
echo -e "${BLUE}WebSocket服务地址:${NC} $WS_URL"
echo -e "${BLUE}JWT访问令牌:${NC} $JWT_TOKEN"
echo -e "${BLUE}聊天室ID:${NC} $CHAT_ROOM_ID"
echo ""
echo -e "${YELLOW}📋 手动WebSocket测试步骤:${NC}"
echo "1. 在浏览器中访问: http://localhost:8080/websocket-chat-client.html"
echo "2. 输入上述WebSocket服务地址和JWT令牌"
echo "3. 输入聊天室ID: $CHAT_ROOM_ID"
echo "4. 点击'连接WebSocket'按钮"
echo "5. 在聊天界面发送测试消息"
echo ""
echo -e "${YELLOW}🔗 WebSocket连接URL示例:${NC}"
echo "ws://localhost:8080/ws?token=$JWT_TOKEN"
echo ""
echo -e "${YELLOW}📡 STOMP消息端点:${NC}"
echo "• 发送消息: /app/chat/$CHAT_ROOM_ID/send"
echo "• 订阅聊天室: /topic/chat/$CHAT_ROOM_ID"
echo "• 订阅用户消息: /user/queue/messages"
echo "• 更新在线状态: /app/user/status"
echo "• 标记已读: /app/chat/$CHAT_ROOM_ID/read"

# 创建快速测试文件
echo -e "\n${YELLOW}7. 生成WebSocket快速测试文件...${NC}"
cat > /tmp/websocket-test-config.json << EOF
{
  "serverUrl": "$WS_URL",
  "jwtToken": "$JWT_TOKEN",
  "chatRoomId": "$CHAT_ROOM_ID",
  "baseUrl": "$BASE_URL",
  "testMessage": "🧪 WebSocket实时消息测试 - $(date '+%Y-%m-%d %H:%M:%S')"
}
EOF

echo -e "${GREEN}✅ 测试配置已保存到: /tmp/websocket-test-config.json${NC}"

# 性能测试建议
echo -e "\n${YELLOW}8. 性能测试建议${NC}"
echo "========================================"
echo -e "${BLUE}并发连接测试:${NC}"
echo "• 建议使用工具: Artillery, WebSocket King, wscat"
echo "• 测试场景: 100并发用户，每用户发送10条消息"
echo "• 监控指标: 连接成功率、消息延迟、内存使用"
echo ""
echo -e "${BLUE}压力测试命令示例:${NC}"
echo "# 安装wscat: npm install -g wscat"
echo "# 连接测试: wscat -c \"$WS_URL?token=$JWT_TOKEN\""
echo ""
echo -e "${BLUE}Redis连接检查:${NC}"
echo "docker exec fliliy-redis redis-cli ping"
echo "docker exec fliliy-redis redis-cli keys \"websocket:*\""

# 日志监控建议
echo -e "\n${YELLOW}9. 日志监控${NC}"
echo "========================================"
echo -e "${BLUE}关键日志关键字:${NC}"
echo "• WebSocket连接: 'WebSocket handshake'"
echo "• 消息发送: 'Received WebSocket message'"
echo "• 连接管理: 'User.*subscribed to chatRoom'"
echo "• 错误监控: 'WebSocket.*failed'"

# 完成提示
echo -e "\n${GREEN}🎉 WebSocket功能测试准备完成！${NC}"
echo "========================================"
echo -e "${BLUE}下一步操作:${NC}"
echo "1. 打开浏览器访问测试页面进行手动测试"
echo "2. 查看应用日志了解WebSocket连接详情"
echo "3. 使用Redis工具查看在线用户状态"
echo "4. 进行多用户并发测试验证系统稳定性"
echo ""
echo -e "${YELLOW}📞 技术支持:${NC}"
echo "如遇到问题，请检查:"
echo "• 应用是否正常运行 (端口8080)"
echo "• Redis服务是否可用"
echo "• JWT令牌是否有效"
echo "• 聊天室权限是否正确"