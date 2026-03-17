#!/bin/bash

# 百度搜索API服务部署脚本

set -e

echo "=== 百度搜索API服务部署 ==="
echo "请选择部署方式:"
echo "1. Docker Compose (推荐)"
echo "2. Docker容器"
echo "3. 本地运行 + pm2守护进程"
echo "4. 本地运行 + screen"
echo

read -p "请选择 [1-4]: " choice
echo

case $choice in
    1)
        echo "使用Docker Compose部署..."
        docker-compose down || true
        docker-compose build --no-cache
        docker-compose up -d
        echo "✅ 服务已启动在后台"
        echo "运行状态: docker-compose ps"
        echo "查看日志: docker-compose logs -f"
        ;;
    2)
        echo "使用Docker容器部署..."
        # 停止旧容器
        docker stop baidusearch-api 2>/dev/null || true
        docker rm baidusearch-api 2>/dev/null || true
        
        # 构建并运行
        docker build -t baidusearch-api .
        docker run -d \
            --name baidusearch-api \
            --restart unless-stopped \
            -p 25000:25000 \
            -e PYTHONUNBUFFERED=1 \
            -v $(pwd)/logs:/app/logs \
            baidusearch-api
        
        echo "✅ 服务已启动在后台"
        echo "查看状态: docker ps | grep baidusearch"
        echo "查看日志: docker logs -f baidusearch-api"
        ;;
    3)
        echo "使用PM2守护进程部署..."
        if ! command -v pm2 &> /dev/null; then
            echo "安装pm2..."
            npm install -g pm2
        fi
        
        # 安装依赖
        echo "安装Python依赖..."
        pip install -r requirements.txt gunicorn
        
        echo "使用pm2启动服务..."
        pm2 delete baidusearch-api 2>/dev/null || true
        
        # 创建pm2配置文件
        cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'baidusearch-api',
    script: 'gunicorn',
    args: '--bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app',
    cwd: __dirname,
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PYTHONUNBUFFERED: '1'
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    pid_file: './logs/pm2.pid'
  }]
}
EOF
        
        pm2 start ecosystem.config.js
        pm2 save
        pm2 startup
        echo "✅ 服务已启动在后台"
        echo "运行状态: pm2 status"
        echo "查看日志: pm2 logs baidusearch-api"
        ;;
    4)
        echo "使用Screen后台运行..."
        # 安装依赖
        echo "安装Python依赖..."
        pip install -r requirements.txt gunicorn
        
        # 停止已有的screen会话
        screen -S baidusearch-api -X quit 2>/dev/null || true
        
        echo "启动Screen会话..."
        screen -dmS baidusearch-api gunicorn --bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app
        
        echo "✅ 服务已启动在后台"
        echo "查看会话: screen -ls | grep baidusearch"
        echo "连接会话: screen -r baidusearch-api"
        echo "退出连接: Ctrl+A, D"
        ;;
    *)
        echo "❌ 无效的选择"
        exit 1
        ;;
esac

echo
echo "=== 部署完成 ==="
echo "API地址: http://localhost:25000/brave-search"
echo "测试命令: curl 'http://localhost:25000/brave-search?q=test'"