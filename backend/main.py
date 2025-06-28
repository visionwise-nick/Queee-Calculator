from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import google.generativeai as genai
import json
import os
from datetime import datetime
import time

app = FastAPI(title="Queee Calculator AI Backend", version="2.0.0")

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 全局变量
_genai_initialized = False
current_model_key = "flash"

def initialize_genai():
    """初始化Google AI"""
    global _genai_initialized
    if _genai_initialized:
        return
        
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("未找到 GEMINI_API_KEY 环境变量")
    
    genai.configure(api_key=api_key)
    _genai_initialized = True
    print("✅ Google AI 初始化完成")

def get_current_model():
    """获取当前AI模型实例"""
    global _genai_initialized
    if not _genai_initialized:
        initialize_genai()
    
    model_name = AVAILABLE_MODELS[current_model_key]["name"]
    return genai.GenerativeModel(model_name)

# 可用模型配置
AVAILABLE_MODELS = {
    "pro": {
        "name": "gemini-2.5-pro",
        "display_name": "Gemini 2.5 Pro",
        "description": "最强推理模型，复杂任务专用，响应时间较长"
    },
    "flash": {
        "name": "gemini-2.0-flash-exp", 
        "display_name": "Gemini 2.0 Flash",
        "description": "快速响应模型，均衡性能，推荐日常使用"
    },
    "flash-thinking": {
        "name": "gemini-2.0-flash-thinking-exp",
        "display_name": "Gemini 2.0 Flash Thinking", 
        "description": "思考推理模型，带有推理过程展示"
    }
}

# Pydantic模型 - 简化版
class GridPosition(BaseModel):
    row: int
    column: int
    columnSpan: Optional[int] = None

class CalculatorAction(BaseModel):
    type: str  # input, operator, equals, clear, clearAll, backspace, decimal, negate, expression
    value: Optional[str] = None
    expression: Optional[str] = None  # 数学表达式，如 "x*x", "x*0.15", "sqrt(x)"

class CalculatorButton(BaseModel):
    id: str
    label: str
    action: CalculatorAction
    gridPosition: GridPosition
    type: str  # e.g., 'primary', 'secondary', 'operator'
    widthMultiplier: Optional[float] = 1.0
    heightMultiplier: Optional[float] = 1.0
    
    # Visual properties
    backgroundColor: Optional[str] = None
    textColor: Optional[str] = None
    fontSize: Optional[float] = None
    borderRadius: Optional[float] = None
    elevation: Optional[float] = None
    gradientColors: Optional[List[str]] = None
    backgroundImage: Optional[str] = None
    customColor: Optional[str] = None
    description: Optional[str] = Field(None, description="按钮功能的详细说明，用于长按提示")

class CalculatorTheme(BaseModel):
    name: str
    backgroundColor: str = "#000000"
    backgroundGradient: Optional[List[str]] = None  # 背景渐变色
    backgroundImage: Optional[str] = None  # 背景图片URL
    displayBackgroundColor: str = "#222222"
    displayBackgroundGradient: Optional[List[str]] = None  # 显示区渐变
    displayTextColor: str = "#FFFFFF"
    displayWidth: Optional[float] = None  # 显示区宽度比例 (0.0-1.0)
    displayHeight: Optional[float] = None  # 显示区高度比例 (0.0-1.0)
    displayBorderRadius: Optional[float] = None  # 显示区圆角
    primaryButtonColor: str = "#333333"
    primaryButtonGradient: Optional[List[str]] = None  # 主按钮渐变
    primaryButtonTextColor: str = "#FFFFFF"
    secondaryButtonColor: str = "#555555"
    secondaryButtonGradient: Optional[List[str]] = None  # 次按钮渐变
    secondaryButtonTextColor: str = "#FFFFFF"
    operatorButtonColor: str = "#FF9F0A"
    operatorButtonGradient: Optional[List[str]] = None  # 运算符渐变
    operatorButtonTextColor: str = "#FFFFFF"
    fontSize: float = 24.0
    buttonBorderRadius: float = 8.0
    hasGlowEffect: bool = False
    shadowColor: Optional[str] = None
    buttonElevation: Optional[float] = None  # 按钮阴影高度
    buttonShadowColors: Optional[List[str]] = None  # 多层阴影颜色
    buttonSpacing: Optional[float] = None  # 按钮间距
    adaptiveLayout: bool = True  # 是否启用自适应布局

