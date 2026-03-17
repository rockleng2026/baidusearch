# 快速启动指南

## 最简单的后台运行方式

### 方法1：Docker Compose（推荐）

```bash
# 第一次运行
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 方法2：使用部署脚本

```bash
# Linux/Mac
chmod +x deploy.sh
./deploy.sh

# Windows
deploy.bat
```

### 方法3：PM2（专业守护进程）

```bash
# 安装pm2
npm install -g pm2

# 启动服务
pm2 start ecosystem.config.js

# 保存配置，开机自启
pm2 save
pm2 startup

# 查看状态
pm2 status
```

## 常用命令

### 启动服务
```bash
./deploy.sh  # 交互式选择部署方式
```

### 停止服务
```bash
# Docker方式
docker-compose down

# PM2方式
pm2 stop baidusearch-api

# Systemd方式
sudo systemctl stop baidusearch-api
```

### 重启服务
```bash
# 使用重启脚本
bash restart-service.sh

# 或手动重启（Docker）
docker-compose restart
```

### 监控服务
```bash
# 启动后台监控
bash monitor.sh daemon

# 查看监控日志
tail -f logs/monitor.log
```

## 验证服务

```bash
# 简单测试
curl "http://localhost:25000/brave-search?q=test"

# 详细测试
python test_api.py
```

## 故障排除

1. **端口冲突**：修改 `docker-compose.yml` 或 `main.py` 中的端口号
2. **无法启动**：查看 `logs/` 目录下的错误日志
3. **服务崩溃**：使用 `monitor.sh` 自动重启
4. **依赖问题**：重新运行 `pip install -r requirements.txt`

## 生产环境建议

1. **使用Docker**：部署最简单，隔离性好
2. **启用监控**：使用 `monitor.sh daemon` 自动重启
3. **配置防火墙**：只允许必要端口访问
4. **日志管理**：定期清理 `logs/` 目录日志文件