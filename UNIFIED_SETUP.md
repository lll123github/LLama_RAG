# 统一的Llama + RAG搜索服务

这是一个融合了Llama.cpp聊天功能和上下文搜索功能的统一服务。

## 功能特性

- [object Object]聊天**: 基于llama.cpp的本地大语言模型聊天
- 🔍 **上下文搜索**: 在本地文件中快速搜索相关内容
- 📚 **上下文导入**: 将搜索结果直接导入到聊天提示词中
- 🌐 **远程访问**: 支持通过IP地址访问（不需要localhost）
- ⚡ **轻量级**: 适配ARM64 OpenWrt环境

## 项目结构

```
.
├── unified_run.sh              # 启动脚本（启动所有服务）
├── unified_app.py              # 统一的Flask后端应用
├── templates/
│   └── unified_index.html      # 统一的前端页面
├── rag/
│   ├── app.py                  # 原始搜索应用（已集成到unified_app.py）
│   ├── search_strings.py       # 搜索引擎
│   ├── templates/index.html    # 原始搜索前端（已集成）
│   ├── content/                # 搜索内容文件夹
│   └── search_results.json     # 缓存的搜索结果
├── llama.cpp/                  # llama.cpp源码和编译产物
├── models/                     # 模型文件夹
└── run_llama.sh               # 原始llama启动脚本（已集成）
```

## 快速开始

### 前置要求

1. **Python 3.7+**
   ```bash
   python3 --version
   ```

2. **llama.cpp编译**
   ```bash
   cd llama.cpp
   mkdir build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   make -j$(nproc)
   cd ../..
   ```

3. **模型文件**
   - 将模型文件放在 `models/` 目录下
   - 默认使用: `Qwen3-0.6B-Q8_0.gguf`
   - 可通过环境变量 `MODEL_PATH` 修改

4. **内容文件**
   - 将要搜索的文件放在 `rag/content/` 目录下
   - 支持 `.md` 和 `.txt` 格式

### 启动服务

```bash
# 使用默认配置启动
./unified_run.sh

# 或使用自定义端口
LLAMA_PORT=8000 UNIFIED_PORT=5000 ./unified_run.sh
```

### 访问服务

启动后，在浏览器中访问：

```
http://192.168.1.1:5000
```

或使用本机IP地址（脚本会自动检测）

## 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LLAMA_PORT` | 8000 | Llama服务器端口 |
| `UNIFIED_PORT` | 5000 | 统一应用端口 |
| `MODEL_PATH` | `/root/models/Qwen3-0.6B-Q8_0.gguf` | 模型文件路径 |
| `LLAMA_TEMPLATE` | `/root/llama.cpp/models/templates/qwen3_nonthinking.jinja` | 聊天模板路径 |

### 修改配置

编辑 `unified_run.sh` 中的配置部分：

```bash
# 服务端口
LLAMA_PORT=${LLAMA_PORT:-8000}
UNIFIED_PORT=${UNIFIED_PORT:-5000}

# 模型路径
MODEL_PATH=${MODEL_PATH:-"/root/models/Qwen3-0.6B-Q8_0.gguf"}
```

## 使用指南

### 聊天功能

1. 在左侧聊天框输入消息
2. 按 `Enter` 发送，或 `Shift+Enter` 换行
3. 模型会自动回复

### 搜索功能

1. 在右侧搜索框输入关键词
2. 点击"搜索"或按 `Enter` 搜索
3. 点击搜索结果下的"导入到提示词"按钮
4. 导入的上下文会显示在聊天输入框上方
5. 发送消息时，上下文会自动包含在提示词中

### 上下文导入

- 导入的上下文会显示为绿色提示框
- 点击 `✕` 按钮可以清除已导入的上下文
- 可以多次导入不同的上下文（最后导入的会覆盖之前的）

## API接口

### 聊天API

```bash
POST /api/llama/chat
Content-Type: application/json

{
    "model": "default",
    "messages": [
        {"role": "user", "content": "你好"}
    ],
    "temperature": 0.7,
    "max_tokens": 2048
}
```

