# 字符串匹配搜索工具

一个完整的字符串搜索解决方案，包含后端服务和前端界面。

## 功能特性

- 🔍 **快速搜索**: 在内容文件中快速搜索字符串
- 📝 **上下文显示**: 显示匹配字符串的上下文（前后各100个字符）
- 🎨 **美观界面**: 现代化的Web界面，支持响应式设计
- 🔄 **多次查询**: 支持多次搜索，无需重启服务
- 📊 **结果统计**: 显示匹配数量和文件信息
- ✨ **高亮显示**: 自动高亮搜索结果中的匹配字符串

## 项目结构

```
.
├── app.py                 # Flask后端服务
├── search_strings.py      # 字符串匹配核心模块
├── templates/
│   └── index.html        # 前端页面
├── main.sh               # 启动脚本
├── requirements.txt      # Python依赖
└── README.md            # 本文件
```

## 安装依赖

```bash
pip install -r requirements.txt
```

或者手动安装：

```bash
pip install Flask==2.3.3 Werkzeug==2.3.7
```

## 使用方法

### 方式一：使用启动脚本（推荐）

```bash
chmod +x main.sh
./main.sh
```

脚本会自动：
1. 检查Python3和Flask是否安装
2. 启动Flask服务
3. 在默认浏览器中打开应用页面

### 方式二：手动启动

```bash
python3 app.py
```

然后在浏览器中打开：`http://localhost:5000`

## 使用说明

1. **输入搜索字符串**: 在文本框中输入要搜索的字符串
2. **点击匹配按钮**: 或按 Enter 键执行搜索
3. **查看结果**: 结果会显示在下方的展示框中
4. **多次搜索**: 可以继续输入新的搜索字符串，无需重启服务

## API接口

### 搜索接口

**请求**:
```
POST /api/search
Content-Type: application/json

{
    "search_string": "要搜索的字符串"
}
```

**响应**:
```json
{
    "success": true,
    "message": "找到 X 个匹配",
    "data": {
        "file_name.md": [
            "匹配的上下文1",
            "匹配的上下文2"
        ]
    },
    "count": 2
}
```

### 健康检查接口

**请求**:
```
GET /api/health
```

**响应**:
```json
{
    "status": "ok",
    "message": "服务运行正常"
}
```

## 配置说明

在 `search_strings.py` 中可以修改以下参数：

- `content_dir`: 内容文件夹路径（默认为 `@content` 或 `content`）
- `context_length`: 上下文长度，单位为字符数（默认为 100）

## 文件要求

搜索工具会在指定的内容文件夹中查找以下文件类型：
- `.md` (Markdown文件)
- `.txt` (文本文件)

## 浏览器兼容性

- Chrome/Edge (推荐)
- Firefox
- Safari
- 其他现代浏览器

## 工作原理

### 搜索流程

1. **缓存优先**: 首先在 `search_results.json` 中搜索
   - 快速响应（毫秒级）
   - 支持离线使用
   - 适合已经搜索过的内容

2. **实时搜索**: 如果缓存中没有结果，则在原始文件中搜索
   - 支持新的搜索词
   - 需要 `@content` 或 `content` 文件夹存在
   - 响应时间较长

### 数据来源标识

搜索结果会显示数据来源：
- 🟢 **缓存搜索** (绿色): 从 `search_results.json` 获取
- 🔵 **实时搜索** (蓝色): 从原始文件实时搜索

## 故障排除

### 问题：无法连接到服务
- 确保Flask服务已启动
- 检查端口5000是否被占用
- 尝试更改 `app.py` 中的端口号

### 问题：搜索结果为空
- 确认搜索字符串是否正确
- 检查 `search_results.json` 是否存在
- 如果需要搜索新内容，确保 `@content` 或 `content` 文件夹存在

### 问题：找不到内容文件
- 运行 `python3 diagnose.py` 诊断脚本
- 确保 `@content` 或 `content` 文件夹与 `app.py` 在同一目录或上级目录
- 检查文件夹中是否有 `.md` 或 `.txt` 文件

### 诊断工具

使用诊断脚本查看当前配置：
```bash
python3 diagnose.py
```

输出信息包括：
- 当前工作目录
- 内容文件夹位置
- 缓存搜索结果数量
- 可用的文件列表

## 许可证

MIT License
