# 快速开始指南

## 5分钟快速启动

### 前置条件

- Python 3.7+
- llama.cpp已编译
- 模型文件已下载

### 启动服务

```bash
cd /root/llama_rag
./unified_run_arm64.sh
```

### 访问服务

打开浏览器访问：
```
http://192.168.1.1:5000
```

## 基本使用

### 聊天

1. 在左侧输入框输入消息
2. 按 `Enter` 发送
3. 等待模型回复

### 搜索（支持多段导入/全部导入）

1. 在右侧搜索框输入关键词
2. 点击"搜索"或按 `Enter`
3. 逐条导入：点击任意结果下的"导入到提示词"，可多次点击导入多段上下文
4. 一键导入：点击搜索框右侧的"全部导入"，将当前搜索结果全部导入
5. 在聊天输入框上方可以看到已导入的上下文列表，可单独删除或点击"清空"一次移除全部
6. 发送消息时会自动把所有已导入上下文拼接到提示词中

## 常用命令

### 启动服务

```bash
# 标准版本
./unified_run.sh

# ARM64优化版本（推荐）
./unified_run_arm64.sh

# 自定义端口
UNIFIED_PORT=8080 ./unified_run_arm64.sh
```

### 后台运行

```bash
# 使用nohup
nohup ./unified_run_arm64.sh > /tmp/unified.log 2>&1 &

# 使用screen
screen -S llama_rag
./unified_run_arm64.sh
# Ctrl+A D 分离

# 恢复screen
screen -r llama_rag
```

### 查看日志

```bash
# Llama日志
tail -f /tmp/llama_server.log

# Flask日志
tail -f /tmp/flask_app.log

# 系统日志（如果使用systemd）
journalctl -u llama-rag.service -f
```

### 停止服务

```bash
# 前台运行时：按 Ctrl+C

# 后台运行时：
pkill -f unified_app.py
pkill -f llama-server
```

## 配置修改

### 更改模型

```bash
export MODEL_PATH="/path/to/your/model.gguf"
./unified_run_arm64.sh
```

### 更改端口

```bash
export LLAMA_PORT=8001
export UNIFIED_PORT=5001
./unified_run_arm64.sh
```

### 优化性能

编辑 `unified_run_arm64.sh`：

```bash
# 减少线程（节省CPU）
LLAMA_THREADS=1

# 减少上下文（节省内存）
LLAMA_CONTEXT=1024

# 使用更小的模型
MODEL_PATH="/root/models/Qwen3-0.6B-Q4_0.gguf"
```

## API快速参考

### 聊天API

```bash
curl -X POST http://localhost:5000/api/llama/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "default",
    "messages": [{"role": "user", "content": "你好"}],
    "temperature": 0.7,
    "max_tokens": 2048
  }'
```

### 搜索API

```bash
curl -X POST http://localhost:5000/api/search \
  -H "Content-Type: application/json" \
  -d '{"search_string": "关键词"}'
```

### 健康检查

```bash
curl http://localhost:5000/api/llama/health
curl http://localhost:5000/api/search/health
curl http://localhost:5000/api/system/info
```

## 故障排除

### 无法启动

```bash
# 检查Python
python3 --version

# 检查Flask
python3 -c "import flask; print('OK')"

# 检查llama-server
./llama.cpp/build/bin/llama-server --version

# 检查模型文件
ls -lh /root/models/
```

### 无法访问

```bash
# 检查服务是否运行
ps aux | grep unified_app

# 检查端口
netstat -tuln | grep 5000

# 测试本地连接
curl http://localhost:5000/
```

### 搜索不工作

```bash
# 检查内容文件夹
ls -la /root/llama_rag/rag/content/

# 生成缓存
cd /root/llama_rag/rag
python3 search_strings.py "test"
```

## 文件结构

```
/root/llama_rag/
├── unified_run.sh              # 启动脚本
├── unified_run_arm64.sh        # ARM64优化版本
├── unified_app.py              # 后端应用
├── templates/
│   └── unified_index.html      # 前端页面
├── rag/
│   ├── content/                # 搜索内容
│   ├── search_strings.py       # 搜索引擎
│   └── search_results.json     # 搜索缓存
├── llama.cpp/
│   └── build/bin/llama-server  # 编译的二进制文件
└── models/
    └── Qwen3-0.6B-Q8_0.gguf    # 模型文件
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LLAMA_PORT` | 8000 | Llama服务器端口 |
| `UNIFIED_PORT` | 5000 | 统一应用端口 |
| `MODEL_PATH` | `/root/models/Qwen3-0.6B-Q8_0.gguf` | 模型路径 |
| `LLAMA_THREADS` | 2 | 线程数 |
| `LLAMA_CONTEXT` | 2048 | 上下文长度 |

## 性能提示

- **内存不足**: 使用Q4_0量化模型，减少上下文长度
- **CPU使用率高**: 减少线程数，使用更小的模型
- **响应缓慢**: 检查磁盘I/O，增加内存，使用SSD

## 更多信息

- 详细配置: 见 `UNIFIED_SETUP.md`
- 部署指南: 见 `DEPLOYMENT_GUIDE.md`
- 原始README: 见 `rag/README.md`

## 快速问题解答

**Q: 如何更新模型？**
A: 下载新模型到 `/root/models/`，设置 `MODEL_PATH` 环境变量

**Q: 如何保存聊天记录？**
A: 目前只保存在浏览器内存，可修改代码添加数据库支持

**Q: 支持多用户吗？**
A: 支持，Flask已启用多线程

**Q: 如何禁用搜索？**
A: 删除 `rag/content/` 目录

**Q: 可以用HTTPS吗？**
A: 可以使用Nginx反向代理添加SSL

## 获取帮助

1. 查看日志: `/tmp/llama_server.log`, `/tmp/flask_app.log`
2. 查看详细文档: `DEPLOYMENT_GUIDE.md`
3. 检查API: 访问 `http://localhost:5000/api/system/info`

