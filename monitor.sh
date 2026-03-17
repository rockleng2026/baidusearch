#!/bin/bash

# 服务监控脚本

SERVICE_URL="http://localhost:25000/brave-search?q=test"
CHECK_INTERVAL=60  # 检查间隔（秒）
MAX_RETRIES=3      # 最大重试次数
RESTART_SCRIPT="./restart-service.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_service() {
    response=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL" --max-time 5)
    if [ "$response" = "200" ]; then
        echo "success"
    else
        echo "failed"
    fi
}

restart_service() {
    log "正在重启服务..."
    
    # 尝试不同的重启方式
    if command -v docker-compose &> /dev/null; then
        log "使用Docker Compose重启..."
        docker-compose restart
        return $?
    elif command -v docker &> /dev/null; then
        log "使用Docker重启..."
        docker restart baidusearch-api 2>/dev/null
        if [ $? -ne 0 ]; then
            log "启动新容器..."
            docker run -d --name baidusearch-api --restart unless-stopped -p 25000:25000 baidusearch-api:latest
        fi
        return $?
    elif command -v pm2 &> /dev/null; then
        log "使用PM2重启..."
        pm2 restart baidusearch-api
        return $?
    elif command -v systemctl &> /dev/null; then
        log "使用systemctl重启..."
        systemctl restart baidusearch-api
        return $?
    elif [ -f "$RESTART_SCRIPT" ]; then
        log "使用自定义重启脚本..."
        bash "$RESTART_SCRIPT"
        return $?
    else
        log "尝试使用gunicorn重启..."
        pkill -f "gunicorn.*main:app" 2>/dev/null
        sleep 2
        gunicorn --bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app > logs/service.log 2>&1 &
        return $?
    fi
}

monitor() {
    log "启动服务监控..."
    log "服务URL: $SERVICE_URL"
    log "检查间隔: ${CHECK_INTERVAL}秒"
    
    consecutive_failures=0
    
    while true; do
        status=$(check_service)
        
        if [ "$status" = "success" ]; then
            if [ "$consecutive_failures" -gt 0 ]; then
                log "服务恢复成功"
                consecutive_failures=0
            else
                log "服务正常运行"
            fi
        else
            consecutive_failures=$((consecutive_failures + 1))
            log "服务检测失败 ($consecutive_failures/$MAX_RETRIES)"
            
            if [ "$consecutive_failures" -ge "$MAX_RETRIES" ]; then
                log "达到最大失败次数，尝试重启服务..."
                if restart_service; then
                    log "服务重启成功，等待30秒后重新检查..."
                    sleep 30
                    consecutive_failures=0
                else
                    log "服务重启失败"
                fi
            fi
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# 守护进程化运行
if [ "$1" = "daemon" ]; then
    nohup bash "$0" > logs/monitor.log 2>&1 &
    echo $! > logs/monitor.pid
    log "监控脚本已启动在后台，PID: $(cat logs/monitor.pid)"
else
    monitor
fi