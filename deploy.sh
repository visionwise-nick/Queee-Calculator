#!/bin/bash

# Queee Calculator 统一部署脚本
# 部署到 queee-calculator-ai-backend 服务

set -e  # 遇到错误立即退出

echo "🚀 开始部署 Queee Calculator AI Backend..."

# 设置变量
APP_NAME="queee-calculator-ai-backend"
REGION="us-central1"
PROJECT_CONTEXT="."

echo "📋 部署配置:"
echo "  应用名称: $APP_NAME"
echo "  区域: $REGION"
echo "  项目目录: $PROJECT_CONTEXT"
echo ""

# 检查必要的工具
echo "🔍 检查必要工具..."
command -v git >/dev/null 2>&1 || { echo "❌ 错误: git 未安装" >&2; exit 1; }

# 检查部署平台工具
DEPLOY_PLATFORM=""
if command -v heroku >/dev/null 2>&1; then
    DEPLOY_PLATFORM="heroku"
    echo "✅ 发现 Heroku CLI"
elif command -v gcloud >/dev/null 2>&1; then
    DEPLOY_PLATFORM="gcp"
    echo "✅ 发现 Google Cloud CLI"
else
    echo "⚠️  未发现部署工具，请选择安装："
    echo "  - Heroku CLI: brew install heroku/brew/heroku"
    echo "  - Google Cloud CLI: brew install google-cloud-sdk"
    echo ""
    echo "💡 如果Command Line Tools过时，请先运行："
    echo "  sudo rm -rf /Library/Developer/CommandLineTools"
    echo "  sudo xcode-select --install"
    exit 1
fi

# 跳过本地Docker构建，使用云端构建

if [ "$DEPLOY_PLATFORM" = "heroku" ]; then
    echo "🚀 使用 Heroku 部署..."
    
    # 检查是否已登录
    if ! heroku auth:whoami >/dev/null 2>&1; then
        echo "🔐 请登录 Heroku..."
        heroku login
    fi
    
    # 使用Git部署而不是容器部署
    echo "📤 使用 Git 推送到 Heroku..."
    
    # 检查是否已添加Heroku remote
    if ! git remote get-url heroku >/dev/null 2>&1; then
        echo "🔗 添加 Heroku remote..."
        heroku git:remote -a $APP_NAME
    fi
    
    # 推送到Heroku
    git push heroku main
    
    # 设置环境变量
    echo "⚙️  设置环境变量..."
    heroku config:set --app $APP_NAME \
        GEMINI_API_KEY="${GEMINI_API_KEY:-}" \
        ENVIRONMENT=production
    
    # 获取应用URL
    APP_URL=$(heroku apps:info --app $APP_NAME --json | jq -r '.app.web_url' 2>/dev/null || echo "https://$APP_NAME.herokuapp.com/")
    
    echo "🔍 检查部署状态..."
    heroku ps --app $APP_NAME

elif [ "$DEPLOY_PLATFORM" = "gcp" ]; then
    echo "🚀 使用 Google Cloud Run 部署..."
    
    # 使用云端构建和部署
    echo "☁️  使用 Cloud Build 进行云端构建和部署..."
    gcloud run deploy $APP_NAME \
        --source . \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --set-env-vars GEMINI_API_KEY="${GEMINI_API_KEY:-}",ENVIRONMENT=production \
        --quiet
    
    # 获取应用URL
    APP_URL=$(gcloud run services describe $APP_NAME --region=$REGION --format="value(status.url)")
fi

echo ""
echo "✅ 部署完成！"
echo "🌐 应用URL: $APP_URL"
echo "📊 健康检查: ${APP_URL}health"
echo "🔧 API文档: ${APP_URL}docs"
echo ""

# 运行健康检查
echo "🏥 运行健康检查..."
if command -v curl >/dev/null 2>&1; then
    sleep 5  # 等待应用启动
    if curl -f "${APP_URL}health" >/dev/null 2>&1; then
        echo "✅ 健康检查通过！"
    else
        echo "⚠️  健康检查失败，请检查应用日志"
        if [ "$DEPLOY_PLATFORM" = "heroku" ]; then
            heroku logs --tail --app $APP_NAME
        elif [ "$DEPLOY_PLATFORM" = "gcp" ]; then
            gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$APP_NAME" --limit 50
        fi
    fi
else
    echo "ℹ️  curl 未安装，跳过自动健康检查"
    echo "   请手动访问: ${APP_URL}health"
fi

echo ""
echo "📝 有用的命令:"
if [ "$DEPLOY_PLATFORM" = "heroku" ]; then
    echo "  查看日志: heroku logs --tail --app $APP_NAME"
    echo "  重启应用: heroku restart --app $APP_NAME"
    echo "  查看配置: heroku config --app $APP_NAME"
    echo "  打开应用: heroku open --app $APP_NAME"
elif [ "$DEPLOY_PLATFORM" = "gcp" ]; then
    echo "  查看日志: gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=$APP_NAME' --limit 50"
    echo "  查看服务: gcloud run services describe $APP_NAME --region=$REGION"
    echo "  删除服务: gcloud run services delete $APP_NAME --region=$REGION"
fi

echo ""
echo "🎯 后续使用此脚本进行所有部署操作，确保统一性！" 