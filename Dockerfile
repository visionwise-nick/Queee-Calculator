# 1. 使用官方的 Python 3.10 slim 版本作为基础镜像
# slim 版本比较小，可以加快部署速度
FROM python:3.10-slim

# 2. 设置容器内的工作目录
WORKDIR /app

# 3. 将我们的后端代码复制到容器中
# 我们只复制 backend 文件夹，以保持镜像的纯净
COPY ./backend /app

# 4. 安装 requirements.txt 中定义的所有 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 5. 声明容器将监听的端口
# Heroku 会通过 PORT 环境变量告诉我们的应用应该在哪个端口上监听
EXPOSE $PORT

# 6. 定义容器启动时要执行的命令
# 使用 uvicorn 启动 FastAPI 应用
# --host 0.0.0.0 让服务可以从容器外部访问
# --port $PORT 使用环境变量中的端口，支持Heroku的动态端口分配
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"] 