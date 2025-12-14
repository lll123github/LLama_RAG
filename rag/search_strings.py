#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
字符串匹配搜索工具
在@content/文件夹的.md和.txt文件中搜索指定字符串，返回匹配的上下文
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Tuple


class StringMatcher:
    """字符串匹配器"""
    
    def __init__(self, content_dir: str = "@content", context_length: int = 100):
        """
        初始化匹配器
        
        Args:
            content_dir: 内容文件夹路径
            context_length: 上下文长度（字符数）
        """
        self.content_dir = content_dir
        self.context_length = context_length
        self.results = {}
    
    def find_files(self) -> List[Path]:
        """查找所有.md和.txt文件"""
        files = []
        content_path = Path(self.content_dir)
        
        if not content_path.exists():
            print(f"警告: 文件夹 {self.content_dir} 不存在")
            return files
        
        # 递归查找所有.md和.txt文件
        for pattern in ['**/*.md', '**/*.txt']:
            files.extend(content_path.glob(pattern))
        
        return sorted(files)
    
    def get_context(self, text: str, index: int, match_len: int) -> str:
        """
        获取匹配位置的上下文（前后各self.context_length个字符）
        
        Args:
            text: 完整文本
            index: 匹配位置的起始索引
            match_len: 匹配字符串的长度
            
        Returns:
            包含上下文的字符串
        """
        # 计算上下文的起始和结束位置（前后各self.context_length个字符）
        context_start = max(0, index - self.context_length)
        context_end = min(len(text), index + match_len + self.context_length)
        
        context = text[context_start:context_end]
        return context
    
    def search(self, search_string: str) -> Dict:
        """
        在所有文件中搜索字符串
        
        Args:
            search_string: 要搜索的字符串
            
        Returns:
            包含匹配结果的字典
        """
        if not search_string:
            print("错误: 搜索字符串不能为空")
            return {}
        
        results = {}
        files = self.find_files()
        
        if not files:
            print(f"未找到任何.md或.txt文件在 {self.content_dir}")
            return results
        
        print(f"正在搜索 {len(files)} 个文件中的字符串: '{search_string}'")
        print("-" * 60)
        
        for file_path in files:
            try:
                # 读取文件内容
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 使用字符串的index方法查找所有匹配
                matches = []
                start = 0
                
                while True:
                    try:
                        index = content.index(search_string, start)
                        # 获取上下文
                        context = self.get_context(content, index, len(search_string))
                        matches.append(context)
                        start = index + 1
                    except ValueError:
                        # 没有更多匹配
                        break
                
                # 如果找到匹配，添加到结果
                if matches:
                    file_name = file_path.name
                    if file_name not in results:
                        results[file_name] = []
                    results[file_name].extend(matches)
                    print(f"✓ {file_name}: 找到 {len(matches)} 个匹配")
            
            except Exception as e:
                print(f"✗ 处理文件 {file_path.name} 时出错: {e}")
        
        print("-" * 60)
        print(f"总共找到 {sum(len(v) for v in results.values())} 个匹配")
        
        return results
    
    def to_json(self, results: Dict) -> str:
        """
        将结果转换为JSON格式
        
        Args:
            results: 搜索结果字典
            
        Returns:
            JSON格式的字符串
        """
        # 展平结果，每个匹配作为一个条目
        flattened = {}
        for file_name, contexts in results.items():
            for i, context in enumerate(contexts):
                # 使用文件名和索引作为键
                key = f"{file_name}_{i+1}" if len(contexts) > 1 else file_name
                flattened[key] = context
        
        return json.dumps(flattened, ensure_ascii=False, indent=2)


def main():
    """主函数"""
    import sys
    
    # 获取搜索字符串
    if len(sys.argv) < 2:
        search_string = input("请输入要搜索的字符串: ").strip()
    else:
        search_string = sys.argv[1]
    
    if not search_string:
        print("错误: 搜索字符串不能为空")
        return
    
    # 创建匹配器并搜索（优先使用content，如果不存在则尝试@content）
    content_dir = "content" if Path("content").exists() else "@content"
    matcher = StringMatcher(content_dir=content_dir, context_length=100)
    results = matcher.search(search_string)
    
    # 输出结果
    if results:
        json_output = matcher.to_json(results)
        print("\n搜索结果 (JSON格式):")
        print(json_output)
        
        # 保存到文件
        output_file = "search_results.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(json_output)
        print(f"\n结果已保存到 {output_file}")
    else:
        print("未找到任何匹配")


if __name__ == "__main__":
    main()

