#!/bin/bash

##############################################################################
# 部署检查脚本
# 检查系统是否满足运行统一Llama + RAG服务的所有要求
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ==================== 系统检查 ====================
print_header "系统环境检查"

# 操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    check_pass "操作系统: Linux"
    
    # 检查架构
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        check_pass "CPU架构: ARM64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        check_warn "CPU架构: x86_64 (推荐使用ARM64优化版本)"
    else
        check_warn "CPU架构: $ARCH (可能不支持)"
    fi
else
    check_warn "操作系统: $OSTYPE (推荐使用Linux)"
fi

# 内存
TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')
echo "  总内存: $TOTAL_MEM, 可用: $AVAIL_MEM"

# 磁盘空间
DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')
DISK_AVAIL_NUM=$(df . | awk 'NR==2 {print $4}')
echo "  可用磁盘空间: $DISK_AVAIL"

if [ $DISK_AVAIL_NUM -gt 5242880 ]; then  # 5GB
    check_pass "磁盘空间充足 (>5GB)"
else
    check_warn "磁盘空间可能不足 (<5GB)"
fi

# ==================== Python检查 ====================
print_header "Python环境检查"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    check_pass "Python3已安装: $PYTHON_VERSION"
else
    check_fail "Python3未安装"
fi

# Python依赖
if python3 -c "import flask" 2>/dev/null; then
    FLASK_VERSION=$(python3 -c "import flask; print(flask.__version__)" 2>/dev/null)
    check_pass "Flask已安装: $FLASK_VERSION"
else
    check_warn "Flask未安装 (可自动安装)"
fi

if python3 -c "import requests" 2>/dev/null; then
    REQUESTS_VERSION=$(python3 -c "import requests; print(requests.__version__)" 2>/dev/null)
    check_pass "requests已安装: $REQUESTS_VERSION"
else
    check_warn "requests未安装 (可自动安装)"
fi

# ==================== 编译工具检查 ====================
print_header "编译工具检查"

if command -v gcc &> /dev/null; then
    GCC_VERSION=$(gcc --version | head -1)
    check_pass "GCC已安装: $GCC_VERSION"
else
    check_warn "GCC未安装 (编译llama.cpp需要)"
fi

if command -v cmake &> /dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1)
    check_pass "CMake已安装: $CMAKE_VERSION"
else
    check_warn "CMake未安装 (编译llama.cpp需要)"
fi

if command -v make &> /dev/null; then
    check_pass "Make已安装"
else
    check_warn "Make未安装 (编译llama.cpp需要)"
fi

# ==================== 项目文件检查 ====================
print_header "项目文件检查"

# 启动脚本
if [ -f "unified_run.sh" ]; then
    check_pass "unified_run.sh 存在"
else
    check_fail "unified_run.sh 不存在"
fi

if [ -f "unified_run_arm64.sh" ]; then
    check_pass "unified_run_arm64.sh 存在"
else
    check_fail "unified_run_arm64.sh 不存在"
fi

# 应用文件
if [ -f "unified_app.py" ]; then
    check_pass "unified_app.py 存在"
else
    check_fail "unified_app.py 不存在"
fi

# 前端文件
if [ -f "templates/unified_index.html" ]; then
    check_pass "templates/unified_index.html 存在"
else
    check_fail "templates/unified_index.html 不存在"
fi

# RAG模块
if [ -f "rag/search_strings.py" ]; then
    check_pass "rag/search_strings.py 存在"
else
    check_fail "rag/search_strings.py 不存在"
fi

# llama.cpp
if [ -d "llama.cpp" ]; then
    check_pass "llama.cpp 目录存在"
    
    if [ -f "llama.cpp/build/bin/llama-server" ]; then
        check_pass "llama-server 已编译"
    else
        check_warn "llama-server 未编译 (需要编译)"
    fi
else
    check_fail "llama.cpp 目录不存在"
fi

# ==================== 模型文件检查 ====================
print_header "模型文件检查"

