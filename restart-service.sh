#!/bin/bash

# 服务重启脚本

echo "=== 百度搜索API服务重启脚本 ==="
echo "选择重启方式:"
echo "1. Docker Compose"
echo "2. Docker容器"
echo "3. PM2"
echo "4. Systemd"
echo "5. Gunicorn直接重启"
echo

read -p "请选择 [1-5]: " method
echo

case $method in
    1)
        echo "使用Docker Compose重启..."
        docker-compose restart
        ;;
    2)
        echo "使用Docker重启..."
        docker stop baidusearch-api 2>/dev/null || true
        docker rm baidusearch-api 2>/dev/null || true
        docker run -d \
            --name baidusearch-api \
            --restart unless-stopped \
            -p 25000:25000 \
            -e PYTHONUNBUFFERED=1 \
            -v $(pwd)/logs:/app/logs \
            baidusearch-api:latest
        ;;
    3)
        echo "使用PM2重启..."
        pm2 restart baidusearch-api || pm2 start ecosystem.config.js
        ;;
    4)
        echo "使用Systemd重启..."
        sudo systemctl restart baidusearch-api || echo "尝试使用root权限重启"
        ;;
    5)
        echo "使用Gunicorn直接重启..."
        pkill -f "gunicorn.*main:app" 2>/dev/null
        sleep 2
        echo "启动新进程..."
        gunicorn --bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app > logs/service.log 2>&1 &
        echo "进程PID: $!"
        ;;
    *)
        echo "无效选择，使用默认方式重启..."
        # 尝试自动检测
        if command -v docker-compose &> /dev/null && [ -f "docker-compose.yml" ]; then
            docker-compose restart
        elif command -v docker &> /dev/null; then
            docker restart baidusearch-api 2>/dev/null || docker run -d --name baidusearch-api -p 25000:25000 baidusearch-api:latest
        elif command -v pm2 &> /dev/null; then
            pm2 restart baidusearch-api 2>/dev/null || pm2 start ecosystem.config.js
        elif command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q baidusearch-api; then
            sudo systemctl restart baidusearch-api
        else
            pkill -f "gunicorn.*main:app" 2>/dev/null
            sleep 2
            gunicorn --bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app > logs/service.log 2>&1 &
        fi
        ;;
esac

echo "✅ 重启完成"
echo "等待10秒后检查服务状态..."
sleep 10

# 检查服务状态
if curl -s -o /dev/null -w "%{http_code}" http://localhost:25000/brave-search?q=test --max-time 5 | grep -q "200"; then
    echo "✅ 服务正常运行"
else
    echo "⚠️ 服务可能未启动，请检查日志"
fi