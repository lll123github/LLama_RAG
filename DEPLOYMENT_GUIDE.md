# OpenWrt ARM64 部署指南

本指南说明如何在ARM64 OpenWrt设备上部署和运行统一的Llama + RAG搜索服务。

## 前置条件

### 硬件要求

- **CPU**: ARM64处理器（如高通IPQ8074等）
- **内存**: 至少2GB RAM（推荐4GB+）
- **存储**: 至少5GB可用空间（用于模型和系统）

### 软件要求

- OpenWrt 21.02 或更新版本
- Python 3.7+
- 编译工具链

## 部署步骤

### 1. 准备OpenWrt环境

#### 1.1 SSH连接到设备

```bash
ssh root@192.168.1.1
```

#### 1.2 更新软件包

```bash
opkg update
opkg install python3 python3-pip git curl
```

#### 1.3 安装Python依赖

```bash
pip3 install flask requests
```

### 2. 上传项目文件

#### 2.1 从本地机器上传

```bash
# 在本地机器上执行
scp -r . root@192.168.1.1:/root/llama_rag
```

或使用rsync（更快）：

```bash
rsync -av --delete . root@192.168.1.1:/root/llama_rag/
```

#### 2.2 验证文件结构

```bash
# 在OpenWrt设备上
cd /root/llama_rag
ls -la
```

应该看到：
```
unified_run.sh
unified_run_arm64.sh
unified_app.py
templates/
rag/
llama.cpp/
models/
```

### 3. 编译llama.cpp

#### 3.1 安装编译依赖

```bash
opkg install cmake gcc g++ make
```

#### 3.2 编译

```bash
cd /root/llama_rag/llama.cpp
mkdir -p build
cd build

# 针对ARM64的编译配置
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_FLAGS="-O3 -march=armv8-a" \
    -DCMAKE_CXX_FLAGS="-O3 -march=armv8-a"

# 编译（使用所有可用CPU核心）
make -j$(nproc)
```

编译时间可能较长（10-30分钟），取决于设备性能。

#### 3.3 验证编译

```bash
ls -la bin/llama-server
```

### 4. 准备模型文件

#### 4.1 下载模型

模型文件应该放在 `/root/models/` 目录下。

推荐使用量化版本以节省空间和内存：

```bash
mkdir -p /root/models
cd /root/models

# 下载Qwen3 0.6B量化版本（约400MB）
wget https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf
```

或使用其他模型：
- Qwen3-0.6B-Q4_0.gguf（更小，约200MB）
- Qwen3-1.5B-Q4_0.gguf（更强，约800MB）
- Phi-3-mini-4k-instruct-Q4_0.gguf（轻量级）

#### 4.2 验证模型

```bash
ls -lh /root/models/
```

### 5. 准备内容文件

#### 5.1 创建内容目录

```bash
mkdir -p /root/llama_rag/rag/content
```

#### 5.2 上传内容文件

```bash
# 从本地机器上传
scp -r /path/to/your/content/* root@192.168.1.1:/root/llama_rag/rag/content/
```

支持的格式：
- `.md` (Markdown)
- `.txt` (纯文本)

#### 5.3 生成搜索缓存（可选）

```bash
cd /root/llama_rag/rag
python3 search_strings.py "test"
```

这会生成 `search_results.json` 缓存文件，加快搜索速度。

### 6. 启动服务

#### 6.1 使用ARM64优化版本（推荐）

```bash
cd /root/llama_rag
./unified_run_arm64.sh
```

#### 6.2 或使用标准版本

```bash
cd /root/llama_rag
./unified_run.sh
```

#### 6.3 验证服务启动

```bash
# 在另一个终端中
curl http://localhost:5000/
curl http://localhost:8000/health
```

### 7. 访问服务

在浏览器中打开：

```
http://192.168.1.1:5000
```

或使用设备的实际IP地址。

## 后台运行

### 方案1：使用nohup

```bash
cd /root/llama_rag
nohup ./unified_run_arm64.sh > /tmp/unified.log 2>&1 &
```

查看日志：
```bash
tail -f /tmp/unified.log
```

### 方案2：使用screen（推荐）

```bash
# 创建新的screen会话
screen -S llama_rag

# 在screen中运行
cd /root/llama_rag
./unified_run_arm64.sh

# 按 Ctrl+A 然后 D 分离screen
```

恢复screen：
```bash
screen -r llama_rag
```

### 方案3：使用systemd服务（最佳）

创建服务文件：

```bash
sudo cat > /etc/systemd/system/llama-rag.service << 'EOF'
[Unit]
Description=Llama RAG Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/llama_rag
ExecStart=/root/llama_rag/unified_run_arm64.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

启用并启动服务：

```bash
systemctl daemon-reload
systemctl enable llama-rag.service
systemctl start llama-rag.service
```

查看服务状态：

```bash
systemctl status llama-rag.service
journalctl -u llama-rag.service -f
```

## 配置优化

### 针对ARM64设备的优化

编辑 `unified_run_arm64.sh`：

```bash
# 减少线程数（节省CPU）
LLAMA_THREADS=2  # 改为1或2

# 减少上下文长度（节省内存）
LLAMA_CONTEXT=2048  # 改为1024或512

