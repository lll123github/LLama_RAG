# 🤖 统一的Llama + RAG搜索服务

一个融合了Llama.cpp本地大语言模型和上下文搜索功能的统一服务，专为ARM64 OpenWrt设备优化。

## ✨ 核心特性

- **💬 本地聊天**: 基于llama.cpp的离线大语言模型，无需云服[object Object]智能搜索**: 在本地文件中快速搜索相关内容
- **📚 上下文导入**: 将搜索结果直接导入到聊天提示词
- **🌐 远程访问**: 支持通过IP地址访问，无需localhost
- **⚡ 轻量级**: 针对ARM64 OpenWrt优化，资源占用低
- **🔒 隐私保护**: 完全离线运行，数据不上传任何服务器

## 📋 快速开始

### 最简单的方式（3步）

```bash
# 1. 进入项目目录
cd /root/llama_rag

# 2. 运行启动脚本
./unified_run_arm64.sh

# 3. 打开浏览器访问
# http://192.168.1.1:5000
```

### 详细步骤

详见 [QUICK_START.md](QUICK_START.md)

## 📁 项目结构

```
.
├── unified_run.sh              # 标准启动脚本
├── unified_run_arm64.sh        # ARM64优化启动脚本 ⭐
├── unified_app.py              # 统一后端应用
├── check_deployment.sh         # 部署检查脚本
├── config.env.example          # 配置文件模板
│
├── templates/
│   └── unified_index.html      # 统一前端页面
│
├── rag/
│   ├── search_strings.py       # 搜索引擎
│   ├── content/                # 📚 搜索内容文件夹
│   └── search_results.json     # 搜索缓存
│
├── llama.cpp/                  # llama.cpp源码
│   └── build/bin/llama-server  # 编译的二进制文件
│
└── models/                     # 🤖 模型文件夹
    └── Qwen3-0.6B-Q8_0.gguf
│
├── QUICK_START.md              # 快速开始指南
├── UNIFIED_SETUP.md            # 详细配置说明
├── DEPLOYMENT_GUIDE.md         # OpenWrt部署指南
└── README_UNIFIED.md           # 本文件
```

## 🚀 启动方式

### 方式1：直接运行（前台）

```bash
./unified_run_arm64.sh
```

### 方式2：后台运行（nohup）

```bash
nohup ./unified_run_arm64.sh > /tmp/unified.log 2>&1 &
```

### 方式3：后台运行（screen）

```bash
screen -S llama_rag
./unified_run_arm64.sh
# Ctrl+A D 分离
```

### 方式4：系统服务（systemd）

```bash
sudo systemctl start llama-rag.service
sudo systemctl enable llama-rag.service
```

详见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 🌐 访问服务

启动后，在浏览器中访问：

```
http://192.168.1.1:5000
```

或使用实际的设备IP地址。

## 💻 使用指南

### 聊天功能

1. **输入消息**: 在左侧聊天框输入内容
2. **发送**: 按 `Enter` 发送，或 `Shift+Enter` 换行
3. **接收回复**: 模型会自动生成回复

### 搜索功能

1. **输入关键词**: 在右侧搜索框输入要搜索的内容
2. **执行搜索**: 点击"搜索"按钮或按 `Enter`
3. **查看结果**: 搜索结果会显示在下方
4. **导入上下文**: 点击结果下的"导入到提示词"按钮
5. **发送消息**: 已导入的上下文会自动包含在提示词中

### 上下文管理

- 导入的上下文显示为绿色提示框
- 点击 `✕` 按钮可清除已导入的上下文
- 可多次导入不同的上下文（最后导入的会覆盖之前的）

## ⚙️ 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LLAMA_PORT` | 8000 | Llama服务器端口 |
| `UNIFIED_PORT` | 5000 | 统一应用端口 |
| `MODEL_PATH` | `/root/models/Qwen3-0.6B-Q8_0.gguf` | 模型文件路径 |
| `LLAMA_THREADS` | 2 | 线程数（ARM64推荐2-4） |
| `LLAMA_CONTEXT` | 2048 | 上下文长度（推荐1024-4096） |

### 修改配置

```bash
# 方式1：环境变量
export UNIFIED_PORT=8080
./unified_run_arm64.sh

# 方式2：编辑脚本
vi unified_run_arm64.sh
# 修改 LLAMA_THREADS, LLAMA_CONTEXT 等
```

## 🔧 API接口

### 聊天API

```bash
POST /api/llama/chat
Content-Type: application/json

{
    "model": "default",
    "messages": [{"role": "user", "content": "你好"}],
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

### 健康检查

```bash
GET /api/llama/health      # Llama服务状态
GET /api/search/health     # 搜索服务状态
GET /api/system/info       # 系统信息
```

详见 [UNIFIED_SETUP.md](UNIFIED_SETUP.md)

## 📊 性能优化

### 对于ARM64设备

```bash
# 编辑 unified_run_arm64.sh

