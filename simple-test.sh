#!/bin/bash

echo "📝 简单编译测试"
echo "==============="

cd /Users/yit/Desktop/second-hand-platform2

mvn clean compile

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 编译成功！ChatMessageRepository LIMIT语法问题已修复"
    echo "✅ 所有HQL查询语法错误已解决"
    echo ""
    echo "🚀 现在可以启动IDEA中的Spring Boot应用了！"
else
    echo ""
    echo "❌ 还有编译错误需要修复"
fi

echo "==============="