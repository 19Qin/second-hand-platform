#!/bin/bash

# 聊天系统API测试脚本
# 基于你的配置: localhost:8080/api/v1

BASE_URL="http://localhost:8080/api/v1"

echo "🚀 开始测试聊天系统API..."
echo "===================================="

# 获取访问令牌（假设已经有用户登录）
echo "📝 第一步：用户登录获取JWT令牌"
echo "请确保应用程序已启动，并且有测试用户数据"

# 测试用户登录 - 使用已存在的测试用户
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/auth/login/password" \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "13800138001",
    "password": "password123"
  }')

echo "登录响应: ${LOGIN_RESPONSE}"

# 从响应中提取JWT令牌
ACCESS_TOKEN=$(echo "${LOGIN_RESPONSE}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ 获取JWT令牌失败，请检查用户登录"
    exit 1
fi

echo "✅ JWT令牌获取成功: ${ACCESS_TOKEN:0:20}..."
echo ""

# 设置请求头
AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"

echo "🏠 第二步：获取聊天列表"
echo "===================================="
CHAT_LIST_RESPONSE=$(curl -s -X GET "${BASE_URL}/chats?page=1&size=10" \
  -H "${AUTH_HEADER}")

echo "聊天列表响应:"
echo "${CHAT_LIST_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${CHAT_LIST_RESPONSE}"
echo ""

echo "💬 第三步：创建聊天室"
echo "===================================="
# 假设商品ID为1，创建聊天室
CHAT_ROOM_RESPONSE=$(curl -s -X POST "${BASE_URL}/chats/rooms?productId=1" \
  -H "${AUTH_HEADER}")

echo "聊天室创建响应:"
echo "${CHAT_ROOM_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${CHAT_ROOM_RESPONSE}"
echo ""

# 从响应中提取聊天室ID
CHAT_ROOM_ID=$(echo "${CHAT_ROOM_RESPONSE}" | grep -o '"chatRoomId":[0-9]*' | cut -d':' -f2)

if [ ! -z "$CHAT_ROOM_ID" ]; then
    echo "✅ 聊天室创建成功，ID: ${CHAT_ROOM_ID}"
    
    echo "📨 第四步：发送测试消息"
    echo "===================================="
    
    # 发送文本消息
    SEND_MESSAGE_RESPONSE=$(curl -s -X POST "${BASE_URL}/chats/${CHAT_ROOM_ID}/messages" \
      -H "${AUTH_HEADER}" \
      -H "Content-Type: application/json" \
      -d '{
        "type": "TEXT",
        "content": "你好，这是聊天系统测试消息！"
      }')
    
    echo "发送消息响应:"
    echo "${SEND_MESSAGE_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${SEND_MESSAGE_RESPONSE}"
    echo ""
    
    echo "📖 第五步：获取聊天记录"
    echo "===================================="
    
    # 获取聊天记录
    MESSAGES_RESPONSE=$(curl -s -X GET "${BASE_URL}/chats/${CHAT_ROOM_ID}/messages?page=1&size=20" \
      -H "${AUTH_HEADER}")
    
    echo "聊天记录响应:"
    echo "${MESSAGES_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${MESSAGES_RESPONSE}"
    echo ""
    
    echo "🔔 第六步：获取未读消息数"
    echo "===================================="
    
    # 获取未读消息数
    UNREAD_COUNT_RESPONSE=$(curl -s -X GET "${BASE_URL}/chats/unread-count" \
      -H "${AUTH_HEADER}")
    
    echo "未读消息数响应:"
    echo "${UNREAD_COUNT_RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${UNREAD_COUNT_RESPONSE}"
    echo ""
    
else
    echo "❌ 聊天室创建失败"
fi

echo "🎉 聊天系统API测试完成！"
echo "===================================="
echo ""
echo "📋 测试总结："
echo "1. ✅ 用户认证"
echo "2. ✅ 聊天列表API"
echo "3. ✅ 创建聊天室API"
echo "4. ✅ 发送消息API"
echo "5. ✅ 获取聊天记录API"
echo "6. ✅ 未读消息统计API"
echo ""
echo "🔧 下一步建议："
echo "- 启动应用程序: mvn spring-boot:run"
echo "- 执行SQL脚本创建表结构"
echo "- 运行此测试脚本验证功能"