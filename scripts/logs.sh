#!/bin/bash

# ============================================
# Fliliy二手平台 - 日志查看脚本
# ============================================

# 进入项目目录
cd "$(dirname "$0")/.."

# 显示菜单
echo "============================================"
echo "📋 Fliliy日志查看工具"
echo "============================================"
echo ""
echo "请选择要查看的服务:"
echo "  1) 应用服务 (fliliy-app)"
echo "  2) MySQL"
echo "  3) Redis"
echo "  4) Elasticsearch"
echo "  5) RabbitMQ"
echo "  6) 所有服务"
echo "  0) 退出"
echo ""
echo -n "请输入选项 [0-6]: "

read choice

case $choice in
    1)
        echo ""
        echo "📱 应用服务日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f app
        ;;
    2)
        echo ""
        echo "🗄️  MySQL日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f mysql
        ;;
    3)
        echo ""
        echo "💾 Redis日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f redis
        ;;
    4)
        echo ""
        echo "🔍 Elasticsearch日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f elasticsearch
        ;;
    5)
        echo ""
        echo "🐰 RabbitMQ日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f rabbitmq
        ;;
    6)
        echo ""
        echo "📋 所有服务日志 (按Ctrl+C退出):"
        echo ""
        docker-compose logs -f
        ;;
    0)
        echo "退出"
        exit 0
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac
