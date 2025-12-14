#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字符串匹配搜索服务
提供REST API接口，接收搜索字符串，返回JSON格式的匹配结果
支持从 search_results.json 缓存读取，或实时搜索
"""

from flask import Flask, render_template, request, jsonify
from search_strings import StringMatcher
from pathlib import Path
import json
import os

app = Flask(__name__)

# 全局变量
cached_results = {}
matcher = None

def load_cached_results():
    """加载缓存的搜索结果"""
    global cached_results
    
    results_file = Path("search_results.json")
    if results_file.exists():
        try:
            with open(results_file, "r", encoding="utf-8") as f:
                cached_results = json.load(f)
            print(f"✓ 成功加载缓存搜索结果: {len(cached_results)} 个条目")
            return True
        except Exception as e:
            print(f"✗ 加载缓存失败: {e}")
            return False
    else:
        print("⚠ 未找到 search_results.json 缓存文件")
        return False

def find_content_dir():
    """查找内容文件夹"""
    possible_paths = [
        "content",
        "@content",
        "../@content",
        "../../@content",
        os.path.expanduser("~/@content"),
    ]
    
    for path in possible_paths:
        if Path(path).exists() and any(Path(path).glob("**/*.md")) or any(Path(path).glob("**/*.txt")):
            print(f"✓ 找到内容文件夹: {path}")
            return path
    
    print("⚠ 未找到包含文件的内容文件夹")
    return None

def init_matcher():
    """初始化匹配器"""
    global matcher
    
    content_dir = find_content_dir()
    if content_dir:
        matcher = StringMatcher(content_dir=content_dir, context_length=100)
        print("✓ 匹配器初始化成功")
    else:
        print("⚠ 无法初始化匹配器（未找到内容文件夹）")
        matcher = None

def search_in_cache(search_string):
    """在缓存中搜索"""
    if not cached_results:
        return {}
    
    results = {}
    search_lower = search_string.lower()
    
    for key, context in cached_results.items():
        # 检查上下文中是否包含搜索字符串（不区分大小写）
        if search_lower in context.lower():
            # 提取文件名
            file_name = "_".join(key.split("_")[:-1]) if "_" in key else key
            
            if file_name not in results:
                results[file_name] = []
            
            results[file_name].append(context)
    
    return results

@app.route('/')
def index():
    """主页面"""
    return render_template('index.html')

@app.route('/api/search', methods=['POST'])
def search():
    """
    搜索API端点
    
    请求格式:
    {
        "search_string": "要搜索的字符串"
    }
    
    返回格式:
    {
        "success": true/false,
        "message": "提示信息",
        "data": {
            "file_name": ["context1", "context2", ...],
            ...
        },
        "count": 总匹配数,
        "source": "cache" 或 "live"
    }
    """
    try:
        # 获取请求数据
        data = request.get_json()
        search_string = data.get('search_string', '').strip()
        
        # 验证输入
        if not search_string:
            return jsonify({
                'success': False,
                'message': '搜索字符串不能为空',
                'data': {},
                'count': 0,
                'source': None
            }), 400
        
        # 优先从缓存搜索
        results = search_in_cache(search_string)
        source = "cache"
        
        # 如果缓存中没有结果，尝试实时搜索
        if not results and matcher:
            print(f"缓存中未找到 '{search_string}'，尝试实时搜索...")
            results = matcher.search(search_string)
            source = "live"
        
        # 统计匹配数
        total_count = sum(len(v) for v in results.values())
        
        return jsonify({
            'success': True,
            'message': f'找到 {total_count} 个匹配 (来自{source})',
            'data': results,
            'count': total_count,
            'source': source
        }), 200
    
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'搜索出错: {str(e)}',
            'data': {},
            'count': 0,
            'source': None
        }), 500

@app.route('/api/health', methods=['GET'])
def health():
    """健康检查端点"""
    cache_status = "✓ 已加载" if cached_results else "✗ 未加载"
    matcher_status = "✓ 已初始化" if matcher else "✗ 未初始化"
    
    return jsonify({
        'status': 'ok',
        'message': '服务运行正常',
        'cache': {
            'status': cache_status,
            'entries': len(cached_results)
        },
        'matcher': {
            'status': matcher_status
        }
    }), 200

@app.route('/api/stats', methods=['GET'])
def stats():
    """获取统计信息"""
    return jsonify({
        'cache_entries': len(cached_results),
        'cached_files': len(set(
            "_".join(k.split("_")[:-1]) if "_" in k else k 
            for k in cached_results.keys()
        )),
        'matcher_available': matcher is not None
    }), 200

if __name__ == '__main__':
    print("=" * 50)
    print("字符串匹配搜索服务启动")
    print("=" * 50)
    
    # 初始化
    load_cached_results()
    init_matcher()
    
    print("\n服务信息:")
    print(f"  访问地址: http://localhost:5001")
    print(f"  缓存条目: {len(cached_results)}")
    print(f"  匹配器: {'可用' if matcher else '不可用'}")
    print("\n按 Ctrl+C 停止服务")
    print("=" * 50)
    print()
    
    app.run(debug=True, host='localhost', port=5001)
