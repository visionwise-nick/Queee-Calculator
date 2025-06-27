from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import google.generativeai as genai
import json
import os
from datetime import datetime

app = FastAPI(title="Queee Calculator AI Backend", version="2.0.0")

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置Gemini AI
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

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

# 当前使用的模型（默认为flash，速度快且效果好）
current_model_key = "flash"

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

class CalculatorTheme(BaseModel):
    name: str
    backgroundColor: str = "#000000"
    displayBackgroundColor: str = "#222222"
    displayTextColor: str = "#FFFFFF"
    primaryButtonColor: str = "#333333"
    primaryButtonTextColor: str = "#FFFFFF"
    secondaryButtonColor: str = "#555555"
    secondaryButtonTextColor: str = "#FFFFFF"
    operatorButtonColor: str = "#FF9F0A"
    operatorButtonTextColor: str = "#FFFFFF"
    fontSize: float = 24.0
    buttonBorderRadius: float = 8.0
    hasGlowEffect: bool = False
    shadowColor: Optional[str] = None

class CalculatorLayout(BaseModel):
    name: str
    rows: int
    columns: int
    buttons: List[CalculatorButton]
    description: str = ""

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

class CustomizationRequest(BaseModel):
    user_input: str = Field(..., description="用户的自然语言描述")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=[], description="对话历史")
    current_config: Optional[Dict[str, Any]] = Field(default=None, description="当前计算器配置")