# 减少线程数（节省CPU）
LLAMA_THREADS=1

# 减少上下文长度（节省内存）
LLAMA_CONTEXT=1024

# 使用更小的模型
MODEL_PATH="/root/models/Qwen3-0.6B-Q4_0.gguf"
```

### 模型选择

| 模型 | 大小 | 内存 | 速度 | 质量 |
|------|------|------|------|------|
| Qwen3-0.6B-Q4_0 | ~200MB | ~1GB | 快 | 一般 |
| Qwen3-0.6B-Q8_0 | ~400MB | ~2GB | 中等 | 较好 |
| Qwen3-1.5B-Q4_0 | ~800MB | ~3GB | 中等 | 好 |
| Phi-3-mini-Q4_0 | ~1.5GB | ~4GB | 慢 | 很好 |

## 🐛 故障排除

### 无法启动

```bash
# 检查Python
python3 --version

# 检查依赖
python3 -c "import flask; import requests; print('OK')"

# 检查llama-server
./llama.cpp/build/bin/llama-server --version

# 查看详细日志
tail -20 /tmp/llama_server.log
tail -20 /tmp/flask_app.log
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

# 生成搜索缓存
cd /root/llama_rag/rag
python3 search_strings.py "test"
```

详见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 的故障排除部分

## 📚 文档

- **[QUICK_START.md](QUICK_START.md)** - 5分钟快速开始
- **[UNIFIED_SETUP.md](UNIFIED_SETUP.md)** - 详细功能和配置说明
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - OpenWrt部署完整指南
- **[check_deployment.sh](check_deployment.sh)** - 自动检查部署环境

## 🔍 检查部署环境

运行部署检查脚本：

```bash
./check_deployment.sh
```

这会检查：
- ✓ Python环境
- ✓ 编译工具
- ✓ 项目文件
- ✓ 模型文件
- ✓ 内容文件
- ✓ 网络配置
- ✓ 权限设置

## 🌍 OpenWrt部署

### 快速部署（5步）

```bash
# 1. SSH连接
ssh root@192.168.1.1

# 2. 安装依赖
opkg update && opkg install python3 python3-pip
pip3 install flask requests

# 3. 上传项目
scp -r . root@192.168.1.1:/root/llama_rag

# 4. 编译llama.cpp
cd /root/llama_rag/llama.cpp/build
cmake .. && make -j$(nproc)

# 5. 启动服务
cd /root/llama_rag
./unified_run_arm64.sh
```

详见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

## 🎯 常见问题

**Q: 如何更改模型？**
```bash
export MODEL_PATH="/path/to/your/model.gguf"
./unified_run_arm64.sh
```

**Q: 如何更改访问端口？**
```bash
export UNIFIED_PORT=8080
./unified_run_arm64.sh
```

**Q: 支持多用户并发吗？**
是的，Flask已启用多线程支持。

**Q: 如何禁用搜索功能？**
删除或重命名 `rag/content/` 目录。

**Q: 支持HTTPS吗？**
可以使用Nginx反向代理添加SSL支持。

**Q: 如何保存聊天记录？**
目前聊天记录只保存在浏览器内存中，可修改代码添加数据库支持。

## 📈 监控和日志

### 查看日志

```bash
# Llama日志
tail -f /tmp/llama_server.log

# Flask日志
tail -f /tmp/flask_app.log

# 系统日志（systemd）
journalctl -u llama-rag.service -f
```

### 监控性能

```bash
# 实时监控进程
watch -n 1 'ps aux | grep -E "llama|flask"'

# 监控内存
watch -n 1 'free -h'

# 监控CPU
top -b -n 1 | head -20
```

## 🔐 安全建议

1. **防火墙**: 配置防火墙只允许需要的端口
2. **认证**: 可在Nginx反向代理中添加基本认证
3. **HTTPS**: 使用SSL证书加密通信
4. **隐私**: 所有数据本地处理，不上传任何服务器

## 📦 依赖项

- Python 3.7+
- Flask 2.3+
- requests
- llama.cpp（已包含）

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

## 💬 获取帮助

1. 查看相关文档
2. 运行 `check_deployment.sh` 检查环境
3. 查看日志文件
4. 提交Issue

## 🎓 学习资源

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [OpenWrt官方文档](https://openwrt.org/docs)
- [Flask文档](https://flask.palletsprojects.com/)
- [Qwen模型](https://huggingface.co/Qwen)

## 🚀 下一步

1. ✅ 运行 `./check_deployment.sh` 检查环境
2. ✅ 根据需要编译 llama.cpp
3. ✅ 下载模型文件到 `models/` 目录
4. ✅ 添加搜索内容到 `rag/content/` 目录
5. ✅ 运行 `./unified_run_arm64.sh` 启动服务
6. ✅ 在浏览器中访问 `http://192.168.1.1:5000`

---

**祝你使用愉快！** 🎉

如有问题，请查看 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 或提交Issue。

