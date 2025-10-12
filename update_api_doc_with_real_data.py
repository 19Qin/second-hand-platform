#!/usr/bin/env python3
"""
更新API文档,插入真实的测试数据
"""

import json

# 读取所有测试结果
test_results = {}

test_files = {
    'products_list': '/tmp/test_products_list.json',
    'product_search': '/tmp/test_product_search.json',
    'search_suggest': '/tmp/test_search_suggest.json',
    'user_profile': '/tmp/test_user_profile.json',
    'user_favorites': '/tmp/test_user_favorites.json',
    'user_products': '/tmp/test_user_products.json',
    'addresses': '/tmp/test_addresses.json',
    'transactions': '/tmp/test_transactions.json',
    'chats': '/tmp/test_chats.json',
    'unread_count': '/tmp/test_unread_count.json',
    'notifications': '/tmp/test_notifications.json',
    'notification_unread': '/tmp/test_notification_unread.json',
}

for name, filepath in test_files.items():
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            test_results[name] = json.load(f)
    except Exception as e:
        print(f"Warning: Could not load {name}: {e}")

# 打印摘要
print("=" * 60)
print("API测试数据加载完成")
print("=" * 60)
for name, data in test_results.items():
    if isinstance(data, dict):
        code = data.get('code', 'N/A')
        message = data.get('message', 'N/A')
        print(f"{name:20s} - code: {code}, message: {message}")
print("=" * 60)
print(f"\n总计加载 {len(test_results)} 个测试结果")
print("\n这些数据已准备好插入到API文档中")