class CalculatorLayout(BaseModel):
    name: str
    rows: int
    columns: int
    buttons: List[CalculatorButton]
    description: str = ""
    minButtonSize: Optional[float] = None  # 最小按钮尺寸
    maxButtonSize: Optional[float] = None  # 最大按钮尺寸
    gridSpacing: Optional[float] = None  # 网格间距

class CalculatorConfig(BaseModel):
    id: str
    name: str
    description: str
    theme: CalculatorTheme
    layout: CalculatorLayout
    version: str = "1.0.0"
    createdAt: str
    authorPrompt: Optional[str] = None
    thinkingProcess: Optional[str] = None  # AI的思考过程
    aiResponse: Optional[str] = None  # AI的回复消息

class CustomizationRequest(BaseModel):
    user_input: str = Field(..., description="用户的自然语言描述")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=[], description="对话历史")
    current_config: Optional[Dict[str, Any]] = Field(default=None, description="当前计算器配置")

# 简化的AI系统提示 - 专注布局设计
SYSTEM_PROMPT = """你是顶级的计算器设计AI。你的任务是根据用户需求，生成一份完整、精确、可直接使用的计算器JSON配置。

⚠️ 核心设计准则 (必须严格遵守):
1.  **【绝不为空】**: `buttons`数组绝对不能为空。对于任何请求，都必须生成一个包含基础功能的计算器。
2.  **【Action完整性】**: 每个按钮都必须有`action`字段，且`action.type`必须是有效类型。无效或缺失将导致按钮失灵。
3.  **【保留基础】**: 任何设计都必须包含17个基础按钮 (数字0-9, +−×÷, =, AC, ±, .)，除非用户明确要求删除。

🎯 设计任务清单:
- **布局**: 决定行列数 (2-10行, 2-8列)。
- **按钮**: 安排每个按钮的位置、功能和样式。
- **主题**: 设计配色、背景、视觉效果。
- **功能描述**: 为复杂或不常见的按钮添加`description`字段，用于长按提示。

🔧 布局与按钮规则:
- **基础按钮ID**: 必须使用标准ID (zero, one, ..., add, subtract, ..., clear, negate, decimal)。
- **坐标**: `gridPosition`的`row`和`column`从0开始。
- **Action有效类型**: `type`必须是 'input', 'operator', 'equals', 'clear', 'clearAll', 'decimal', 'negate', 'expression' 之一。
- **功能描述**: 为所有非数字和基础运算符的按钮添加`description`字段。例如: `{"id": "negate", "description": "切换正负号"}`。

🔄 继承性原则 (重要):
- 只修改用户明确要求的部分。
- 保持现有的颜色、布局、视觉效果不变，除非用户要求更改。
- 基于现有配置进行增量修改，而不是重新设计。

🎨 视觉设计功能:
- **尺寸**: `widthMultiplier`, `heightMultiplier` (0.5-3.0)。
- **独立样式**: `fontSize`, `borderRadius`, `elevation`。
- **渐变**: `gradientColors: ["#起始色", "#结束色"]`。
- **背景图**: `backgroundImage: "AI生成图片描述"`。
- **主题增强**: `backgroundGradient`, `displayHeight`, `buttonShadowColors`, `buttonSpacing`等。
- **功能描述**: `description: "按钮功能中文说明"` (例如: "计算x的平方根")。

💡 基础计算器设计模板 (如果用户没有具体要求，可基于此模板进行修改):
```json
{
  "layout": {
    "rows": 5, "columns": 4,
    "buttons": [
      {"id": "clear", "label": "AC", "action": {"type": "clear"}, "gridPosition": {"row": 0, "column": 0}, "type": "secondary", "description": "清除所有输入"},
      {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 0, "column": 1}, "type": "secondary", "description": "切换正负号"},
      {"id": "percent", "label": "%", "action": {"type": "expression", "expression": "x/100"}, "gridPosition": {"row": 0, "column": 2}, "type": "secondary", "description": "计算百分比"},
      {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 0, "column": 3}, "type": "operator"},
      {"id": "seven", "label": "7", "action": {"type": "input", "value": "7"}, "gridPosition": {"row": 1, "column": 0}, "type": "primary"},
      {"id": "eight", "label": "8", "action": {"type": "input", "value": "8"}, "gridPosition": {"row": 1, "column": 1}, "type": "primary"},
      {"id": "nine", "label": "9", "action": {"type": "input", "value": "9"}, "gridPosition": {"row": 1, "column": 2}, "type": "primary"},
      {"id": "multiply", "label": "×", "action": {"type": "operator", "value": "*"}, "gridPosition": {"row": 1, "column": 3}, "type": "operator"},
      {"id": "four", "label": "4", "action": {"type": "input", "value": "4"}, "gridPosition": {"row": 2, "column": 0}, "type": "primary"},
      {"id": "five", "label": "5", "action": {"type": "input", "value": "5"}, "gridPosition": {"row": 2, "column": 1}, "type": "primary"},
      {"id": "six", "label": "6", "action": {"type": "input", "value": "6"}, "gridPosition": {"row": 2, "column": 2}, "type": "primary"},
      {"id": "subtract", "label": "−", "action": {"type": "operator", "value": "-"}, "gridPosition": {"row": 2, "column": 3}, "type": "operator"},
      {"id": "one", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 3, "column": 0}, "type": "primary"},
      {"id": "two", "label": "2", "action": {"type": "input", "value": "2"}, "gridPosition": {"row": 3, "column": 1}, "type": "primary"},
      {"id": "three", "label": "3", "action": {"type": "input", "value": "3"}, "gridPosition": {"row": 3, "column": 2}, "type": "primary"},
      {"id": "add", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 3, "column": 3}, "type": "operator"},
      {"id": "zero", "label": "0", "action": {"type": "input", "value": "0"}, "gridPosition": {"row": 4, "column": 0, "columnSpan": 2}, "type": "primary"},
      {"id": "decimal", "label": ".", "action": {"type": "decimal"}, "gridPosition": {"row": 4, "column": 2}, "type": "primary", "description": "输入小数点"},
      {"id": "equals", "label": "=", "action": {"type": "equals"}, "gridPosition": {"row": 4, "column": 3}, "type": "operator"}
    ]
  }
}
```

只返回这份JSON配置，不要包含任何其他文字。"""

