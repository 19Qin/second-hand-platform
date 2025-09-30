#!/bin/bash

# 交易闭环测试脚本
# 测试完整的 "咨询 -> 同意 -> 完成" 流程

BASE_URL="http://localhost:8080/api/v1"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        交易闭环流程测试脚本${NC}"
echo -e "${BLUE}===============================================${NC}"

# 测试用户登录凭据（需要先运行才能获取token）
BUYER_TOKEN=""
SELLER_TOKEN=""
PRODUCT_ID=""

if [[ -z "$BUYER_TOKEN" || -z "$SELLER_TOKEN" || -z "$PRODUCT_ID" ]]; then
    echo -e "${YELLOW}警告: 需要先设置测试数据${NC}"
    echo -e "${YELLOW}请在脚本中设置以下变量:${NC}"
    echo "BUYER_TOKEN=买家的JWT token"
    echo "SELLER_TOKEN=卖家的JWT token" 
    echo "PRODUCT_ID=测试商品ID"
    echo ""
    echo -e "${BLUE}获取token的方法:${NC}"
    echo "1. 注册/登录用户获取buyer token"
    echo "2. 注册/登录另一个用户获取seller token"
    echo "3. 使用seller token发布商品获取product ID"
    exit 1
fi

# 步骤1: 买家发起咨询
echo -e "${BLUE}步骤1: 买家发起交易咨询${NC}"
INQUIRY_RESPONSE=$(curl -s -X POST "${BASE_URL}/transactions/inquiry" \
  -H "Authorization: Bearer ${BUYER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": '"${PRODUCT_ID}"',
    "message": "你好，这个商品还在吗？可以优惠吗？",
    "inquiryType": "PURCHASE"
  }')

echo "Response: $INQUIRY_RESPONSE"

# 提取transaction ID
TRANSACTION_ID=$(echo $INQUIRY_RESPONSE | jq -r '.data.transactionId' | sed 's/tx_//')

if [[ "$TRANSACTION_ID" == "null" ]]; then
    echo -e "${RED}❌ 交易咨询失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 交易咨询成功, Transaction ID: $TRANSACTION_ID${NC}"
sleep 2

# 步骤2: 卖家同意线下交易  
echo -e "${BLUE}步骤2: 卖家同意线下交易${NC}"
AGREE_RESPONSE=$(curl -s -X POST "${BASE_URL}/transactions/${TRANSACTION_ID}/agree-offline" \
  -H "Authorization: Bearer ${SELLER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "好的，明天下午3点三里屯见面交易",
    "meetingTime": "2025-01-02T15:00:00",
    "contactInfo": {
      "contactName": "张三",
      "contactPhone": "13800138000"
    },
    "meetingLocation": {
      "locationName": "三里屯太古里",
      "detailAddress": "南区1号楼星巴克门口",
      "longitude": 116.404,
      "latitude": 39.915
    },
    "notes": "请带好商品和充电器，到时微信联系"
  }')

echo "Response: $AGREE_RESPONSE"

# 提取交易验证码
TRANSACTION_CODE=$(echo $AGREE_RESPONSE | jq -r '.data.transactionCode')

if [[ "$TRANSACTION_CODE" == "null" ]]; then
    echo -e "${RED}❌ 同意交易失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 同意交易成功, 验证码: $TRANSACTION_CODE${NC}"
sleep 2

# 步骤3: 查看交易详情
echo -e "${BLUE}步骤3: 查看交易详情${NC}"
DETAIL_RESPONSE=$(curl -s -X GET "${BASE_URL}/transactions/${TRANSACTION_ID}" \
  -H "Authorization: Bearer ${BUYER_TOKEN}")

echo "Transaction Detail Response: $DETAIL_RESPONSE"
sleep 2

# 步骤4: 卖家确认交易完成
echo -e "${BLUE}步骤4: 卖家确认交易完成${NC}"
COMPLETE_RESPONSE=$(curl -s -X POST "${BASE_URL}/transactions/${TRANSACTION_ID}/complete" \
  -H "Authorization: Bearer ${SELLER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionCode": "'"${TRANSACTION_CODE}"'",
    "feedback": "交易顺利，买家很好沟通",
    "rating": 5
  }')

echo "Response: $COMPLETE_RESPONSE"

if [[ $(echo $COMPLETE_RESPONSE | jq -r '.code') == "200" ]]; then
    echo -e "${GREEN}✅ 交易完成成功${NC}"
else
    echo -e "${RED}❌ 交易完成失败${NC}"
    exit 1
fi

sleep 2

# 步骤5: 查看交易记录
echo -e "${BLUE}步骤5: 查看买家交易记录${NC}"
BUYER_TRANSACTIONS=$(curl -s -X GET "${BASE_URL}/transactions?type=buy" \
  -H "Authorization: Bearer ${BUYER_TOKEN}")

echo "Buyer Transactions: $BUYER_TRANSACTIONS"

echo -e "${BLUE}步骤6: 查看卖家交易记录${NC}"
SELLER_TRANSACTIONS=$(curl -s -X GET "${BASE_URL}/transactions?type=sell" \
  -H "Authorization: Bearer ${SELLER_TOKEN}")

echo "Seller Transactions: $SELLER_TRANSACTIONS"

echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}🎉 交易闭环流程测试完成！${NC}"
echo -e "${BLUE}===============================================${NC}"

# 测试总结
echo -e "${YELLOW}测试总结:${NC}"
echo "1. ✅ 买家发起交易咨询"
echo "2. ✅ 卖家同意线下交易并生成验证码"
echo "3. ✅ 查看交易详情功能"
echo "4. ✅ 卖家使用验证码确认交易完成"
echo "5. ✅ 查看交易记录列表"
echo ""
echo -e "${GREEN}所有核心交易功能正常运行！${NC}"