#!/bin/bash

echo "🚀 快速编译测试"
echo "=================="

cd /Users/yit/Desktop/second-hand-platform2

echo "正在编译项目..."
mvn compile -q

if [ $? -eq 0 ]; then
    echo "✅ 编译成功！SecurityConfig修复完成"
else
    echo "❌ 编译失败，需要进一步修复"
    echo ""
    echo "详细错误信息："
    mvn compile
fi

echo "=================="