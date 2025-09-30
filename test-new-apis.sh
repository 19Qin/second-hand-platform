#!/bin/bash

# 新增API接口测试脚本
# 测试地址管理、消息通知、系统配置等新增功能

BASE_URL="http://localhost:8080/api/v1"

echo "=== 新增API接口测试 ==="
echo "测试时间: $(date)"
echo

# 1. 测试系统配置API（无需认证）
echo "1. 测试系统配置API"
echo "GET $BASE_URL/system/config"
curl -s -X GET "$BASE_URL/system/config" \
  -H "Content-Type: application/json" | jq '.'
echo

echo "GET $BASE_URL/system/version"
curl -s -X GET "$BASE_URL/system/version" \
  -H "Content-Type: application/json" | jq '.'
echo

# 2. 测试健康检查
echo "2. 测试健康检查"
echo "GET $BASE_URL/health"
curl -s -X GET "$BASE_URL/health" \
  -H "Content-Type: application/json" | jq '.'
echo

# 注意：以下API需要认证token，会返回403，说明路由正常但需要登录
echo "3. 测试需要认证的API（预期返回403认证错误）"

echo "GET $BASE_URL/user/addresses"
curl -s -X GET "$BASE_URL/user/addresses" \
  -H "Content-Type: application/json" | jq '.'
echo

echo "GET $BASE_URL/user/notifications"
curl -s -X GET "$BASE_URL/user/notifications" \
  -H "Content-Type: application/json" | jq '.'
echo

echo "GET $BASE_URL/user/notifications/unread-count"
curl -s -X GET "$BASE_URL/user/notifications/unread-count" \
  -H "Content-Type: application/json" | jq '.'
echo

echo "=== 测试完成 ==="
echo "✅ 系统配置API: 应该返回配置信息"
echo "✅ 版本信息API: 应该返回版本信息"
echo "✅ 地址管理API: 应该返回403（需要认证）"
echo "✅ 通知管理API: 应该返回403（需要认证）"
echo
echo "如果以上API都有响应（200成功或403认证失败），说明新增API接口已成功实现！"