# AI二次校验和修复系统提示
VALIDATION_PROMPT = """你是计算器配置修复机器人。你的唯一任务是修复传入的JSON配置，确保其100%可用。

⚠️ 修复铁律 (必须严格执行):
1.  **【修复空按钮】**: 如果`buttons`数组为空，或少于17个基础按钮，立即用下面的标准模板替换或补充。
2.  **【修复Action】**: 检查每个按钮，如果`action`字段缺失或`action.type`无效，立即修复它。
3.  **【补充描述】**: 为所有功能键 (非数字和基础运算符) 补充`description`字段，解释其功能。
4.  **【遵守继承】**: 严格保持用户未要求修改的任何颜色、样式或布局。

🎯 必需的17个基础按钮 (标准配置模板):
```json
[
  {"id": "clear", "label": "AC", "action": {"type": "clear"}, "gridPosition": {"row": 0, "column": 0}, "type": "secondary", "description": "清除所有输入"},
  {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 0, "column": 1}, "type": "secondary", "description": "切换正负号"},
  {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 0, "column": 3}, "type": "operator"},
  {"id": "seven", "label": "7", "action": {"type": "input", "value": "7"}, "gridPosition": {"row": 1, "column": 0}, "type": "primary"},
  {"id": "eight", "label": "8", "action": {"type": "input", "value": "8"}, "gridPosition": {"row": 1, "column": 1}, "type": "primary"},
  {"id": "nine", "label": "9", "action": {"type": "input", "value": "9"}, "gridPosition": {"row": 1, "column": 2}, "type": "primary"},
  {"id": "multiply", "label": "×", "action": {"type": "operator", "value": "*"}, "gridPosition": {"row": 1, "column": 3}, "type": "operator"},
  {"id": "four", "label": "4", "action": {"type": "input", "value": "4"}, "gridPosition": {"row": 2, "column": 0}, "type": "primary"},
  {"id": "five", "label": "5", "action": {"type": "input", "value": "5"}, "gridPosition": {"row": 2, "column": 1}, "type": "primary"},
  {"id": "six", "label": "6", "action": {"type": "input", "value": "6"}, "gridPosition": {"row": 2, "column": 2}, "type": "primary"},
  {"id": "subtract", "label": "−", "action": {"type": "operator", "value": "-"}, "gridPosition": {"row": 2, "column": 3}, "type": "operator"},
  {"id": "one", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 3, "column": 0}, "type": "primary"},
  {"id": "two", "label": "2", "action": {"type": "input", "value": "2"}, "gridPosition": {"row": 3, "column": 1}, "type": "primary"},
  {"id": "three", "label": "3", "action": {"type": "input", "value": "3"}, "gridPosition": {"row": 3, "column": 2}, "type": "primary"},
  {"id": "add", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 3, "column": 3}, "type": "operator"},
  {"id": "zero", "label": "0", "action": {"type": "input", "value": "0"}, "gridPosition": {"row": 4, "column": 0}, "type": "primary", "widthMultiplier": 2.0},
  {"id": "decimal", "label": ".", "action": {"type": "decimal"}, "gridPosition": {"row": 4, "column": 2}, "type": "primary", "description": "输入小数点"},
  {"id": "equals", "label": "=", "action": {"type": "equals"}, "gridPosition": {"row": 4, "column": 3}, "type": "operator"}
]
```

📝 返回格式:
直接返回修复后的完整JSON配置，确保其100%可用。不要包含任何说明文字。

请基于用户需求和现有配置，对生成的配置进行修复并返回最终的JSON。"""

