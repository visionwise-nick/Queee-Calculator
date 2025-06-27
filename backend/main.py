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
    prompt: str = Field(..., description="用户的自然语言描述")

# 简化的AI系统提示
SYSTEM_PROMPT = """你是AI计算器设计师。严格按照以下格式返回JSON，无其他文字。

基础操作类型：
- input: 数字输入，需要value字段
- operator: 运算符，需要value字段(+,-,*,/)
- equals: 等号
- clearAll: 全清除
- negate: 正负号
- decimal: 小数点
- expression: 表达式运算，需要expression字段

完整示例：
{
  "name": "蓝色平方计算器",
  "description": "带平方功能的蓝色计算器",
  "theme": {
    "name": "蓝色主题",
    "backgroundColor": "#001133",
    "displayBackgroundColor": "#002244",
    "operatorButtonColor": "#0066ff"
  },
  "layout": {
    "name": "标准布局",
    "rows": 6,
    "columns": 4,
    "buttons": [
      {"id": "clear", "label": "AC", "action": {"type": "clearAll"}, "gridPosition": {"row": 1, "column": 0}, "type": "secondary"},
      {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 1, "column": 1}, "type": "secondary"},
      {"id": "square", "label": "x²", "action": {"type": "expression", "expression": "x*x"}, "gridPosition": {"row": 1, "column": 2}, "type": "special"},
      {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 1, "column": 3}, "type": "operator"}
    ]
  }
}"""

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "2.0.0"}

@app.post("/customize")
async def customize_calculator(request: CustomizationRequest) -> CalculatorConfig:
    try:
        # 构建用户提示
        user_prompt = f"""设计计算器：{request.prompt}

要求完整JSON，包含：
- name: 计算器名称
- description: 描述
- theme: 主题颜色配置
- layout: 按钮布局(必须包含17个基础按钮)

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
            config_data['authorPrompt'] = request.prompt
        
        # 验证生成的配置
        calculator_config = CalculatorConfig(**config_data)
        
        # 基础验证
        if len(calculator_config.layout.buttons) < 16:
            raise ValueError(f"按钮数量不足：需要至少16个按钮，当前只有{len(calculator_config.layout.buttons)}个")
        
        # 检查必需的基础按钮
        button_labels = [btn.label for btn in calculator_config.layout.buttons]
        required_basics = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-', '×', '÷', '=', 'AC']
        missing = [req for req in required_basics if req not in button_labels and req.replace('×', '*').replace('÷', '/') not in button_labels]
        
        if missing:
            raise ValueError(f"缺少必需的基础按钮: {missing}")
        
        return calculator_config
        
    except Exception as e:
        print(f"处理错误: {e}")
        raise HTTPException(status_code=500, detail=f"生成计算器配置失败: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000))) 