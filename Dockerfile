FROM python:3.9-slim

WORKDIR /app

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production
ENV BDUSS_COOKIE=
ENV BDUSS_BFESS_COOKIE=

# 复制依赖文件
COPY requirements.txt .

# 安装依赖（包含生产服务器）
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# 安装 curl（用于健康检查）
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 复制应用代码
COPY main.py .

# 暴露端口
EXPOSE 25000

# 创建非root用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 使用Gunicorn运行应用（生产环境）
CMD ["gunicorn", "--bind", "0.0.0.0:25000", "--workers", "4", "--threads", "2", "--timeout", "120", "main:app"]