@app.get("/health")
async def health_check():
    return {
        "status": "healthy", 
        "version": "2.0.0",
        "current_model": AVAILABLE_MODELS[current_model_key]["display_name"],
        "model_key": current_model_key
    }

@app.get("/models")
async def get_available_models():
    """获取所有可用的AI模型"""
    return {
        "available_models": AVAILABLE_MODELS,
        "current_model": current_model_key
    }

@app.post("/switch-model/{model_key}")
async def switch_model(model_key: str):
    """动态切换AI模型"""
    global current_model_key
    
    if model_key not in AVAILABLE_MODELS:
        raise HTTPException(
            status_code=400, 
            detail=f"不支持的模型: {model_key}. 可用模型: {list(AVAILABLE_MODELS.keys())}"
        )
    
    old_model = AVAILABLE_MODELS[current_model_key]["display_name"]
    current_model_key = model_key
    new_model = AVAILABLE_MODELS[current_model_key]["display_name"]
    
    return {
        "message": f"模型已切换: {old_model} → {new_model}",
        "old_model": old_model,
        "new_model": new_model,
        "model_key": current_model_key,
        "description": AVAILABLE_MODELS[current_model_key]["description"]
    }

@app.post("/customize")
async def customize_calculator(request: CustomizationRequest) -> CalculatorConfig:
    try:
        # 分析对话历史和当前配置，确定设计继承策略
        conversation_context = ""
        current_config_info = ""
        is_iterative_request = False
        
        # 检查是否有当前配置（最重要的继承依据）
        if request.current_config:
            theme = request.current_config.get('theme', {})
            layout = request.current_config.get('layout', {})
            buttons = layout.get('buttons', [])
            
            current_config_info = f"""
📋 【当前计算器配置 - 必须继承】
名称: {request.current_config.get('name', '未知')}
描述: {request.current_config.get('description', '未知')}
布局: {layout.get('rows', 0)}行 × {layout.get('columns', 0)}列，共{len(buttons)}个按钮

🎨 【当前主题配置 - 保持不变除非用户要求】
- 主题名称: {theme.get('name', '默认')}
- 背景颜色: {theme.get('backgroundColor', '#000000')}
- 背景渐变: {theme.get('backgroundGradient', '无')}
- 背景图片: {theme.get('backgroundImage', '无')}
- 显示区背景: {theme.get('displayBackgroundColor', '#222222')}
- 显示区渐变: {theme.get('displayBackgroundGradient', '无')}
- 显示文字颜色: {theme.get('displayTextColor', '#FFFFFF')}
- 主按钮颜色: {theme.get('primaryButtonColor', '#333333')}
- 主按钮渐变: {theme.get('primaryButtonGradient', '无')}
- 次按钮颜色: {theme.get('secondaryButtonColor', '#555555')}
- 次按钮渐变: {theme.get('secondaryButtonGradient', '无')}
- 运算符颜色: {theme.get('operatorButtonColor', '#FF9F0A')}
- 运算符渐变: {theme.get('operatorButtonGradient', '无')}
- 字体大小: {theme.get('fontSize', 24.0)}
- 按钮圆角: {theme.get('buttonBorderRadius', 8.0)}
- 发光效果: {theme.get('hasGlowEffect', False)}
- 阴影颜色: {theme.get('shadowColor', '无')}
- 按钮阴影: {theme.get('buttonElevation', '无')}
- 多层阴影: {theme.get('buttonShadowColors', '无')}
- 按钮间距: {theme.get('buttonSpacing', '默认')}
- 自适应布局: {theme.get('adaptiveLayout', True)}

🔄 【继承要求】
请严格保持以上所有配置不变，除非用户明确要求修改某个特定属性。
用户只是想要增加功能或微调，不要重新设计整个主题！
"""
            is_iterative_request = True
        
        # 分析对话历史
        if request.conversation_history:
            recent_messages = request.conversation_history[-3:] if len(request.conversation_history) > 3 else request.conversation_history
            conversation_context = f"""
📜 【对话历史上下文】
{chr(10).join([f"- {msg.get('role', '用户')}: {msg.get('content', '')}" for msg in recent_messages])}

基于对话历史，这是一个{('继续优化' if is_iterative_request else '新建')}请求。
"""

        # 构建增强的用户提示
        enhanced_user_prompt = f"""
{conversation_context}

{current_config_info}

🎯 【用户当前需求】
{request.user_input}

⚠️ 【重要提醒】
1. 如果有现有配置，请严格继承所有未被用户要求修改的属性
2. 只修改用户明确要求改变的部分
3. 保持现有的视觉风格和配色方案
4. 确保所有按钮都包含完整的action字段
5. 生成的配置必须在移动设备上正常显示

请生成符合要求的计算器配置JSON。
"""

        # 调用AI生成配置
        model = get_current_model()
        response = model.generate_content([
            {"role": "user", "parts": [SYSTEM_PROMPT + "\n\n" + enhanced_user_prompt]}
        ])
        
        # 解析AI响应
        response_text = response.text.strip()
        print(f"📝 AI响应长度: {len(response_text)} 字符")
        
        # 提取JSON配置
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            config_json = response_text[json_start:json_end].strip()
        else:
            # 尝试找到JSON对象的开始和结束
            json_start = response_text.find('{')
            json_end = response_text.rfind('}')
            if json_start != -1 and json_end != -1:
                config_json = response_text[json_start:json_end+1]
            else:
                config_json = response_text
        
        print(f"🔍 提取的JSON长度: {len(config_json)} 字符")
        print(f"🔍 JSON前100字符: {config_json[:100]}")
        
        # 解析JSON
        try:
            raw_config = json.loads(config_json)
            print(f"✅ JSON解析成功")
        except json.JSONDecodeError as e:
            print(f"❌ JSON解析失败: {str(e)}")
            print(f"📄 原始响应: {response_text[:500]}")
            raise HTTPException(status_code=500, detail=f"AI生成的JSON格式无效: {str(e)}")
        
        # 🔍 AI二次校验和修复
        fixed_config = await fix_calculator_config(request.user_input, request.current_config, raw_config)
        
        # 基本数据验证和字段补充
        if 'theme' not in fixed_config:
            fixed_config['theme'] = {}
        if 'layout' not in fixed_config:
            fixed_config['layout'] = {'buttons': []}
        
        # 补充必需字段
        theme = fixed_config['theme']
        if 'name' not in theme:
            theme['name'] = '自定义主题'
        
        layout = fixed_config['layout']
        if 'name' not in layout:
            layout['name'] = '自定义布局'
        if 'buttons' not in layout:
            layout['buttons'] = []
        
        # 确保所有按钮都有action字段
        for button in layout.get('buttons', []):
            if 'action' not in button:
                # 根据按钮类型和ID推断action
                button_id = button.get('id', '')
                if button_id in ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']:
                    number_map = {'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4', 
                                  'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9'}
                    button['action'] = {'type': 'input', 'value': number_map.get(button_id, button_id)}
                elif button_id == 'add':
                    button['action'] = {'type': 'operator', 'value': '+'}
                elif button_id == 'subtract':
                    button['action'] = {'type': 'operator', 'value': '-'}
                elif button_id == 'multiply':
                    button['action'] = {'type': 'operator', 'value': '*'}
                elif button_id == 'divide':
                    button['action'] = {'type': 'operator', 'value': '/'}
                elif button_id == 'equals':
                    button['action'] = {'type': 'equals'}
                elif button_id == 'clear':
                    button['action'] = {'type': 'clear'}
                elif button_id == 'decimal':
                    button['action'] = {'type': 'decimal'}
                elif button_id == 'negate':
                    button['action'] = {'type': 'negate'}
        else:
                    button['action'] = {'type': 'input', 'value': button.get('label', '0')}
        
        print(f"🔍 修复后按钮数量: {len(layout.get('buttons', []))}")
        
        # 创建完整的配置对象
        config = CalculatorConfig(
            id=f"calc_{int(time.time())}",
            name=fixed_config.get('name', '自定义计算器'),
            description=fixed_config.get('description', '由AI修复的计算器配置'),
            theme=CalculatorTheme(**theme),
            layout=CalculatorLayout(**layout),
            version="1.0.0",
            createdAt=datetime.now().isoformat(),
            authorPrompt=request.user_input,
            thinkingProcess=response_text if "思考过程" in response_text else None,
            aiResponse=f"✅ 成功修复计算器配置",
        )
        
        return config
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"修复计算器配置时出错: {str(e)}")
        raise HTTPException(status_code=500, detail=f"修复计算器配置失败: {str(e)}")

