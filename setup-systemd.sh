#!/bin/bash

# Systemd服务安装脚本

set -e

echo "=== 百度搜索API服务 Systemd 安装 ==="

# 检查是否root
if [ "$EUID" -ne 0 ]; then 
    echo "请使用sudo运行此脚本"
    exit 1
fi

# 安装依赖
echo "安装系统依赖..."
apt-get update
apt-get install -y python3 python3-pip python3-venv curl

# 创建用户和目录
echo "创建系统用户和目录..."
useradd -r -s /bin/false baidusearch || true
mkdir -p /opt/baidusearch-api
mkdir -p /var/log/baidusearch-api
chown -R baidusearch:baidusearch /opt/baidusearch-api
chown -R baidusearch:baidusearch /var/log/baidusearch-api

# 复制文件
echo "复制应用程序文件..."
cp -r ./* /opt/baidusearch-api/
chown -R baidusearch:baidusearch /opt/baidusearch-api/*

# 安装Python依赖
echo "安装Python依赖..."
cd /opt/baidusearch-api
pip3 install -r requirements.txt gunicorn

# 安装systemd服务
echo "安装systemd服务..."
cp baidusearch-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable baidusearch-api.service

echo
echo "=== 安装完成 ==="
echo
echo "启动服务: sudo systemctl start baidusearch-api"
echo "停止服务: sudo systemctl stop baidusearch-api"
echo "查看状态: sudo systemctl status baidusearch-api"
echo "查看日志: sudo journalctl -u baidusearch-api -f"
echo
echo "服务将在系统启动时自动运行"
echo "API地址: http://localhost:25000/brave-search"