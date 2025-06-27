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

class CustomizationRequest(BaseModel):
    user_input: str = Field(..., description="用户的自然语言描述")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=[], description="对话历史")

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

🔥 关键要求：
- 必须创造至少25个按钮（17个基础+8个以上专业功能）
- 使用5列或6列布局容纳更多功能
- 每个专业计算器都要有丰富的功能按钮
- 不要只改颜色，要实际增加有用的计算功能

设计目标：创造25-35个按钮的功能丰富计算器，结合用户需求选择最合适的功能组合，设计专业级的视觉主题。只返回JSON。"""

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "2.0.0"}

@app.post("/customize")
async def customize_calculator(request: CustomizationRequest) -> CalculatorConfig:
    try:
        # 构建对话历史上下文
        conversation_context = ""
        if request.conversation_history:
            conversation_context = "\n\n对话历史：\n"
            for msg in request.conversation_history[-5:]:  # 只保留最近5条
                role = "用户" if msg.get("role") == "user" else "AI"
                conversation_context += f"{role}: {msg.get('content', '')}\n"
        
        # 构建用户提示
        user_prompt = f"""设计计算器：{request.user_input}

{conversation_context}

要求完整JSON，包含：
- name: 计算器名称  
- description: 描述
- theme: 主题颜色配置
- layout: 按钮布局(必须包含17个基础按钮 + 至少8个专业功能按钮 = 25个以上按钮)

重要：必须创造功能丰富的计算器，不要只改颜色！要增加实用的计算功能！
使用5列或6列布局，创造25-35个按钮的专业计算器。

按钮格式：{{"id":"按钮ID", "label":"显示文字", "action":{{"type":"操作类型", "value":"值或表达式"}}, "gridPosition":{{"row":行, "column":列}}, "type":"按钮类型"}}

只返回JSON，无其他文字。"""

        # 调用Gemini AI
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content([SYSTEM_PROMPT, user_prompt])
        
        if not response.text:
            raise ValueError("AI没有返回有效响应")
        
        # 清理响应文本
        response_text = response.text.strip()
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
        
        # 验证生成的配置
        calculator_config = CalculatorConfig(**config_data)
        
        # 基础验证 - 鼓励更多按钮
        if len(calculator_config.layout.buttons) < 20:
            print(f"建议增加更多功能按钮，当前只有{len(calculator_config.layout.buttons)}个按钮")
        
        # 验证最多可以有50个按钮
        if len(calculator_config.layout.buttons) > 50:
            raise ValueError(f"按钮数量过多：最多50个按钮，当前有{len(calculator_config.layout.buttons)}个")
        
        # 检查必需的基础按钮
        button_labels = [btn.label for btn in calculator_config.layout.buttons]
        button_types = [btn.action.type for btn in calculator_config.layout.buttons]
        
        # 必需的数字按钮
        required_numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
        missing_numbers = [num for num in required_numbers if num not in button_labels]
        
        # 必需的运算符按钮
        required_operators = ['+', '-', '*', '/', '×', '÷']
        has_operators = any(op in button_labels for op in required_operators)
        
        # 必需的功能按钮
        has_equals = 'equals' in button_types or '=' in button_labels
        has_clear = 'clearAll' in button_types or 'AC' in button_labels
        has_decimal = 'decimal' in button_types or '.' in button_labels
        
        errors = []
        if missing_numbers:
            errors.append(f"缺少数字按钮: {missing_numbers}")
        if not has_operators:
            errors.append("缺少运算符按钮 (+, -, *, /)")
        if not has_equals:
            errors.append("缺少等号按钮 (=)")
        if not has_clear:
            errors.append("缺少清除按钮 (AC)")
        if not has_decimal:
            errors.append("缺少小数点按钮 (.)")
            
        if errors:
            raise ValueError(f"配置验证失败: {'; '.join(errors)}")
        
        return calculator_config
        
    except Exception as e:
        print(f"处理错误: {e}")
        raise HTTPException(status_code=500, detail=f"生成计算器配置失败: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000))) 