# 强化的AI系统提示
SYSTEM_PROMPT = """你是专业的计算器设计大师。创造功能丰富、设计精美的专业计算器。

🎯 核心设计原则：
1. 【永远保留基础功能】- 绝不能删除或替换基础的17个按钮
2. 【增加而非替换】- 总是添加新功能，扩展计算器能力
3. 【专业级设计】- 创造复杂、有用、创新的功能组合
4. 【视觉卓越】- 精心设计主题、颜色、布局

📋 必须保留的17个基础按钮（永远不能删除）：
- 数字：0,1,2,3,4,5,6,7,8,9
- 运算符：+,-,*,/
- 功能：=（等号）, AC（清除）, ±（正负号）, .（小数点）

🚀 专业功能扩展库（用expression实现）：
【数学函数】平方:"x*x" 立方:"pow(x,3)" 开根号:"sqrt(x)" 立方根:"pow(x,1/3)" 倒数:"1/x" 绝对值:"abs(x)"
【科学计算】正弦:"sin(x)" 余弦:"cos(x)" 正切:"tan(x)" 自然对数:"log(x)" 常用对数:"log10(x)" e的x次方:"exp(x)"
【金融财务】小费15%:"x*0.15" 小费20%:"x*0.20" 税率8.5%:"x*0.085" 增值税:"x*1.13" 折扣7折:"x*0.7" 翻倍:"x*2"
【工程计算】平方根倒数:"1/sqrt(x)" x的4次方:"pow(x,4)" x的5次方:"pow(x,5)" 2的x次方:"pow(2,x)"
【日常实用】转华氏度:"x*9/5+32" 转摄氏度:"(x-32)*5/9" 英寸转厘米:"x*2.54" 厘米转英寸:"x/2.54"

💡 布局设计策略：
- 标准4列布局，可扩展至5-6行
- 基础按钮占用核心位置
- 专业功能放在额外行或列
- 使用isWide和columnSpan创造有趣布局

🎨 主题设计要求：
- 根据用途选择专业配色（科学=蓝色系，金融=绿色系，工程=橙色系）
- 使用渐变色和阴影效果
- 设置合适的字体大小和圆角
- 考虑夜间模式和护眼配色

科学计算器示例：
{
  "name": "专业科学计算器",
  "description": "包含三角函数、对数、幂运算的完整科学计算器",
  "theme": {
    "name": "科学蓝主题",
    "backgroundColor": "#0B1426",
    "displayBackgroundColor": "#1e3a5f",
    "primaryButtonColor": "#2563eb",
    "primaryButtonTextColor": "#ffffff",
    "secondaryButtonColor": "#374151",
    "secondaryButtonTextColor": "#f3f4f6",
    "operatorButtonColor": "#0891b2",
    "operatorButtonTextColor": "#ffffff",
    "displayTextColor": "#f0f9ff",
    "fontSize": 22.0,
    "buttonBorderRadius": 12.0,
    "hasGlowEffect": true,
    "shadowColor": "#1e40af"
  },
  "layout": {
    "name": "科学布局",
    "rows": 7,
    "columns": 5,
    "buttons": [
      {"id": "sin", "label": "sin", "action": {"type": "expression", "expression": "sin(x)"}, "gridPosition": {"row": 1, "column": 0}, "type": "special"},
      {"id": "cos", "label": "cos", "action": {"type": "expression", "expression": "cos(x)"}, "gridPosition": {"row": 1, "column": 1}, "type": "special"},
      {"id": "tan", "label": "tan", "action": {"type": "expression", "expression": "tan(x)"}, "gridPosition": {"row": 1, "column": 2}, "type": "special"},
      {"id": "log", "label": "log", "action": {"type": "expression", "expression": "log(x)"}, "gridPosition": {"row": 1, "column": 3}, "type": "special"},
      {"id": "sqrt", "label": "√", "action": {"type": "expression", "expression": "sqrt(x)"}, "gridPosition": {"row": 1, "column": 4}, "type": "special"},
      
      {"id": "clear", "label": "AC", "action": {"type": "clearAll"}, "gridPosition": {"row": 2, "column": 0}, "type": "secondary"},
      {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 2, "column": 1}, "type": "secondary"},
      {"id": "square", "label": "x²", "action": {"type": "expression", "expression": "x*x"}, "gridPosition": {"row": 2, "column": 2}, "type": "special"},
      {"id": "cube", "label": "x³", "action": {"type": "expression", "expression": "pow(x,3)"}, "gridPosition": {"row": 2, "column": 3}, "type": "special"},
      {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 2, "column": 4}, "type": "operator"},
      
      {"id": "seven", "label": "7", "action": {"type": "input", "value": "7"}, "gridPosition": {"row": 3, "column": 0}, "type": "primary"},
      {"id": "eight", "label": "8", "action": {"type": "input", "value": "8"}, "gridPosition": {"row": 3, "column": 1}, "type": "primary"},
      {"id": "nine", "label": "9", "action": {"type": "input", "value": "9"}, "gridPosition": {"row": 3, "column": 2}, "type": "primary"},
      {"id": "power", "label": "x^y", "action": {"type": "expression", "expression": "pow(x,2)"}, "gridPosition": {"row": 3, "column": 3}, "type": "special"},
      {"id": "multiply", "label": "×", "action": {"type": "operator", "value": "*"}, "gridPosition": {"row": 3, "column": 4}, "type": "operator"},
      
      {"id": "four", "label": "4", "action": {"type": "input", "value": "4"}, "gridPosition": {"row": 4, "column": 0}, "type": "primary"},
      {"id": "five", "label": "5", "action": {"type": "input", "value": "5"}, "gridPosition": {"row": 4, "column": 1}, "type": "primary"},
      {"id": "six", "label": "6", "action": {"type": "input", "value": "6"}, "gridPosition": {"row": 4, "column": 2}, "type": "primary"},
      {"id": "inverse", "label": "1/x", "action": {"type": "expression", "expression": "1/x"}, "gridPosition": {"row": 4, "column": 3}, "type": "special"},
      {"id": "subtract", "label": "-", "action": {"type": "operator", "value": "-"}, "gridPosition": {"row": 4, "column": 4}, "type": "operator"},
      
      {"id": "one", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 5, "column": 0}, "type": "primary"},
      {"id": "two", "label": "2", "action": {"type": "input", "value": "2"}, "gridPosition": {"row": 5, "column": 1}, "type": "primary"},
      {"id": "three", "label": "3", "action": {"type": "input", "value": "3"}, "gridPosition": {"row": 5, "column": 2}, "type": "primary"},
      {"id": "exp", "label": "e^x", "action": {"type": "expression", "expression": "exp(x)"}, "gridPosition": {"row": 5, "column": 3}, "type": "special"},
      {"id": "add", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 5, "column": 4}, "type": "operator"},
      
      {"id": "zero", "label": "0", "action": {"type": "input", "value": "0"}, "gridPosition": {"row": 6, "column": 0, "columnSpan": 2}, "type": "primary", "isWide": true},
      {"id": "decimal", "label": ".", "action": {"type": "decimal"}, "gridPosition": {"row": 6, "column": 2}, "type": "primary"},
      {"id": "equals", "label": "=", "action": {"type": "equals"}, "gridPosition": {"row": 6, "column": 3, "columnSpan": 2}, "type": "operator", "isWide": true}
    ]
  }
}

🔥 设计原则：
- 根据用户需求自由设计，可以是简单的基础计算器，也可以是复杂的专业计算器
- 想要多少按钮就设计多少按钮，完全由需求决定
- 可以自由选择布局（3列、4列、5列等）
- 主题设计要符合用途和用户喜好

设计目标：完全根据用户的具体需求设计计算器，自由发挥创造力。只返回JSON。"""

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
            current_config_info = f"""
📋 【当前计算器配置】
名称: {request.current_config.get('name', '未知')}
描述: {request.current_config.get('description', '未知')}
主题: {request.current_config.get('theme', {}).get('name', '未知主题')}
按钮数量: {len(request.current_config.get('layout', {}).get('buttons', []))}
布局: {request.current_config.get('layout', {}).get('rows', '?')}行×{request.current_config.get('layout', {}).get('columns', '?')}列

🎨 当前主题配色:
- 背景色: {request.current_config.get('theme', {}).get('backgroundColor', '未知')}
- 显示屏: {request.current_config.get('theme', {}).get('displayBackgroundColor', '未知')}
- 主要按钮: {request.current_config.get('theme', {}).get('primaryButtonColor', '未知')}
- 运算符按钮: {request.current_config.get('theme', {}).get('operatorButtonColor', '未知')}

⚠️ 这是需要继承和保持的基础设计！
"""
            is_iterative_request = True
        
        if request.conversation_history:
            conversation_context = "\n\n📚 对话历史分析：\n"
            
            # 查找最近的AI生成配置信息
            for i, msg in enumerate(reversed(request.conversation_history[-10:])):
                role = "用户" if msg.get("role") == "user" else "AI助手"
                content = msg.get('content', '')
                conversation_context += f"{role}: {content}\n"
                
                                # 检测是否为增量修改请求
                if msg.get("role") == "user" and any(keyword in content.lower() for keyword in [
                    '修改', '改变', '调整', '优化', '增加', '删除', '换', '改成', '变成', 
                    '把', '将', '设置', '改为', '换成', '加一个', '去掉', '改下', '换个'
                ]):
                    is_iterative_request = True
        
        # 根据对话类型构建不同的提示策略
        if is_iterative_request and request.current_config:
            # 增量修改模式
            design_instruction = """
🔄 【增量修改模式】
重要原则：
1. 保持现有设计的核心特征和风格
2. 仅针对用户明确提及的部分进行修改
3. 未提及的按钮、颜色、布局保持不变
4. 优先微调而非重新设计

修改策略：
- 如果用户要求改变某个按钮，只修改该按钮
- 如果用户要求调整颜色，只改变相关颜色属性
- 如果用户要求添加功能，在现有布局基础上扩展
- 保持整体主题风格的一致性
"""
        else:
            # 全新设计模式
            design_instruction = """
🆕 【全新设计模式】
设计策略：
- 根据用户需求从零开始设计
- 可以自由选择主题、布局、功能
- 创造符合用户期望的完整计算器
"""
        
        # 构建智能化的用户提示
        user_prompt = f"""当前用户需求：{request.user_input}

{current_config_info}

{conversation_context}

{design_instruction}

🎯 任务要求：
请生成一个完整的计算器配置JSON，严格按照以下原则：

{'【继承现有设计】在现有计算器基础上进行精确修改，未提及的元素保持原样' if is_iterative_request else '【全新设计】根据用户需求创建全新的计算器'}

必须包含的字段：
- name: 计算器名称  
- description: 功能描述
- theme: 完整的主题配色方案
- layout: 包含所有按钮的布局配置

按钮格式标准：
{{"id":"唯一ID", "label":"显示文字", "action":{{"type":"操作类型", "value/expression":"参数"}}, "gridPosition":{{"row":行号, "column":列号}}, "type":"按钮类型"}}

⚠️ 特别注意：
- 如果是修改请求，精确理解用户要改什么，不改什么
- 保持基础计算功能的完整性（数字0-9、运算符+−×÷、等号=、清除AC）
- 主题颜色要协调统一
- 布局要合理，避免按钮重叠

只返回JSON配置，不要任何解释文字。"""

        # 使用当前选择的模型
        model_name = AVAILABLE_MODELS[current_model_key]["name"]
        model_display = AVAILABLE_MODELS[current_model_key]["display_name"]
        print(f"🤖 使用模型: {model_display} ({model_name})")
        
        model = genai.GenerativeModel(model_name)
        response = model.generate_content([SYSTEM_PROMPT, user_prompt])
        
        if not response.text:
            raise ValueError("AI没有返回有效响应")
        
        # 提取思考过程（如果是thinking模型）
        thinking_process = None
        response_text = response.text.strip()
        
        if current_model_key == "flash-thinking":
            print(f"📝 原始响应长度: {len(response_text)} 字符")
            
            # Flash Thinking模型的多种可能格式
            if "<thinking>" in response_text and "</thinking>" in response_text:
                # 标准thinking标签格式
                thinking_start = response_text.find("<thinking>") + 10
                thinking_end = response_text.find("</thinking>")
                thinking_process = response_text[thinking_start:thinking_end].strip()
                response_text = response_text[thinking_end + 11:].strip()
                print(f"🧠 提取到思考过程(标签格式): {len(thinking_process)} 字符")
            else:
                # 尝试寻找JSON起始位置
                json_start = response_text.find('{')
                if json_start > 50:  # 如果JSON前有足够的文本，可能是思考过程
                    potential_thinking = response_text[:json_start].strip()
                    
                    # 过滤掉可能的markdown格式标记
                    if potential_thinking and not potential_thinking.startswith('```'):
                        thinking_process = potential_thinking
                        response_text = response_text[json_start:].strip()
                        print(f"🧠 提取到思考过程(前缀格式): {len(thinking_process)} 字符")
                    else:
                        print("🤔 JSON前的内容似乎不是思考过程")
                elif json_start == -1:
                    # 找不到JSON，可能整个响应都是思考过程
                    print("⚠️ 未找到JSON格式，可能需要重新请求")
                    # 可以在这里添加重试逻辑或使用默认配置
                else:
                    print("🤔 JSON前内容过短，可能没有思考过程")
        
        # 清理响应文本
        if response_text.startswith('```json'):
            response_text = response_text[7:]
        if response_text.endswith('```'):
            response_text = response_text[:-3]
        response_text = response_text.strip()
        
        # 解析JSON
        try:
            config_data = json.loads(response_text)
        except json.JSONDecodeError as e:
            print(f"JSON解析错误: {e}")
            print(f"响应内容: {response_text}")
            raise ValueError(f"AI返回了无效的JSON格式: {e}")
        
        # 添加必需字段
        if 'id' not in config_data:
            config_data['id'] = f"ai-generated-{int(datetime.now().timestamp())}"
        if 'createdAt' not in config_data:
            config_data['createdAt'] = datetime.now().isoformat()
        if 'authorPrompt' not in config_data:
            config_data['authorPrompt'] = request.user_input
        if thinking_process:
            config_data['thinkingProcess'] = thinking_process
        
        # 直接验证生成的配置结构，完全信任AI的输出
        calculator_config = CalculatorConfig(**config_data)
        
        return calculator_config
        
    except Exception as e:
        print(f"处理错误: {e}")
        raise HTTPException(status_code=500, detail=f"生成计算器配置失败: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000))) 