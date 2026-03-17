@echo off
echo 正在启动百度搜索API服务...

REM 检查Python环境
python --version
if errorlevel 1 (
    echo 错误: 未找到Python环境
    pause
    exit /b 1
)

REM 安装依赖
echo 安装依赖...
pip install -r requirements.txt

REM 启动服务
echo 启动服务在端口 25000...
python main.py

pause