async def fix_calculator_config(user_input: str, current_config: dict, generated_config: dict) -> dict:
    """AI二次校验和修复生成的计算器配置"""
    try:
        # 构建修复上下文
        fix_context = f"""
用户需求：{user_input}

现有配置摘要（需要继承的部分）：
{json.dumps(current_config, ensure_ascii=False, indent=2) if current_config else "无现有配置"}

生成的配置（需要修复）：
{json.dumps(generated_config, ensure_ascii=False, indent=2)}

请修复上述配置中的问题，确保：
1. 满足用户需求
2. 继承现有配置中用户未要求修改的部分
3. 包含所有必需的基础按钮
4. 所有按钮都有正确的action字段
5. 布局结构合理

直接返回修正后的完整JSON配置。
"""

        # 调用AI进行修复
        model = get_current_model()
        response = model.generate_content([
            {"role": "user", "parts": [VALIDATION_PROMPT + "\n\n" + fix_context]}
        ])
        
        # 解析修复后的配置
        fix_text = response.text.strip()
        print(f"🔧 AI修复响应长度: {len(fix_text)} 字符")
        
        # 提取JSON
        if "```json" in fix_text:
            json_start = fix_text.find("```json") + 7
            json_end = fix_text.find("```", json_start)
            fixed_json = fix_text[json_start:json_end].strip()
        else:
            # 尝试找到JSON对象的开始和结束
            json_start = fix_text.find('{')
            json_end = fix_text.rfind('}')
            if json_start != -1 and json_end != -1:
                fixed_json = fix_text[json_start:json_end+1]
            else:
                # 如果找不到JSON，返回原配置
                print("⚠️ AI修复未返回有效JSON，使用原配置")
                return generated_config
        
        try:
            fixed_config = json.loads(fixed_json)
            print("✅ AI修复成功")
            return fixed_config
        except json.JSONDecodeError as e:
            print(f"❌ AI修复的JSON格式无效: {str(e)}")
            return generated_config
            
    except Exception as e:
        print(f"AI修复过程中出错: {str(e)}")
        return generated_config

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080))) 