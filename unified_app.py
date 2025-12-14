#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
统一的Llama + RAG搜索服务
融合llama.cpp聊天和上下文搜索功能
支持在llama前端中集成搜索功能
"""

from flask import Flask, render_template, request, jsonify, send_from_directory
from rag.search_strings import StringMatcher
from pathlib import Path
import json
import os
import requests
from urllib.parse import urljoin

app = Flask(__name__, template_folder='templates', static_folder='static')

# 配置
LLAMA_SERVER_URL = os.environ.get('LLAMA_SERVER_URL', 'http://localhost:8000')
SEARCH_PORT = int(os.environ.get('SEARCH_PORT', '5001'))
UNIFIED_PORT = int(os.environ.get('UNIFIED_PORT', '5000'))

# 全局变量
cached_results = {}
matcher = None

def load_cached_results():
    """加载缓存的搜索结果"""
    global cached_results
    
    results_file = Path("rag/search_results.json")
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
        print("⚠ 未找到 rag/search_results.json 缓存文件")
        return False

def find_content_dir():
    """查找内容文件夹"""
    possible_paths = [
        "content",
        "@content",
        "rag/content",
        "../@content",
        "../../@content",
        os.path.expanduser("~/@content"),
    ]
    
    for path in possible_paths:
        path_obj = Path(path)
        if path_obj.exists() and (any(path_obj.glob("**/*.md")) or any(path_obj.glob("**/*.txt"))):
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
    """主页面 - 统一的llama + 搜索界面"""
    return render_template('unified_index.html')

# ==================== 搜索API ====================

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

@app.route('/api/search/health', methods=['GET'])
def search_health():
    """搜索服务健康检查"""
    cache_status = "✓ 已加载" if cached_results else "✗ 未加载"
    matcher_status = "✓ 已初始化" if matcher else "✗ 未初始化"
    
    return jsonify({
        'status': 'ok',
        'message': '搜索服务运行正常',
        'cache': {
            'status': cache_status,
            'entries': len(cached_results)
        },
        'matcher': {
            'status': matcher_status
        }
    }), 200

@app.route('/api/search/stats', methods=['GET'])
def search_stats():
    """获取搜索统计信息"""
    return jsonify({
        'cache_entries': len(cached_results),
        'cached_files': len(set(
            "_".join(k.split("_")[:-1]) if "_" in k else k 
            for k in cached_results.keys()
        )),
        'matcher_available': matcher is not None
    }), 200

# ==================== Llama API 代理 ====================

@app.route('/api/llama/chat', methods=['POST'])
def llama_chat():
    """
    代理llama聊天请求
    """
    try:
        data = request.get_json()
        
        # 转发到llama服务器
        llama_url = urljoin(LLAMA_SERVER_URL, '/v1/chat/completions')
        response = requests.post(llama_url, json=data, timeout=300)
        
        return jsonify(response.json()), response.status_code
    except requests.exceptions.ConnectionError:
        return jsonify({
            'error': 'Llama服务器连接失败',
            'message': f'无法连接到 {LLAMA_SERVER_URL}'
        }), 503
    except Exception as e:
        return jsonify({
            'error': '代理请求失败',
            'message': str(e)
        }), 500

@app.route('/api/llama/health', methods=['GET'])
def llama_health():
    """检查llama服务器健康状态"""
    try:
        llama_url = urljoin(LLAMA_SERVER_URL, '/health')
        response = requests.get(llama_url, timeout=5)
        
        if response.status_code == 200:
            return jsonify({
                'status': 'ok',
                'message': 'Llama服务器运行正常',
                'url': LLAMA_SERVER_URL
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Llama服务器响应异常',
                'url': LLAMA_SERVER_URL
            }), 503
    except requests.exceptions.ConnectionError:
        return jsonify({
            'status': 'error',
            'message': f'无法连接到Llama服务器: {LLAMA_SERVER_URL}',
            'url': LLAMA_SERVER_URL
        }), 503
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'健康检查失败: {str(e)}',
            'url': LLAMA_SERVER_URL
        }), 500

# ==================== 系统信息 ====================

@app.route('/api/system/info', methods=['GET'])
def system_info():
    """获取系统信息"""
    return jsonify({
        'service': 'unified_llama_rag',
        'version': '1.0.0',
        'llama_server': LLAMA_SERVER_URL,
        'search_enabled': matcher is not None or len(cached_results) > 0,
        'cache_entries': len(cached_results),
        'matcher_available': matcher is not None
    }), 200

if __name__ == '__main__':
    print("=" * 60)
    print("统一的Llama + RAG搜索服务启动")
    print("=" * 60)
    
    # 初始化
    load_cached_results()
    init_matcher()
    
    print("\n服务信息:")
    print(f"  访问地址: http://0.0.0.0:{UNIFIED_PORT}")
    print(f"  Llama服务器: {LLAMA_SERVER_URL}")
    print(f"  缓存条目: {len(cached_results)}")
    print(f"  匹配器: {'可用' if matcher else '不可用'}")
    print("\n按 Ctrl+C 停止服务")
    print("=" * 60)
    print()
    
    # 在0.0.0.0上监听，支持远程访问
    app.run(debug=False, host='0.0.0.0', port=UNIFIED_PORT, threaded=True)

