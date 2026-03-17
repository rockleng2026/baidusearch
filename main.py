from flask import Flask, request, jsonify, Response
from baidusearch.baidusearch import search
import json
import logging
import random
import time

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config["JSON_AS_ASCII"] = False

import os

user_agents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
]

BDUSS_COOKIE = os.environ.get("BDUSS_COOKIE", "")
BDUSS_BFESS_COOKIE = os.environ.get("BDUSS_BFESS_COOKIE", "")


@app.route("/brave-search", methods=["GET"])
def brave_search():
    """
    Brave风格搜索API接口 - 支持TS客户端调用
    参数:
        query: 搜索关键词 (必填)
        count: 返回结果数量 (可选，默认10)
        country: 国家代码 (可选)
        search_lang: 搜索语言 (可选)
        ui_lang: 用户界面语言 (可选)
        freshness: 内容新鲜度 (可选)
    """
    # 获取请求参数
    query = request.args.get("q")
    count = request.args.get("count", 10, type=int)
    country = request.args.get("country")
    search_lang = request.args.get("search_lang")
    ui_lang = request.args.get("ui_lang")
    freshness = request.args.get("freshness")

    # 参数校验
    if not query:
        return jsonify({"error": "缺少必要的参数: query", "code": 400}), 400

    try:
        import baidusearch.baidusearch as bs
        from http.cookiejar import CookieJar

        bs.HEADERS["User-Agent"] = random.choice(user_agents)

        cookie_value = BDUSS_BFESS_COOKIE or BDUSS_COOKIE
        if cookie_value:
            cookie_str = f"BDUSS_BFESS={cookie_value}"
            bs.HEADERS["Cookie"] = cookie_str
            bs.session.cookies.set(
                "BDUSS_BFESS", cookie_value, domain=".baidu.com", path="/"
            )

        time.sleep(random.uniform(0.5, 2.0))

        results = search(query, num_results=count, debug=0)

        # 格式化结果以匹配BraveSearchResponse结构
        formatted_results = []
        for result in results:
            # 清理摘要中的空白字符
            abstract = result.get("abstract", "")
            if abstract:
                abstract = abstract.translate(str.maketrans("", "", " \r\n"))

            formatted_result = {
                "title": result.get("title", ""),
                "url": result.get("url", ""),
                "description": abstract,
                "age": result.get("rank", ""),  # 假设rank字段表示内容的新鲜度
            }
            formatted_results.append(formatted_result)

        # 构建最终返回的JSON结果
        final_result = {"web": {"results": formatted_results}}

        return Response(
            json.dumps(final_result, ensure_ascii=False),
            mimetype="application/json; charset=utf-8",
        )

    except Exception as e:
        logger.error(f"Brave搜索过程中发生错误: {str(e)}")
        return jsonify(
            {"error": f"Brave搜索过程中发生错误: {str(e)}", "code": 500}
        ), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=25000, debug=True)
