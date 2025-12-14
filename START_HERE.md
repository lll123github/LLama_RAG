# 🚀 从这里开始

## 快速开始 (3 步)

### 第 1 步: 启动服务
```bash
bash unified_run_fixed.sh
```

### 第 2 步: 打开浏览器
访问 **http://localhost:5000**

### 第 3 步: 开始使用
- 💬 聊天
- 📁 上传文件
- 🖼️ 粘贴图片
- 🔍 搜索上下文

---

## 遇到问题？

### 方法 1: 快速修复
```bash
bash diagnose_and_fix.sh full
```

### 方法 2: 查看指南
- 快速修复: `cat QUICK_FIX_GUIDE.md`
- 故障排除: `cat TROUBLESHOOTING.md`
- 使用说明: `cat USAGE_INSTRUCTIONS.md`

### 方法 3: 查看日志
```bash
tail -f /tmp/llama_server.log
tail -f /tmp/flask_app.log
```

---

## 📚 文档导航

| 文档 | 用途 |
|------|------|
| **QUICK_FIX_GUIDE.md** | 快速修复和功能说明 |
| **TROUBLESHOOTING.md** | 详细故障排除 |
| **USAGE_INSTRUCTIONS.md** | 详细使用说明 |
| **IMPROVEMENTS_SUMMARY.md** | 改进总结 |
| **README_IMPROVEMENTS.md** | 改进版本指南 |
| **CHECKLIST.md** | 完成检查清单 |

---

## ✨ 新增功能

### 📁 文件上传
- 支持: TXT, PDF, Markdown, Word
- 方法: 点击 "[object Object]按钮
- 效果: 文件内容自动包含在消息中

### 🖼️ 图片粘贴
- 支持: PNG, JPG, GIF, WebP
- 方法: Ctrl+V (或 Cmd+V on Mac)
- 效果: 图片信息自动包含在消息中

### ⚙️ 改进的启动脚本
- 自动环境检查
- 自动端口占用检测
- 详细的日志输出
- 更好的错误处理

###[object Object]诊断工具
```bash
bash diagnose_and_fix.sh full      # 完整诊断和修复
bash diagnose_and_fix.sh diagnose  # 仅诊断
bash diagnose_and_fix.sh fix       # 仅修复
bash diagnose_and_fix.sh test      # 仅测试
```

---

## 🎯 常见任务

### 启动服务
```bash
bash unified_run_fixed.sh
```

### 修复 HTTP 503 错误
```bash
bash diagnose_and_fix.sh full
```

### 更改端口
```bash
export LLAMA_PORT=8001
export UNIFIED_PORT=5001
bash unified_run_fixed.sh
```

### 使用不同的模型
```bash
export MODEL_PATH="/path/to/your/model.gguf"
bash unified_run_fixed.sh
```

### 优化性能 (低端设备)
```bash
export LLAMA_THREADS=1
export LLAMA_CONTEXT=1024
bash unified_run_fixed.sh
```

### 查看日志
```bash
tail -f /tmp/llama_server.log
tail -f /tmp/flask_app.log
```

---

## 📊 改进总结

✅ **HTTP 503 错误** - 已解决  
✅ **文件上传功能** - 已添加  
✅ **图片粘贴功能** - 已添加  
✅ **诊断工具** - 已创建  
✅ **详细文档** - 已编写  

---

## 💡 快速提示

1. **文件上传**: 点击 "📁 上传文件" 按钮
2. **图片粘贴**: 在输入框中按 Ctrl+V
3. **快速清空**: 点击 "清空" 按钮删除所有文件
4. **批量上传**: 可以一次选择多个文件
5. **后台运行**: `nohup bash unified_run_fixed.sh > /tmp/service.log 2>&1 &`

---

## 🆘 需要帮助？

### 快速诊断
```bash
bash diagnose_and_fix.sh full
```

### 查看快速修复指南
```bash
cat QUICK_FIX_GUIDE.md
```

### 查看故障排除指南
```bash
cat TROUBLESHOOTING.md
```

### 查看使用说明
```bash
cat USAGE_INSTRUCTIONS.md
```

---

## 🎉 现在就开始吧！

```bash
# 启动服务
bash unified_run_fixed.sh

# 打开浏览器访问
# http://localhost:5000
```

祝你使用愉快！

---

**版本**: 1.1  
**状态**: ✅ 完成  
**最后更新**: 2024-01-XX
