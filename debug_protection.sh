#!/bin/bash

echo "🔍 调试字段保护功能"
echo "================================"

# 简单的测试请求
cat > debug_request.json << 'EOF'
{
  "user_input": "添加一个sin函数按钮",
  "current_config": {
    "appBackground": {
      "backgroundImageUrl": "test_url",
      "backgroundType": "image",
      "backgroundOpacity": 1.0,
      "buttonOpacity": 0.7,
      "displayOpacity": 0.8,
      "testField": "should_be_protected"
    }
  },
  "has_image_workshop_content": true,
  "workshop_protected_fields": [
    "appBackground.buttonOpacity",
    "appBackground.displayOpacity",
    "appBackground.testField"
  ]
}
EOF

echo "📤 发送调试请求..."
echo "保护字段: appBackground.buttonOpacity, appBackground.displayOpacity, appBackground.testField"

curl -s -X POST "https://queee-calculator-ai-backend-685339952769.us-central1.run.app/customize" \
  -H "Content-Type: application/json" \
  -d @debug_request.json > debug_response.json

echo "✅ 请求完成"
echo ""
echo "📊 结果分析:"
echo "原始appBackground内容:"
echo "  buttonOpacity: 0.7"
echo "  displayOpacity: 0.8"
echo "  testField: should_be_protected"
echo ""
echo "响应中的appBackground内容:"
cat debug_response.json | grep -o '"appBackground":{[^}]*}' | head -1 | sed 's/,/,\n  /g' | sed 's/{/{\n  /'
echo ""
echo "🔍 检查保护情况:"
if grep -q "buttonOpacity.*0.7" debug_response.json; then
    echo "✅ buttonOpacity 保护成功"
else
    echo "❌ buttonOpacity 保护失败"
fi

if grep -q "displayOpacity.*0.8" debug_response.json; then
    echo "✅ displayOpacity 保护成功"
else
    echo "❌ displayOpacity 保护失败"
fi

if grep -q "testField.*should_be_protected" debug_response.json; then
    echo "✅ testField 保护成功"
else
    echo "❌ testField 保护失败"
fi

echo ""
echo "📄 完整响应保存到 debug_response.json"

# 清理
rm debug_request.json

echo "🏁 调试完成" 