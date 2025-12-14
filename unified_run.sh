#!/bin/bash

##############################################################################
# 统一的Llama + RAG搜索服务启动脚本
# 功能：
#   1. 启动llama.cpp服务器
#   2. 启动统一的Flask应用（包含搜索和代理功能）
#   3. 支持通过IP地址访问（不使用localhost）
#   4. 适配ARM64 OpenWrt环境
##############################################################################

set -e

# ==================== 配置 ====================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 服务端口
LLAMA_PORT=${LLAMA_PORT:-8000}
UNIFIED_PORT=${UNIFIED_PORT:-5000}

# 模型路径
MODEL_PATH=${MODEL_PATH:-"/root/models/Qwen3-0.6B-Q8_0.gguf"}
LLAMA_TEMPLATE=${LLAMA_TEMPLATE:-"/root/llama.cpp/models/templates/qwen3_nonthinking.jinja"}

# Llama服务器地址（用于代理）
LLAMA_SERVER_URL="http://localhost:${LLAMA_PORT}"

# 获取本机IP地址（优先使用非localhost的IP）
get_local_ip() {
    # 尝试获取以太网IP
    if command -v hostname &> /dev/null; then
        local ip=$(hostname -I | awk '{print $1}')
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # 备选方案：使用ifconfig或ip命令
    if command -v ip &> /dev/null; then
        local ip=$(ip route get 1 | awk '{print $NF;exit}')
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            echo "$ip"
            return
        fi
    fi
    
    # 最后的备选方案
    echo "0.0.0.0"
}

LOCAL_IP=$(get_local_ip)

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ==================== 环境检查 ====================
check_environment() {
    print_header "环境检查"
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        print_error "未找到Python3"
        exit 1
    fi
    print_success "Python3 已安装"
    
    # 检查Flask
    if ! python3 -c "import flask" 2>/dev/null; then
        print_warning "Flask未安装，正在安装..."
        pip3 install -q flask requests
        print_success "Flask已安装"
    else
        print_success "Flask已安装"
    fi
    
    # 检查llama.cpp
    if [ ! -f "llama.cpp/build/bin/llama-server" ]; then
        print_error "未找到llama-server，请确保llama.cpp已编译"
        exit 1
    fi
    print_success "llama-server已找到"
    
    # 检查模型文件
    if [ ! -f "$MODEL_PATH" ]; then
        print_error "模型文件不存在: $MODEL_PATH"
        exit 1
    fi
    print_success "模型文件已找到"
    
    # 检查内容文件夹
    if [ -d "content" ] || [ -d "@content" ] || [ -d "rag/content" ]; then
        print_success "内容文件夹已找到"
    else
        print_warning "未找到内容文件夹，搜索功能可能受限"
    fi
    
    echo ""
}

# ==================== 清理函数 ====================
cleanup() {
    print_header "清理资源"
    
    # 杀死所有后台进程
    if [ ! -z "$LLAMA_PID" ]; then
        print_info "停止Llama服务 (PID: $LLAMA_PID)"
        kill $LLAMA_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FLASK_PID" ]; then
        print_info "停止Flask应用 (PID: $FLASK_PID)"
        kill $FLASK_PID 2>/dev/null || true
    fi
    
    # 等待进程完全退出
    sleep 1
    
    print_success "资源清理完成"
}

# 设置trap以便在脚本退出时清理资源
trap cleanup EXIT INT TERM

# ==================== 启动服务 ====================
start_services() {
    print_header "启动服务"
    
    # 启动Llama服务器
    print_info "启动Llama服务器..."
    print_info "  端口: $LLAMA_PORT"
    print_info "  模型: $MODEL_PATH"
    
    ./llama.cpp/build/bin/llama-server \
        -m "$MODEL_PATH" \
        --jinja \
        -t 4 \
        --mlock \
        -c 4096 \
        --host 0.0.0.0 \
        --port $LLAMA_PORT \
        --chat-template-file "$LLAMA_TEMPLATE" \
        --no_warmup \
        > /tmp/llama_server.log 2>&1 &
    
    LLAMA_PID=$!
    print_success "Llama服务已启动 (PID: $LLAMA_PID)"
    
    # 等待Llama服务启动
    print_info "等待Llama服务启动..."
    sleep 3
    
    # 检查Llama服务是否正常
    for i in {1..10}; do
        if curl -s "http://localhost:$LLAMA_PORT/health" > /dev/null 2>&1; then
            print_success "Llama服务已就绪"
            break
        fi
        if [ $i -eq 10 ]; then
            print_error "Llama服务启动超时"
            print_error "日志: $(tail -5 /tmp/llama_server.log)"
            exit 1
        fi
        sleep 1
    done
    
    # 启动Flask应用
    print_info "启动统一Flask应用..."
    print_info "  端口: $UNIFIED_PORT"
    print_info "  Llama服务: $LLAMA_SERVER_URL"
    
    export LLAMA_SERVER_URL="$LLAMA_SERVER_URL"
    export UNIFIED_PORT="$UNIFIED_PORT"
    
    python3 unified_app.py > /tmp/flask_app.log 2>&1 &
    FLASK_PID=$!
    print_success "Flask应用已启动 (PID: $FLASK_PID)"
    
    # 等待Flask应用启动
    print_info "等待Flask应用启动..."
    sleep 2
    
    # 检查Flask应用是否正常
    for i in {1..10}; do
        if curl -s "http://localhost:$UNIFIED_PORT/" > /dev/null 2>&1; then
            print_success "Flask应用已就绪"
            break
        fi
        if [ $i -eq 10 ]; then
            print_error "Flask应用启动超时"
            print_error "日志: $(tail -5 /tmp/flask_app.log)"
            exit 1
        fi
        sleep 1
    done
    
    echo ""
}

# ==================== 显示信息 ====================
show_info() {
    print_header "服务信息"
    
    echo -e "${GREEN}✓ 所有服务已启动${NC}"
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "  Web界面: ${GREEN}http://${LOCAL_IP}:${UNIFIED_PORT}${NC}"
    echo -e "  Llama API: ${GREEN}http://${LOCAL_IP}:${LLAMA_PORT}${NC}"
    echo ""
    echo -e "${BLUE}进程信息:${NC}"
    echo -e "  Llama服务 PID: ${GREEN}${LLAMA_PID}${NC}"
    echo -e "  Flask应用 PID: ${GREEN}${FLASK_PID}${NC}"
    echo ""
    echo -e "${BLUE}日志文件:${NC}"
    echo -e "  Llama: /tmp/llama_server.log"
    echo -e "  Flask: /tmp/flask_app.log"
    echo ""
    echo -e "${YELLOW}按 Ctrl+C 停止所有服务${NC}"
    echo ""
}

# ==================== 主函数 ====================
main() {
    print_header "统一的Llama + RAG搜索服务"
    
    check_environment
    start_services
    show_info
    
    # 保持脚本运行
    wait
}

# 运行主函数
main

