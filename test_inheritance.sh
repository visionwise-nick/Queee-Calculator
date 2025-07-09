#!/bin/bash

echo "🔧 测试AI设计师继承式修改功能"
echo "============================================================"

BASE_URL="https://queee-calculator-ai-backend-685339952769.us-central1.run.app"

# 创建测试请求JSON
cat > test_request.json << 'EOF'
{
  "user_input": "添加一个sin函数按钮",
  "current_config": {
    "id": "calc_scientific_test",
    "name": "科学计算器",
    "description": "测试用的科学计算器配置",
    "theme": {
      "name": "经典黑",
      "backgroundColor": "#000000",
      "displayBackgroundColor": "#222222",
      "displayTextColor": "#FFFFFF",
      "primaryButtonColor": "#333333",
      "secondaryButtonColor": "#555555",
      "operatorButtonColor": "#FF9F0A",
      "fontSize": 24.0,
      "buttonBorderRadius": 8.0
    },
    "layout": {
      "name": "科学计算器布局",
      "rows": 6,
      "columns": 6,
      "buttons": [
        {
          "id": "btn_1",
          "label": "1",
          "action": {"type": "input", "value": "1"},
          "gridPosition": {"row": 3, "column": 0},
          "type": "primary",
          "backgroundImage": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        },
        {
          "id": "btn_2",
          "label": "2",
          "action": {"type": "input", "value": "2"},
          "gridPosition": {"row": 3, "column": 1},
          "type": "primary"
        },
        {
          "id": "btn_add",
          "label": "+",
          "action": {"type": "operator", "value": "+"},
          "gridPosition": {"row": 3, "column": 2},
          "type": "operator"
        },
        {
          "id": "btn_equals",
          "label": "=",
          "action": {"type": "equals"},
          "gridPosition": {"row": 4, "column": 0},
          "type": "operator"
        }
      ]
    },
    "appBackground": {
      "backgroundImageUrl": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
      "backgroundType": "image",
      "backgroundOpacity": 1.0,
      "buttonOpacity": 0.7,
      "displayOpacity": 0.8
    }
  },
  "has_image_workshop_content": true,
  "workshop_protected_fields": [
    "appBackground.backgroundImageUrl",
    "appBackground.buttonOpacity", 
    "appBackground.displayOpacity",
    "button.btn_1.backgroundImage"
  ]
}
EOF

echo "📤 发送测试请求..."
echo "用户输入: 添加一个sin函数按钮"
echo "原配置按钮数量: 4"
echo "保护字段数量: 4"

# 发送请求并保存响应
echo "正在发送请求..."
curl -X POST "$BASE_URL/customize" \
  -H "Content-Type: application/json" \
  -d @test_request.json \
  -o test_response.json \
  -w "HTTP状态码: %{http_code}\n响应时间: %{time_total}s\n"

# 检查响应状态
if [ $? -eq 0 ]; then
    echo "✅ 请求发送成功！"
    
    # 检查响应文件是否存在且不为空
    if [ -s test_response.json ]; then
        echo "📊 分析响应结果..."
        
        # 提取关键信息
        echo ""
        echo "🔧 配置基本信息:"
        echo "新配置ID: $(cat test_response.json | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)"
        echo "新配置名称: $(cat test_response.json | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)"
        
        # 检查按钮数量
        button_count=$(cat test_response.json | grep -o '"id":"btn_[^"]*"' | wc -l | tr -d ' ')
        echo ""
        echo "🔧 按钮继承检查:"
        echo "新配置按钮数量: $button_count"
        
        # 检查是否保持了原按钮ID
        echo "检查原按钮ID保持情况:"
        for btn_id in "btn_1" "btn_2" "btn_add" "btn_equals"; do
            if grep -q "\"id\":\"$btn_id\"" test_response.json; then
                echo "  ✅ $btn_id - 保持"
            else
                echo "  ❌ $btn_id - 丢失"
            fi
        done
        
        # 检查是否添加了sin函数
        echo ""
        echo "🎯 新功能检查:"
        if grep -q -i "sin" test_response.json; then
            echo "✅ 找到sin相关内容"
            # 尝试提取sin按钮的标签
            sin_labels=$(cat test_response.json | grep -o '"label":"[^"]*sin[^"]*"' | cut -d'"' -f4)
            if [ -n "$sin_labels" ]; then
                echo "sin按钮标签: $sin_labels"
            fi
        else
            echo "❌ 未找到sin相关内容"
        fi
        
        # 检查APP背景保护
        echo ""
        echo "🎨 APP背景保护检查:"
        if grep -q "\"backgroundImageUrl\":" test_response.json; then
            echo "✅ APP背景图字段存在"
        else
            echo "❌ APP背景图字段缺失"
        fi
        
        if grep -q "\"buttonOpacity\":0.7" test_response.json; then
            echo "✅ 按钮透明度保持正确 (0.7)"
        else
            echo "❌ 按钮透明度被修改"
        fi
        
        if grep -q "\"displayOpacity\":0.8" test_response.json; then
            echo "✅ 显示区透明度保持正确 (0.8)"
        else
            echo "❌ 显示区透明度被修改"
        fi
        
        # 检查btn_1的背景图保护
        echo ""
        echo "🔍 按钮背景图保护检查:"
        btn_1_section=$(cat test_response.json | sed -n '/"id":"btn_1"/,/"id":"[^b]/p' | head -20)
        if echo "$btn_1_section" | grep -q "backgroundImage"; then
            echo "✅ btn_1 背景图字段存在"
        else
            echo "❌ btn_1 背景图字段丢失"
        fi
        
        echo ""
        echo "📄 完整响应已保存到 test_response.json"
        echo "可以使用以下命令查看完整内容:"
        echo "cat test_response.json | jq ."
        
    else
        echo "❌ 响应为空或无效"
        echo "查看错误信息:"
        cat test_response.json
    fi
else
    echo "❌ 请求发送失败"
fi

# 清理临时文件
rm -f test_request.json

echo ""
echo "🏁 测试完成" 