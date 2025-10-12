#!/bin/bash

# ============================================
# Fliliy二手平台 - Docker重启脚本
# ============================================

set -e

echo "============================================"
echo "🔄 重启Fliliy二手平台..."
echo "============================================"
echo ""

# 进入项目目录
cd "$(dirname "$0")/.."

# 停止服务
echo "🛑 停止服务..."
docker-compose down
echo ""

# 重新启动
echo "🚀 启动服务..."
docker-compose up -d
echo ""

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10
echo ""

# 查看服务状态
echo "📊 服务状态:"
docker-compose ps
echo ""

echo "✅ 重启完成！"
echo ""
