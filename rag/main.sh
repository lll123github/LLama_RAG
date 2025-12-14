#!/bin/bash

# 字符串匹配搜索服务启动脚本

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 打印当前工作目录和内容文件夹信息
echo "=========================================="
echo "当前工作目录: $(pwd)"
echo "内容文件夹检查:"
if [ -d "content" ]; then
    echo "  ✓ 找到 content 文件夹"
elif [ -d "@content" ]; then
    echo "  ✓ 找到 @content 文件夹"
elif [ -d "../@content" ]; then
    echo "  ✓ 找到 ../@content 文件夹"
else
    echo "  ⚠ 未找到内容文件夹 (content 或 @content)"
    echo "  提示: 请确保内容文件夹与脚本在同一目录或上级目录"
fi
echo "=========================================="
echo ""

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装Python3"
    exit 1
fi

# 检查Flask是否安装
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Flask未安装，正在安装依赖..."
    pip3 install flask
fi

# 获取操作系统类型
OS_TYPE=$(uname -s)

# 启动Flask应用
echo "启动字符串匹配搜索服务..."
echo "服务地址: http://localhost:5001"
echo "按 Ctrl+C 停止服务"
echo ""

# 启动服务并在浏览器中打开
if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS
    python3 app.py &
    sleep 2
    open "http://localhost:5001"
elif [ "$OS_TYPE" = "Linux" ]; then
    # Linux
    python3 app.py &
    sleep 2
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:5001"
    else
        echo "请手动打开浏览器访问: http://localhost:5001"
    fi
elif [[ "$OS_TYPE" == MINGW* ]] || [[ "$OS_TYPE" == MSYS* ]]; then
    # Windows (Git Bash)
    python3 app.py &
    sleep 2
    start "http://localhost:5001"
else
    # 其他系统
    python3 app.py &
    sleep 2
    echo "请手动打开浏览器访问: http://localhost:5001"
fi

# 等待后台进程
wait