if [ -d "models" ]; then
    check_pass "models 目录存在"
    
    MODEL_COUNT=$(find models -type f -name "*.gguf" 2>/dev/null | wc -l)
    if [ $MODEL_COUNT -gt 0 ]; then
        check_pass "找到 $MODEL_COUNT 个模型文件"
        find models -type f -name "*.gguf" -exec ls -lh {} \; | awk '{print "  - " $9 " (" $5 ")"}'
    else
        check_warn "未找到模型文件 (*.gguf)"
    fi
else
    check_warn "models 目录不存在"
fi

# ==================== 内容文件检查 ====================
print_header "内容文件检查"

if [ -d "rag/content" ]; then
    check_pass "rag/content 目录存在"
    
    FILE_COUNT=$(find rag/content -type f \( -name "*.md" -o -name "*.txt" \) 2>/dev/null | wc -l)
    if [ $FILE_COUNT -gt 0 ]; then
        check_pass "找到 $FILE_COUNT 个内容文件"
    else
        check_warn "未找到内容文件 (*.md 或 *.txt)"
    fi
else
    check_warn "rag/content 目录不存在 (搜索功能将不可用)"
fi

# 搜索缓存
if [ -f "rag/search_results.json" ]; then
    CACHE_SIZE=$(wc -l < rag/search_results.json)
    check_pass "搜索缓存存在 ($CACHE_SIZE 行)"
else
    check_warn "搜索缓存不存在 (可自动生成)"
fi

# ==================== 网络检查 ====================
print_header "网络检查"

# 检查curl
if command -v curl &> /dev/null; then
    check_pass "curl 已安装"
else
    check_warn "curl 未安装 (可能无法进行网络测试)"
fi

# 检查端口可用性
if command -v netstat &> /dev/null; then
    if ! netstat -tuln 2>/dev/null | grep -q ":8000 "; then
        check_pass "端口 8000 (Llama) 可用"
    else
        check_warn "端口 8000 已被占用"
    fi
    
    if ! netstat -tuln 2>/dev/null | grep -q ":5000 "; then
        check_pass "端口 5000 (Flask) 可用"
    else
        check_warn "端口 5000 已被占用"
    fi
else
    check_warn "netstat 未安装 (无法检查端口)"
fi

# ==================== 权限检查 ====================
print_header "权限检查"

if [ -x "unified_run.sh" ]; then
    check_pass "unified_run.sh 可执行"
else
    check_warn "unified_run.sh 不可执行 (需要 chmod +x)"
fi

if [ -x "unified_run_arm64.sh" ]; then
    check_pass "unified_run_arm64.sh 可执行"
else
    check_warn "unified_run_arm64.sh 不可执行 (需要 chmod +x)"
fi

# ==================== 总结 ====================
print_header "检查总结"

TOTAL=$((PASS + WARN + FAIL))
echo ""
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${YELLOW}警告: $WARN${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}✓ 所有检查通过！系统已准备就绪${NC}"
        echo ""
        echo "可以运行以下命令启动服务:"
        echo "  ./unified_run_arm64.sh    (推荐用于ARM64设备)"
        echo "  ./unified_run.sh          (标准版本)"
        exit 0
    else
        echo -e "${YELLOW}⚠ 检查通过，但有 $WARN 个警告${NC}"
        echo ""
        echo "建议:"
        echo "1. 安装缺失的依赖"
        echo "2. 编译llama.cpp"
        echo "3. 下载模型文件"
        echo "4. 添加内容文件"
        echo ""
        echo "可以继续运行服务，但某些功能可能不可用"
        exit 0
    fi
else
    echo -e "${RED}✗ 检查失败，有 $FAIL 个错误${NC}"
    echo ""
    echo "请解决以下问题:"
    echo "1. 安装Python3"
    echo "2. 创建必要的目录和文件"
    echo "3. 编译llama.cpp"
    echo ""
    exit 1
fi