### 搜索API

```bash
POST /api/search
Content-Type: application/json

{
    "search_string": "搜索关键词"
}
```

响应格式：
```json
{
    "success": true,
    "message": "找到 5 个匹配 (来自cache)",
    "data": {
        "file1.md": ["context1", "context2"],
        "file2.txt": ["context3"]
    },
    "count": 3,
    "source": "cache"
}
```

### 健康检查

```bash
GET /api/llama/health
GET /api/search/health
GET /api/system/info
```

## 故障排除

### 无法连接到服务

1. 检查防火墙设置
2. 确认IP地址正确
3. 查看日志文件：
   ```bash
   tail -f /tmp/llama_server.log
   tail -f /tmp/flask_app.log
   ```

### Llama服务启动失败

1. 检查模型文件是否存在
2. 检查llama.cpp是否编译成功
3. 查看Llama日志：`tail -f /tmp/llama_server.log`

### 搜索功能不可用

1. 检查内容文件夹是否存在
2. 确保文件夹中有 `.md` 或 `.txt` 文件
3. 尝试手动生成搜索缓存：
   ```bash
   cd rag
   python3 search_strings.py "test"
   ```

### 响应缓慢

1. 减少模型的 `max_tokens` 参数
2. 检查系统资源使用情况
3. 考虑使用更小的模型

## OpenWrt部署

### 1. 准备环境

```bash
# SSH连接到OpenWrt设备
ssh root@192.168.1.1

# 安装必要的包
opkg update
opkg install python3 python3-pip git
pip3 install flask requests
```

### 2. 上传项目

```bash
# 在本地机器上
scp -r . root@192.168.1.1:/root/llama_rag
```

### 3. 编译llama.cpp

```bash
# 在OpenWrt设备上
cd /root/llama_rag/llama.cpp
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_PROCESSOR=aarch64
make -j$(nproc)
```

### 4. 启动服务

```bash
cd /root/llama_rag
./unified_run.sh
```

### 5. 后台运行（可选）

使用 `nohup` 或 `screen` 后台运行：

```bash
nohup ./unified_run.sh > /tmp/unified.log 2>&1 &
```

或使用 `screen`：

```bash
screen -S llama_rag
./unified_run.sh
# 按 Ctrl+A 然后 D 分离screen
```

## 性能优化

### 对于ARM64设备

1. **减少线程数**
   ```bash
   # 在unified_run.sh中修改
   -t 2  # 改为2个线程
   ```

2. **减少上下文长度**
   ```bash
   -c 2048  # 改为2048
   ```

3. **使用更小的模型**
   - 使用量化版本（Q4_0, Q5_0等）
   - 使用更小的模型（如0.5B版本）

4. **启用内存锁定**
   ```bash
   --mlock  # 已启用
   ```

## 开发说明

### 修改前端

编辑 `templates/unified_index.html`，然后刷新浏览器（Ctrl+F5）

### 修改后端

编辑 `unified_app.py`，然后重启服务：

```bash
# 停止当前服务（Ctrl+C）
# 重新启动
./unified_run.sh
```

### 添加新的搜索内容

1. 将文件放在 `rag/content/` 目录
2. 重新生成搜索缓存：
   ```bash
   cd rag
   python3 search_strings.py "test"
   ```
3. 重启服务

## 常见问题

**Q: 如何更改模型？**
A: 修改 `unified_run.sh` 中的 `MODEL_PATH` 变量，或设置环境变量：
```bash
MODEL_PATH=/path/to/your/model.gguf ./unified_run.sh
```

**Q: 如何禁用搜索功能？**
A: 搜索功能会自动检测内容文件夹，如果不存在则自动禁用。

**Q: 支持多用户并发吗？**
A: 支持。Flask应用已启用 `threaded=True`，可以处理多个并发请求。

**Q: 如何保存聊天记录？**
A: 目前聊天记录只保存在浏览器内存中。可以修改 `unified_app.py` 添加数据库支持。

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 支持

如有问题，请查看日志文件或提交Issue。

