#!/bin/bash

# ============================================
# Fliliy二手平台 - Docker停止脚本
# ============================================

set -e

echo "============================================"
echo "🛑 停止Fliliy二手平台..."
echo "============================================"
echo ""

# 进入项目目录
cd "$(dirname "$0")/.."

# 停止所有服务
echo "📦 停止所有容器..."
docker-compose down

echo ""
echo "✅ 所有服务已停止"
echo ""
echo "💡 提示:"
echo "  - 数据已保存在Docker卷中"
echo "  - 重新启动请运行: ./scripts/start.sh"
echo "  - 完全清理（包括数据）请运行: ./scripts/clean.sh"
echo ""
