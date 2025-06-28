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
    type: str  # primary, secondary, operator, special
    customColor: Optional[str] = None
    isWide: bool = False
    widthMultiplier: float = 1.0  # 宽度倍数
    heightMultiplier: float = 1.0  # 高度倍数
    gradientColors: Optional[List[str]] = None  # 渐变色数组
    backgroundImage: Optional[str] = None  # 背景图片URL
    fontSize: Optional[float] = None  # 按钮独立字体大小
    borderRadius: Optional[float] = None  # 按钮独立圆角
    elevation: Optional[float] = None  # 按钮独立阴影高度

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

# 优化的AI系统提示 - 简化但完整
SYSTEM_PROMPT = """你是专业计算器设计师。必须返回完整的JSON配置，严格按照技术规范。

🔧 必须包含的字段：
- layout.rows: 行数 (4-8)
- layout.columns: 列数 (4-6) 
- layout.buttons: 按钮数组（至少17个基础按钮）

🔧 ACTION字段规范：
数字：{"type": "input", "value": "数字"}
运算符：{"type": "operator", "value": "+|-|*|/"}
等号：{"type": "equals"}
清除：{"type": "clearAll"}
数学函数：{"type": "expression", "expression": "函数名(x)"}

🚀 数学函数格式（严格使用）：
- 三角函数：sin(x), cos(x), tan(x), sqrt(x)
- 幂运算：x*x, 1/x, abs(x)
- 特殊：random(), x!

❌ 禁止格式：Math.sin, Math.sqrt, parseInt等JavaScript语法
✅ 正确格式：sin(x), sqrt(x), x*x等Dart语法

🔄 继承性原则：
- 如果有current_config，只修改用户明确要求的部分
- 保持未提及的颜色、效果、布局不变
- 在现有按钮基础上增加新功能

📐 标准布局：
- 基础计算器：4行4列，17个按钮
- 科学计算器：6行5列，添加数学函数
- 特殊计算器：根据需求调整行列数

🎨 视觉功能：
- 渐变：gradientColors: ["#起始色", "#结束色"]
- 背景图：backgroundImage: "描述文字"
- 按钮尺寸：widthMultiplier (0.5-3.0)

必须返回包含theme和layout的完整JSON，确保layout有rows、columns、buttons字段。"""

# AI二次校验和修复系统提示 - 简化版
VALIDATION_PROMPT = """你是配置修复专家。检查并修复生成的计算器配置。

🔧 必须修复的问题：
1. 缺失字段：确保layout有rows、columns、buttons
2. 空按钮数组：如果buttons为空，补充17个基础按钮
3. 错误字段名：text->label, position->gridPosition
4. 错误action格式：修复数学函数格式
5. 数据类型：确保数值字段为正确类型

🚨 按钮字段规范：
- 必需字段：id, label, action, gridPosition, type
- gridPosition格式：{"row": 数字, "column": 数字}
- action格式：{"type": "类型", "value": "值"} 或 {"type": "expression", "expression": "表达式"}

🚨 数学函数修复：
❌ 错误：Math.sin(x), Math.sqrt(x), parseInt(x)
✅ 正确：sin(x), sqrt(x), x*x

🔧 基础按钮模板（如果缺失）：
数字0-9、运算符+−×÷、功能=、AC、±、.

返回修复后的完整JSON配置。"""

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
        if 'rows' not in layout:
            layout['rows'] = 5  # 默认5行
        if 'columns' not in layout:
            layout['columns'] = 4  # 默认4列
        
        # 🔧 修复按钮字段名问题
        for i, button in enumerate(layout.get('buttons', [])):
            # 修复字段名：text -> label
            if 'text' in button and 'label' not in button:
                button['label'] = button['text']
                del button['text']
            
            # 确保必需字段存在
            if 'id' not in button:
                button['id'] = f"button_{i}"
            if 'label' not in button:
                button['label'] = button.get('text', f"按钮{i}")
            if 'type' not in button:
                button['type'] = 'primary'
            if 'gridPosition' not in button:
                # 根据索引计算网格位置
                row = i // layout['columns']
                col = i % layout['columns']
                button['gridPosition'] = {'row': row, 'column': col}
        
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
                    button['action'] = {'type': 'clearAll'}
                elif button_id == 'decimal':
                    button['action'] = {'type': 'decimal'}
                elif button_id == 'negate':
                    button['action'] = {'type': 'negate'}
                else:
                    button['action'] = {'type': 'input', 'value': button.get('label', '0')}
            
            # 🔧 修复错误的数学函数action格式
            action = button.get('action', {})
            action_type = action.get('type', '')
            
            # 如果发现错误的function、scientific、math类型，自动修复为expression格式
            if action_type in ['function', 'scientific', 'math']:
                # 数学函数映射表
                math_function_map = {
                    'sin': 'sin(x)',
                    'cos': 'cos(x)',
                    'tan': 'tan(x)',
                    'asin': 'asin(x)',
                    'acos': 'acos(x)',
                    'atan': 'atan(x)',
                    'log': 'log(x)',
                    'ln': 'log(x)',
                    'log10': 'log10(x)',
                    'log2': 'log2(x)',
                    'exp': 'exp(x)',
                    'sqrt': 'sqrt(x)',
                    'cbrt': 'cbrt(x)',
                    'pow2': 'x*x',
                    'pow3': 'pow(x,3)',
                    'factorial': 'x!',
                    'inverse': '1/x',
                    'abs': 'abs(x)',
                    'random': 'random()',
                    'percent': 'x*0.01',
                }
                
                # 获取函数名
                func_name = action.get('value') or action.get('function') or action.get('operation')
                if func_name and func_name in math_function_map:
                    # 修复为正确的expression格式
                    button['action'] = {
                        'type': 'expression',
                        'expression': math_function_map[func_name]
                    }
                    print(f"🔧 修复按钮 {button.get('id')} 的action格式: {func_name} → {math_function_map[func_name]}")
                else:
                    # 如果没有映射，保持原有格式但改为expression类型
                    button['action'] = {
                        'type': 'expression',
                        'expression': func_name or 'x'
                    }
                    print(f"⚠️ 未知函数 {func_name}，使用默认expression格式")
        
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