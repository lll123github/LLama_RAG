#!/bin/bash

##############################################################################
# ARM64 OpenWrt 优化版本 - 统一的Llama + RAG搜索服务启动脚本
# 针对ARM64 OpenWrt设备优化，简洁高效
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ==================== 配置 ====================
LLAMA_PORT=${LLAMA_PORT:-8000}
UNIFIED_PORT=${UNIFIED_PORT:-5000}
MODEL_PATH=${MODEL_PATH:-"/root/models/Qwen3-VL-2B-Instruct-UD-Q4_K_XL.gguf"}
LLAMA_TEMPLATE=${LLAMA_TEMPLATE:-"/root/llama.cpp/models/templates/qwen3_nonthinking.jinja"}
LLAMA_THREADS=${LLAMA_THREADS:-4}  # ARM64设备使用2个线程
LLAMA_CONTEXT=${LLAMA_CONTEXT:-2048}  # 减少上下文长度以节省内存

LLAMA_SERVER_URL="http://localhost:${LLAMA_PORT}"

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ==================== 清理函数 ====================
cleanup() {
    log_info "清理资源..."
    [ ! -z "$LLAMA_PID" ] && kill $LLAMA_PID 2>/dev/null || true
    [ ! -z "$FLASK_PID" ] && kill $FLASK_PID 2>/dev/null || true
    sleep 1
}

trap cleanup EXIT INT TERM

# ==================== 环境检查 ====================
check_env() {
    log_info "检查环境..."
    
    # Python3
    if ! command -v python3 &> /dev/null; then
        log_err "Python3未安装"
        exit 1
    fi
    log_ok "Python3已安装"
    
    # Flask
    if ! python3 -c "import flask" 2>/dev/null; then
        log_warn "Flask未安装，正在安装..."
        pip3 install -q flask requests 2>/dev/null || {
            log_err "Flask安装失败"
            exit 1
        }
    fi
    log_ok "Flask已安装"
    
    # llama-server
    if [ ! -f "llama.cpp/build/bin/llama-server" ]; then
        log_err "llama-server未找到"
        exit 1
    fi
    log_ok "llama-server已找到"
    
    # 模型文件
    if [ ! -f "$MODEL_PATH" ]; then
        log_err "模型文件不存在: $MODEL_PATH"
        exit 1
    fi
    log_ok "模型文件已找到"
}

# ==================== 启动Llama ====================
start_llama() {
    log_info "启动Llama服务器 (端口: $LLAMA_PORT, 线程: $LLAMA_THREADS)..."
    
    ./llama.cpp/build/bin/llama-server \
        -m "$MODEL_PATH" \
        --jinja \
        -t $LLAMA_THREADS \
        --mlock \
        -c $LLAMA_CONTEXT \
        --host 0.0.0.0 \
        --port $LLAMA_PORT \
        --chat-template-file "$LLAMA_TEMPLATE" \
        --no_warmup \
        > /tmp/llama_server.log 2>&1 &
    
    LLAMA_PID=$!
    log_ok "Llama已启动 (PID: $LLAMA_PID)"
    
    # 等待启动
    log_info "等待Llama启动..."
    for i in {1..15}; do
        if curl -s "http://localhost:$LLAMA_PORT/health" > /dev/null 2>&1; then
            log_ok "Llama已就绪"
            return 0
        fi
        [ $i -lt 15 ] && sleep 1
    done
    
    log_err "Llama启动超时"
    tail -5 /tmp/llama_server.log
    exit 1
}

# ==================== 启动Flask ====================
start_flask() {
    log_info "启动Flask应用 (端口: $UNIFIED_PORT)..."
    
    export LLAMA_SERVER_URL="$LLAMA_SERVER_URL"
    export UNIFIED_PORT="$UNIFIED_PORT"
    
    python3 unified_app.py > /tmp/flask_app.log 2>&1 &
    FLASK_PID=$!
    log_ok "Flask已启动 (PID: $FLASK_PID)"
    
    # 等待启动
    log_info "等待Flask启动..."
    for i in {1..10}; do
        if curl -s "http://localhost:$UNIFIED_PORT/" > /dev/null 2>&1; then
            log_ok "Flask已就绪"
            return 0
        fi
        [ $i -lt 10 ] && sleep 1
    done
    
    log_err "Flask启动超时"
    tail -5 /tmp/flask_app.log
    exit 1
}

# ==================== 显示信息 ====================
show_info() {
    # 获取本机IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    [ -z "$LOCAL_IP" ] && LOCAL_IP="0.0.0.0"
    
    echo ""
    log_ok "所有服务已启动"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "访问地址: http://${LOCAL_IP}:${UNIFIED_PORT}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "进程信息:"
    echo "  Llama (PID: $LLAMA_PID)"
    echo "  Flask (PID: $FLASK_PID)"
    echo ""
    echo "日志文件:"
    echo "  /tmp/llama_server.log"
    echo "  /tmp/flask_app.log"
    echo ""
    echo "按 Ctrl+C 停止服务"
    echo ""
}

# ==================== 主函数 ====================
main() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Llama + RAG 统一服务 (ARM64 OpenWrt优化版)       ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    check_env
    echo ""
    start_llama
    echo ""
    start_flask
    echo ""
    show_info
    
    # 保持运行
    wait
}

main

