#!/usr/bin/env python3
"""
API 测试脚本
用于测试百度搜索API服务是否正常工作
"""

import requests
import json

def test_brave_search():
    """测试Brave搜索接口"""
    base_url = "http://localhost:25000"
    
    # 测试不带参数的请求（应该返回400错误）
    print("测试1: 不带查询参数的请求")
    try:
        response = requests.get(f"{base_url}/brave-search")
        print(f"状态码: {response.status_code}")
        print(f"响应: {response.text}\n")
    except requests.exceptions.ConnectionError:
        print("错误: 无法连接到服务器，请确保服务已启动\n")
        return False
    
    # 测试正常搜索
    print("测试2: 正常搜索请求")
    try:
        response = requests.get(f"{base_url}/brave-search?q=Python编程&count=3")
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"响应格式正确: {'web' in data and 'results' in data.get('web', {})}")
            print(f"结果数量: {len(data.get('web', {}).get('results', []))}")
            print("前2个结果:")
            for i, result in enumerate(data.get('web', {}).get('results', [])[:2], 1):
                print(f"  {i}. {result.get('title', '无标题')[:50]}...")
        else:
            print(f"响应: {response.text}")
        print()
    except Exception as e:
        print(f"测试失败: {e}\n")
        return False
    
    # 测试带更多参数的搜索
    print("测试3: 带多个参数的搜索")
    try:
        params = {
            'q': '人工智能',
            'count': 2,
            'country': 'CN'
        }
        response = requests.get(f"{base_url}/brave-search", params=params)
        print(f"状态码: {response.status_code}")
        if response.status_code == 200:
            print("搜索成功！\n")
        else:
            print(f"响应: {response.text}\n")
    except Exception as e:
        print(f"测试失败: {e}\n")
        return False
    
    return True

if __name__ == "__main__":
    print("=== 百度搜索API服务测试 ===\n")
    if test_brave_search():
        print("✅ 测试完成！服务运行正常")
    else:
        print("❌ 测试失败！请检查服务状态")