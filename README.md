# 百度搜索 API 服务

这是一个基于 Flask 的百度搜索 API 服务，提供类似 Brave Search 的接口。

## 功能特性

- 提供百度搜索结果的 RESTful API 接口
- 支持类似 Brave Search 的参数格式
- 返回格式化的 JSON 响应
- 中文支持

## 安装和运行

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 运行服务（立即测试）

```bash
python main.py
```

### 3. 后台运行（生产环境）

#### 方案一：使用部署脚本（推荐）

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows:**
```cmd
deploy.bat
```

#### 方案二：Docker（推荐用于生产）

```bash
# 后台运行
docker-compose up -d

# 或直接使用docker
docker run -d --name baidusearch-api --restart unless-stopped -p 25000:25000 baidusearch-api
```

#### 方案三：PM2守护进程（需要Node.js）

```bash
npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

#### 方案四：Systemd服务（Linux系统）

```bash
sudo bash setup-systemd.sh
```

## API 接口

### Brave 风格搜索接口

**接口地址**: `GET /brave-search`

**参数**:
- `q`: 搜索关键词 (必填)
- `count`: 返回结果数量 (可选，默认10)
- `country`: 国家代码 (可选)
- `search_lang`: 搜索语言 (可选)
- `ui_lang`: 用户界面语言 (可选)
- `freshness`: 内容新鲜度 (可选)

**示例请求**:
```
GET http://localhost:25000/brave-search?q=Python编程&count=5
```

**响应格式**:
```json
{
  "web": {
    "results": [
      {
        "title": "搜索结果标题",
        "url": "https://example.com",
        "description": "搜索结果描述",
        "age": "内容新鲜度"
      }
    ]
  }
}
```

## 环境配置

默认运行在 25000 端口，可以通过修改 `main.py` 中的端口配置来调整。

如需在生产环境部署，建议：
1. 使用 Gunicorn 或 uWSGI
2. 配置 Nginx 反向代理
3. 设置环境变量

## 故障排除

1. **端口被占用**: 修改 `main.py` 中的端口号
2. **依赖安装失败**: 确保 Python 版本 >= 3.7
3. **找不到模块**: 重新运行 `pip install -r requirements.txt`

## 许可证

MIT License