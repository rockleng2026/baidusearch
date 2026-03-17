#!/bin/bash

# 百度搜索API服务启动脚本

echo "正在启动百度搜索API服务..."

# 检查Python版本
python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "Python版本: $python_version"

# 检查依赖是否安装
echo "检查依赖..."
pip install -r requirements.txt

# 启动服务
echo "启动服务在端口 25000..."
python main.py