# 使用更小的模型
MODEL_PATH="/root/models/Qwen3-0.6B-Q4_0.gguf"
```

### 内存优化

如果内存不足，可以：

1. **使用更小的模型**
   ```bash
   MODEL_PATH="/root/models/Qwen3-0.6B-Q4_0.gguf"
   ```

2. **减少上下文长度**
   ```bash
   LLAMA_CONTEXT=1024
   ```

3. **禁用内存锁定**
   编辑 `unified_run_arm64.sh`，移除 `--mlock` 参数

### CPU优化

1. **减少线程数**
   ```bash
   LLAMA_THREADS=1
   ```

2. **降低优先级**
   ```bash
   nice -n 10 ./unified_run_arm64.sh
   ```

## 故障排除

### 问题1：Llama启动失败

**症状**: 看到 "Llama启动超时" 错误

**解决方案**:
```bash
# 查看详细日志
tail -20 /tmp/llama_server.log

# 检查模型文件
ls -lh /root/models/

# 检查磁盘空间
df -h

# 尝试手动启动
./llama.cpp/build/bin/llama-server -m /root/models/Qwen3-0.6B-Q8_0.gguf --host 0.0.0.0 --port 8000
```

### 问题2：Flask应用启动失败

**症状**: 看到 "Flask启动超时" 错误

**解决方案**:
```bash
# 查看详细日志
tail -20 /tmp/flask_app.log

# 检查Python依赖
python3 -c "import flask; import requests; print('OK')"

# 手动启动Flask
python3 unified_app.py
```

### 问题3：无法访问Web界面

**症状**: 浏览器无法连接到 http://192.168.1.1:5000

**解决方案**:
```bash
# 检查防火墙
ufw status
ufw allow 5000/tcp

# 检查服务是否运行
ps aux | grep unified_app

# 检查端口是否监听
netstat -tuln | grep 5000

# 尝试本地访问
curl http://localhost:5000/
```

### 问题4：搜索功能不可用

**症状**: 搜索返回 "未找到匹配结果"

**解决方案**:
```bash
# 检查内容文件夹
ls -la /root/llama_rag/rag/content/

# 生成搜索缓存
cd /root/llama_rag/rag
python3 search_strings.py "test"

# 检查缓存文件
ls -la search_results.json
```

### 问题5：内存不足

**症状**: 服务运行缓慢或经常崩溃

**解决方案**:
```bash
# 查看内存使用
free -h

# 查看进程内存
ps aux | grep llama

# 使用更小的模型或减少上下文长度
# 编辑 unified_run_arm64.sh
```

## 性能监控

### 实时监控

```bash
# 监控进程
watch -n 1 'ps aux | grep -E "llama|flask"'

# 监控内存
watch -n 1 'free -h'

# 监控CPU
top -b -n 1 | head -20
```

### 日志分析

```bash
# 查看Llama日志
tail -f /tmp/llama_server.log

# 查看Flask日志
tail -f /tmp/flask_app.log

# 查看系统日志
journalctl -f
```

## 更新和维护

### 更新项目代码

```bash
cd /root/llama_rag
git pull origin main
```

### 更新模型

```bash
# 下载新模型
wget -O /root/models/new_model.gguf https://...

# 修改配置
export MODEL_PATH="/root/models/new_model.gguf"
./unified_run_arm64.sh
```

### 清理日志

```bash
# 清理旧日志
rm /tmp/llama_server.log /tmp/flask_app.log

# 或定期清理（添加到crontab）
0 0 * * * rm /tmp/llama_server.log /tmp/flask_app.log
```

## 网络配置

### 允许远程访问

如果需要从其他网络访问，配置防火墙：

```bash
# OpenWrt防火墙
ufw allow 5000/tcp
ufw allow 8000/tcp

# 或编辑防火墙规则
vi /etc/config/firewall
```

### 反向代理（可选）

使用Nginx反向代理以获得更好的性能：

```bash
opkg install nginx

# 配置Nginx
cat > /etc/nginx/conf.d/llama.conf << 'EOF'
upstream llama_app {
    server localhost:5000;
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://llama_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# 启动Nginx
/etc/init.d/nginx start
/etc/init.d/nginx enable
```

## 备份和恢复

### 备份配置和数据

```bash
# 备份整个项目
tar -czf llama_rag_backup.tar.gz /root/llama_rag/

# 备份模型（可选，文件较大）
tar -czf models_backup.tar.gz /root/models/
```

### 恢复

```bash
# 恢复项目
tar -xzf llama_rag_backup.tar.gz -C /

# 恢复模型
tar -xzf models_backup.tar.gz -C /
```

## 常见问题

**Q: 如何更改访问端口？**
A: 设置环境变量：
```bash
UNIFIED_PORT=8080 ./unified_run_arm64.sh
```

**Q: 如何禁用搜索功能？**
A: 删除或重命名 `rag/content/` 目录。

**Q: 支持HTTPS吗？**
A: 可以使用Nginx反向代理添加SSL支持。

**Q: 如何扩展功能？**
A: 编辑 `unified_app.py` 添加新的API端点。

## 参考资源

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [OpenWrt文档](https://openwrt.org/docs/start)
- [Flask文档](https://flask.palletsprojects.com/)
- [Qwen模型](https://huggingface.co/Qwen)

## 支持

如有问题，请：
1. 查看日志文件
2. 检查故障排除部分
3. 提交Issue（如果使用Git）

