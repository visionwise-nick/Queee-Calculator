import os
import google.generativeai as genai
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json

# --- Pydantic Models for Validation ---
# 这些模型将确保AI生成的JSON与Flutter应用所需的结构一致

class SoundEffect(BaseModel):
    trigger: str
    soundUrl: str
    volume: float = 1.0

class CalculatorTheme(BaseModel):
    name: str
    backgroundColor: str
    displayBackgroundColor: str
    displayTextColor: str
    primaryButtonColor: str
    primaryButtonTextColor: str
    secondaryButtonColor: str
    secondaryButtonTextColor: str
    operatorButtonColor: str
    operatorButtonTextColor: str
    backgroundImage: str | None = None
    fontFamily: str | None = None
    fontSize: float = 24.0
    buttonBorderRadius: float = 8.0
    hasGlowEffect: bool = False
    shadowColor: str | None = None
    soundEffects: list[SoundEffect] | None = None

class GridPosition(BaseModel):
    row: int
    column: int
    rowSpan: int | None = None
    columnSpan: int | None = None

class CalculatorAction(BaseModel):
    type: str
    value: str | None = None

class CalculatorButton(BaseModel):
    id: str
    label: str
    action: CalculatorAction
    gridPosition: GridPosition
    type: str # primary, secondary, operator, special
    customColor: str | None = None
    customTextColor: str | None = None
    icon: str | None = None
    isWide: bool = False
    isHigh: bool = False

class CalculatorLayout(BaseModel):
    name: str
    rows: int
    columns: int
    buttons: list[CalculatorButton]
    hasDisplay: bool = True
    displayRowSpan: int = 1
    description: str = ''

class CalculatorConfig(BaseModel):
    id: str
    name: str
    version: int
    theme: CalculatorTheme
    layout: CalculatorLayout

# --- FastAPI App Initialization ---
app = FastAPI()

# 配置CORS，允许Flutter应用（在开发环境中）调用
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # 在生产环境中应配置为你的前端域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Gemini AI Configuration ---
# 请确保您已在环境中设置 GOOGLE_API_KEY
try:
    genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
    model = genai.GenerativeModel('gemini-1.5-flash')
except KeyError:
    print("错误：请设置 'GOOGLE_API_KEY' 环境变量。")
    model = None

# --- System Prompt for AI ---
# 这是最关键的部分，它"教"AI如何成为一个计算器设计师
SYSTEM_PROMPT = """
你是一个专业的计算器配置设计师。根据用户的描述，你需要生成一个JSON配置文件来定义计算器的外观和功能。

## 核心能力
你可以创建以下类型的计算器：
- 基础计算器：四则运算
- 科学计算器：三角函数、对数、指数
- 程序员计算器：进制转换、位运算
- 专业计算器：小费、汇率、单位转换
- 创意计算器：主题化、趣味功能

## 技术规格

### 操作类型 (action.type)
- "input": 数字输入 (需要value)
- "operator": 运算符 (+, -, *, /) (需要value)
- "equals": 等号计算
- "clear": 清除当前
- "clearAll": 全部清除  
- "backspace": 退格
- "decimal": 小数点
- "percentage": 百分比
- "negate": 正负号
- "macro": 自定义宏运算 (需要macro表达式)
- "memory": 内存操作 (MS, MR, MC, M+, M-)
- "scientific": 科学函数 (sin, cos, tan, sqrt, pow, log, ln)
- "function": 数学函数 (abs, round, floor, ceil, reciprocal, factorial)
- "constant": 数学常数 (pi, e, phi, sqrt2)
- "conversion": 单位转换 (deg_to_rad, c_to_f, km_to_miles等)

### 宏表达式 (macro)
支持复杂数学表达式，用"input"代表当前值：
- "input * 0.15" (15%小费)
- "input * input" (平方)
- "sqrt(input)" (平方根)
- "input * 1.60934" (英里转公里)
- "input * 9 / 5 + 32" (摄氏转华氏)

### 布局系统
- rows/columns：网格尺寸 (支持4-10行，3-8列)
- gridPosition：按钮位置 {row, column, rowSpan?, columnSpan?}
- isWide/isHigh：跨格按钮
- 支持不规则布局和自定义尺寸

### 按钮类型 (type)
- "primary": 数字按钮
- "secondary": 功能按钮
- "operator": 运算符按钮
- "special": 特殊功能按钮

### 主题系统
支持完全自定义的颜色、字体、特效：
- backgroundColor: 背景色
- buttonColors: 各类按钮颜色
- textColors: 文字颜色
- fontSize: 字体大小
- borderRadius: 圆角
- hasGlowEffect: 发光效果

## 响应格式
必须返回有效的JSON，包含id、name、theme、layout字段。

## 设计原则
1. 功能优先：确保核心计算功能完整
2. 美观实用：根据用户需求选择合适的主题
3. 创新布局：可以打破传统4x6网格限制
4. 智能命名：按钮标签要直观易懂
5. 宏运算：复杂功能用宏表达式实现

## 示例场景
- "程序员计算器" → 包含A-F按钮、位运算、进制转换
- "厨房计算器" → 单位转换(杯/盎司/毫升)、定时器功能
- "学生计算器" → 数学常数、科学函数、分数计算
- "理财计算器" → 利率计算、货币转换、税费计算

请根据用户描述生成对应的计算器配置。
"""

# --- API Endpoint ---
class GenerateRequest(BaseModel):
    prompt: str

@app.post("/generate-config", response_model=CalculatorConfig)
async def generate_config(request: GenerateRequest):
    if not model:
        raise HTTPException(status_code=500, detail="AI服务未配置，请检查服务器日志和环境变量。")

    user_prompt = request.prompt
    full_prompt = f"{SYSTEM_PROMPT}\n\n用户请求: \"{user_prompt}\""

    try:
        response = model.generate_content(full_prompt)
        
        # 清理AI返回的文本，移除可能存在的markdown代码块标记
        cleaned_response_text = response.text.strip().replace('```json', '').replace('```', '').strip()
        
        # 解析和验证JSON
        ai_json = json.loads(cleaned_response_text)
        config = CalculatorConfig.parse_obj(ai_json)
        return config

    except Exception as e:
        print(f"AI生成或解析JSON时出错: {e}")
        # 这里可以加入重试逻辑，或者返回更详细的错误信息
        raise HTTPException(status_code=500, detail=f"AI无法生成有效的计算器配置: {e}")

@app.get("/")
def read_root():
    return {"status": "Queee Calculator AI Service is running."} 