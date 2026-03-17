# BDUSS Cookie 配置指南

## 背景

百度搜索 API 服务使用 `baidusearch` 库爬取百度搜索结果是，会遇到百度反爬虫机制的拦截，导致搜索返回结果为 0。这是因为：

1. Docker 容器的出口 IP 被百度识别为爬虫 IP 并封锁
2. 请求缺少有效的用户身份认证信息
3. 固定的 User-Agent 特征容易被识别

## 解决方案

通过添加百度 Cookie（BDUSS_BFESS）来绕过百度的安全验证，让百度搜索 API 服务能够正常获取搜索结果。

## 核心实现

### 1. 环境变量支持

在 `main.py` 中添加了两个环境变量支持：

```python
import os

BDUSS_COOKIE = os.environ.get("BDUSS_COOKIE", "")
BDUSS_BFESS_COOKIE = os.environ.get("BDUSS_BFESS_COOKIE", "")
```

### 2. Cookie 注入机制

在搜索请求执行前，动态修改 `baidusearch` 库的请求头：

```python
import baidusearch.baidusearch as bs
from http.cookiejar import CookieJar

# 随机 User-Agent 防止被识别
bs.HEADERS["User-Agent"] = random.choice(user_agents)

# 优先使用 BDUSS_BFESS，其次使用 BDUSS
cookie_value = BDUSS_BFESS_COOKIE or BDUSS_COOKIE
if cookie_value:
    cookie_str = f"BDUSS_BFESS={cookie_value}"
    bs.HEADERS["Cookie"] = cookie_str
    # 同时设置到 session 的 cookiejar 中
    bs.session.cookies.set(
        "BDUSS_BFESS", cookie_value, domain=".baidu.com", path="/"
    )

# 添加随机延迟降低爬虫特征
time.sleep(random.uniform(0.5, 2.0))

results = search(query, num_results=count, debug=0)
```

### 3. Dockerfile 配置

```dockerfile
ENV BDUSS_COOKIE=
ENV BDUSS_BFESS_COOKIE=
```

## 获取 BDUSS_BFESS Cookie

### 方法一：浏览器开发者工具（推荐）

1. 在浏览器中访问 [https://www.baidu.com](https://www.baidu.com)
2. 按 `F12` 打开开发者工具
3. 切换到 **Network**（网络）标签
4. 刷新页面（`F5`）
5. 点击任意请求（如 `www.baidu.com`）
6. 在 **Request Headers**（请求头）中找到 `Cookie` 字段
7. 复制 `BDUSS_BFESS=xxx` 中的 `xxx` 值

### 方法二：使用浏览器扩展

安装 Cookie 管理扩展（如 EditThisCookie、Cookie Editor 等），导出百度域的 Cookie，提取 `BDUSS_BFESS` 字段。

## 部署方式

### Docker Compose（推荐）

编辑 `docker-compose.yml`：

```yaml
version: '3'
services:
  baidusearch-api:
    image: baidusearch-api:latest
    ports:
      - "25000:25000"
    environment:
      - BDUSS_BFESS_COOKIE=你的 BDUSS_BFESS 值
    restart: always
```

然后执行：

```bash
docker-compose up -d
```

### Docker 命令行

```bash
docker run -d --name baidusearch-api \
  -p 25000:25000 \
  -e BDUSS_BFESS_COOKIE="w2eU56WE54WmMwR2E3YjZJWHNINEJ0SlF0LW9zbEtybU5PY1RlTmpRamtQM05wRVFBQUFBJCQAAAAAAAAAAAEAAACqnMoubGVuZ2Zlbmc4NDcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOSyS2nksktpME" \
  baidusearch-api
```

### 直接运行（开发环境）

```bash
export BDUSS_BFESS_COOKIE="你的 BDUSS_BFESS 值"
python main.py
```

## 测试验证

```bash
# 测试 API
curl "http://localhost:25000/brave-search?q=Python 编程&count=3"

# 预期返回
{
  "web": {
    "results": [
      {
        "title": "Python - 百度百科",
        "url": "...",
        "description": "...",
        "age": "1"
      },
      ...
    ]
  }
}
```

## 注意事项

### 1. Cookie 有效期

BDUSS_BFESS Cookie 有有效期（通常为数周至数月），过期后需要重新获取。如果搜索再次返回 0 结果，请检查 Cookie 是否过期。

### 2. 安全提示

- **BDUSS_BFESS 是敏感信息**，相当于百度账号的登录凭证
- 不要将 Cookie 明文提交到代码仓库
- 生产环境建议使用 Docker  secrets 或环境变量管理工具
- 定期更换 Cookie

### 3. 使用频率限制

即使使用 Cookie，也不建议高频调用（建议每秒不超过 1 次请求），否则仍可能触发百度的风控机制。

### 4. 兼容性

- `BDUSS_BFESS` 优先级高于 `BDUSS`
- 如果只配置了 `BDUSS`，系统会自动降级使用
- 建议优先使用 `BDUSS_BFESS`，兼容性更好

## 故障排查

### 问题 1：搜索返回 0 结果

**可能原因：**
- Cookie 过期
- Cookie 值不正确
- 网络问题

**解决方法：**
1. 重新获取 BDUSS_BFESS Cookie
2. 检查容器日志：`docker logs baidusearch-api`
3. 在容器内测试：`docker exec baidusearch-api curl https://www.baidu.com`

### 问题 2：服务启动失败

**可能原因：**
- 环境变量格式错误
- 端口被占用

**解决方法：**
1. 检查环境变量是否正确配置
2. 更换端口或停止占用端口的服务

## 相关资源

- [baidusearch 库源码](https://pypi.org/project/baidusearch/)
- [百度智能云搜索服务](https://cloud.baidu.com/product/search.html)（官方 API 替代方案）
