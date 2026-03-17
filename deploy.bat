@echo off
echo === 百度搜索API服务部署 ===
echo 请选择部署方式:
echo 1. Docker Compose (推荐)
echo 2. Docker容器
echo 3. 本地运行 + pm2守护进程
echo 4. 本地运行 + NSSM服务
echo.

set /p choice="请选择 [1-4]: "
echo.

if "%choice%"=="1" (
    echo 使用Docker Compose部署...
    docker-compose down 2>nul
    docker-compose build --no-cache
    docker-compose up -d
    echo ✅ 服务已启动在后台
    echo 运行状态: docker-compose ps
    echo 查看日志: docker-compose logs -f
    goto end
)

if "%choice%"=="2" (
    echo 使用Docker容器部署...
    docker stop baidusearch-api 2>nul
    docker rm baidusearch-api 2>nul
    docker build -t baidusearch-api .
    docker run -d ^
        --name baidusearch-api ^
        --restart unless-stopped ^
        -p 25000:25000 ^
        -e PYTHONUNBUFFERED=1 ^
        -v %cd%\logs:/app/logs ^
        baidusearch-api
    echo ✅ 服务已启动在后台
    echo 查看状态: docker ps ^| findstr baidusearch
    echo 查看日志: docker logs -f baidusearch-api
    goto end
)

if "%choice%"=="3" (
    echo 使用PM2守护进程部署...
    npm list -g pm2 >nul 2>&1 || (
        echo 安装pm2...
        npm install -g pm2
    )
    
    echo 安装Python依赖...
    pip install -r requirements.txt gunicorn
    
    echo 使用pm2启动服务...
    pm2 delete baidusearch-api 2>nul
    
    echo 创建pm2配置文件...
    (
        echo module.exports = {
        echo   apps: [{
        echo     name: 'baidusearch-api',
        echo     script: 'gunicorn',
        echo     args: '--bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app',
        echo     cwd: __dirname,
        echo     instances: 1,
        echo     autorestart: true,
        echo     watch: false,
        echo     max_memory_restart: '512M',
        echo     env: {
        echo       NODE_ENV: 'production',
        echo       PYTHONUNBUFFERED: '1'
        echo     },
        echo     log_date_format: 'YYYY-MM-DD HH:mm:ss',
        echo     error_file: './logs/pm2-error.log',
        echo     out_file: './logs/pm2-out.log',
        echo     pid_file: './logs/pm2.pid'
        echo   }]
        echo }
    ) > ecosystem.config.js
    
    pm2 start ecosystem.config.js
    pm2 save
    echo ✅ 服务已启动在后台
    echo 运行状态: pm2 status
    echo 查看日志: pm2 logs baidusearch-api
    goto end
)

if "%choice%"=="4" (
    echo 使用NSSM作为Windows服务...
    echo 安装Python依赖...
    pip install -r requirements.txt gunicorn
    
    echo 下载NSSM...
    if not exist nssm (
        mkdir nssm
        powershell -Command "Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile 'nssm.zip'"
        powershell -Command "Expand-Archive -Path 'nssm.zip' -DestinationPath 'nssm' -Force"
        del nssm.zip
    )
    
    cd nssm
    for /f %%i in ('dir /b nssm-*') do set nssm_dir=%%i
    cd "%nssm_dir%\win64"
    nssm.exe install baidusearch-api "cmd.exe" "/c gunicorn --bind 0.0.0.0:25000 --workers 4 --threads 2 --timeout 120 main:app"
    nssm.exe set baidusearch-api AppDirectory "%cd%"
    nssm.exe set baidusearch-api AppStdout "%cd%\logs\service.log"
    nssm.exe set baidusearch-api AppStderr "%cd%\logs\service-error.log"
    
    net start baidusearch-api
    echo ✅ 服务已安装为Windows服务
    echo 启动服务: net start baidusearch-api
    echo 停止服务: net stop baidusearch-api
    echo 删除服务: sc delete baidusearch-api
    cd ..
    goto end
)

echo ❌ 无效的选择
exit /b 1

:end
echo.
echo === 部署完成 ===
echo API地址: http://localhost:25000/brave-search
echo 测试命令: curl "http://localhost:25000/brave-search?q=test"
pause