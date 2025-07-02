from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import google.generativeai as genai
import json
import os
from datetime import datetime
import time
import re
import copy
# 添加图像生成相关导入
import requests
import base64
from io import BytesIO

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
        
    api_key = os.getenv("GEMINI_API_KEY", "AIzaSyDIfDrVDcLEi-RPS33mO0E_aaqnxBgu1U4")
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
        "name": "gemini-2.0-flash", 
        "display_name": "Gemini 2.0 Flash",
        "description": "快速响应模型，均衡性能，推荐日常使用"
    },
    "flash-thinking": {
        "name": "gemini-2.0-flash-thinking-exp",
        "display_name": "Gemini 2.0 Flash Thinking", 
        "description": "思考推理模型，带有推理过程展示"
    },
    "flash-image": {
        "name": "gemini-2.0-flash-preview-image-generation",
        "display_name": "Gemini 2.0 Flash Image Generation",
        "description": "图像生成专用模型，支持文本和图像输出"
    }
}

# Pydantic模型 - 简化版
class GridPosition(BaseModel):
    row: int
    column: int
    columnSpan: Optional[int] = None

class CalculatorAction(BaseModel):
    type: str  # input, operator, equals, clear, clearAll, backspace, decimal, negate, expression, multiParamFunction, parameterSeparator, functionExecute, customFunction
    value: Optional[str] = None
    expression: Optional[str] = None  # 数学表达式，如 "x*x", "x*0.15", "sqrt(x)"
    parameters: Optional[Dict[str, Any]] = None  # 自定义功能的预设参数，如 {"annualRate": 3.5, "years": 30}

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
    # 新增属性
    width: Optional[float] = None  # 按钮绝对宽度(dp)
    height: Optional[float] = None  # 按钮绝对高度(dp)
    backgroundColor: Optional[str] = None  # 按钮独立背景色
    textColor: Optional[str] = None  # 按钮独立文字颜色
    borderColor: Optional[str] = None  # 按钮边框颜色
    borderWidth: Optional[float] = None  # 按钮边框宽度
    shadowColor: Optional[str] = None  # 按钮独立阴影颜色
    shadowOffset: Optional[Dict[str, float]] = None  # 阴影偏移 {"x": 0, "y": 2}
    shadowRadius: Optional[float] = None  # 阴影半径
    opacity: Optional[float] = None  # 按钮透明度 (0.0-1.0)
    rotation: Optional[float] = None  # 按钮旋转角度
    scale: Optional[float] = None  # 按钮缩放比例
    backgroundPattern: Optional[str] = None  # 背景图案类型 ("dots", "stripes", "grid", "waves")
    patternColor: Optional[str] = None  # 图案颜色
    patternOpacity: Optional[float] = None  # 图案透明度
    animation: Optional[str] = None  # 按钮动画类型 ("bounce", "pulse", "shake", "glow")
    animationDuration: Optional[float] = None  # 动画持续时间(秒)
    customIcon: Optional[str] = None  # 自定义图标URL或名称
    iconSize: Optional[float] = None  # 图标大小
    iconColor: Optional[str] = None  # 图标颜色
    
    # 新增：自适应大小相关属性
    adaptiveSize: Optional[bool] = None  # 是否启用自适应大小
    minWidth: Optional[float] = None  # 最小宽度
    maxWidth: Optional[float] = None  # 最大宽度
    minHeight: Optional[float] = None  # 最小高度
    maxHeight: Optional[float] = None  # 最大高度
    aspectRatio: Optional[float] = None  # 宽高比，null表示不限制
    sizeMode: Optional[str] = None  # 'content', 'fill', 'fixed', 'adaptive'
    contentPadding: Optional[Dict[str, float]] = None  # 内容边距 {"left": 8, "top": 4, "right": 8, "bottom": 4}
    autoShrink: Optional[bool] = None  # 内容过长时是否自动缩小
    textScaleFactor: Optional[float] = None  # 文字缩放因子

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

class AppBackground(BaseModel):
    backgroundImageUrl: Optional[str] = None  # APP背景图片URL
    backgroundType: Optional[str] = None  # 背景类型：image, gradient, solid
    backgroundColor: Optional[str] = None  # 背景颜色
    backgroundGradient: Optional[List[str]] = None  # 背景渐变色
    backgroundOpacity: Optional[float] = None  # 背景透明度 (0.0-1.0)
    backgroundBlendMode: Optional[str] = None  # 背景混合模式
    parallaxEffect: Optional[bool] = None  # 是否启用视差效果
    parallaxIntensity: Optional[float] = None  # 视差强度 (0.0-1.0)

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
    appBackground: Optional[AppBackground] = None

class CustomizationRequest(BaseModel):
    user_input: str = Field(..., description="用户的自然语言描述")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=[], description="对话历史")
    current_config: Optional[Dict[str, Any]] = Field(default=None, description="当前计算器配置")
    # 新增：图像生成工坊保护标识
    has_image_workshop_content: Optional[bool] = Field(default=False, description="是否有图像生成工坊生成的内容")
    workshop_protected_fields: Optional[List[str]] = Field(default=[], description="受图像生成工坊保护的字段列表")

# 修复后的AI系统提示 - 明确支持的语法
SYSTEM_PROMPT = """你是专业的计算器功能设计大师。你只负责按钮布局和功能逻辑设计。

🎯 你的核心任务：
1. **输出完整的计算器配置JSON**：包含theme、layout和buttons的功能配置
2. **功能专精**：只负责按钮功能逻辑和布局结构
3. **功能增强**：根据用户需求添加或修改按钮功能
4. **自定义复合功能**：能够根据用户具体需求生成预设参数的专用计算器

🚨 **关键原则 - 禁止无效按键**：
```
严格禁止：
❌ 空按键：没有label或label为空字符串的按键
❌ 无效按键：没有实际功能的按键
❌ 占位按键：仅用于占位的按键
❌ 重复按键：功能完全相同的重复按键
❌ 不支持的功能：底层计算引擎不支持的功能
❌ JavaScript语法：如parseInt、toString、位运算符等

必须确保：
✅ 每个按键都有清晰的label（如"1", "+", "sin", "AC"等）
✅ 每个按键都有明确的action功能
✅ 所有按键都是用户实际需要的功能
✅ 布局紧凑，没有无用的空位
✅ 所有功能都能可靠运行
✅ 只使用支持的数学语法
```

🔧 **支持的Action类型和配置规范**：

## 1. 基础输入类型
```json
{"type": "input", "value": "0-9"}          // 数字输入
{"type": "decimal"}                        // 小数点
{"type": "operator", "value": "+|-|*|/"}   // 基础运算符
{"type": "equals"}                         // 等号计算
{"type": "clear"}                          // 清除
```

## 2. 单参数表达式类型（重要：只支持以下语法）
```json
{"type": "expression", "expression": "SUPPORTED_EXPRESSION"}
```

### ✅ 支持的表达式语法（严格遵守）：
**三角函数**：`sin(x)`, `cos(x)`, `tan(x)`, `asin(x)`, `acos(x)`, `atan(x)`
**双曲函数**：`sinh(x)`, `cosh(x)`, `tanh(x)` 
**对数函数**：`log(x)`, `ln(x)`, `log10(x)`, `log2(x)`
**指数函数**：`exp(x)`, `2^x`, `10^x`
**幂函数**：`x*x`, `x^2`, `x^3`, `x^4`, `x^5`
**根函数**：`sqrt(x)`, `cbrt(x)`
**其他函数**：`1/x`, `abs(x)`, `x!`, `factorial(x)`

**百分比运算**：`x*0.01`, `x*0.15`, `x*0.18`, `x*0.20`
**税费折扣**：`x*1.13`, `x*1.15`, `x*0.85`, `x*0.8`, `x*0.7`
**单位转换**：
- 温度：`x*9/5+32`, `(x-32)*5/9`, `x+273.15`, `x-273.15`
- 长度：`x*2.54`, `x/2.54`, `x*0.3048`, `x/0.3048`
- 重量：`x*0.453592`, `x/0.453592`

**特殊常数**：`pi`, `e`, `random()`

### ❌ 严格禁止的语法（绝对不能使用）：
- JavaScript语法：`parseInt()`, `toString()`, `.toString(16)`, `.toString(2)`
- 位运算符：`&`, `|`, `^`, `~`, `<<`, `>>`
- 字符串操作：任何字符串处理功能
- 条件语句：`if`, `else`, `?:`
- 循环语句：`for`, `while`
- 数组操作：`[]`, `Array`
- 对象操作：`{}`, `Object`

## 3. 多参数函数类型
```json
{"type": "multiParamFunction", "value": "FUNCTION_NAME"}
```

### ✅ 支持的多参数函数：
**基础数学**：`pow`, `log`, `max`, `min`, `avg`, `sum`
**统计计算**：`平均值`, `标准差`, `方差`, `最大值`, `最小值`
**金融计算**：`复利计算`, `贷款计算`, `汇率转换`, `投资回报`
**组合排列**：`组合`, `排列`, `阶乘`
**进制转换**：`进制转换`, `十进制转二进制`, `十进制转八进制`, `十进制转十六进制`, `二进制转十进制`, `八进制转十进制`, `十六进制转十进制`

## 4. 自定义复合功能
```json
{"type": "customFunction", "value": "功能名称", "parameters": {"param1": 默认值}}
```

🎨 **主题配置规范**：
只能设置以下属性：
- backgroundColor: 背景色
- primaryColor: 主色调
- secondaryColor: 辅助色
- displayTextColor: 显示文字颜色
- buttonTextColor: 按钮文字颜色
- operatorColor: 运算符颜色
- numberColor: 数字颜色

📱 **布局配置**：
- 标准4x5网格布局（20个按钮）
- 每行固定4个按钮
- 按钮类型：数字(0-9)、运算符(+/-/*//)、功能键(AC/=)、科学函数

🔍 **响应格式**：
```json
{
  "theme": {
    "name": "计算器名称",
    "backgroundColor": "#颜色代码",
    "primaryColor": "#颜色代码",
    "displayTextColor": "#颜色代码",
    "buttonTextColor": "#颜色代码"
  },
  "layout": {
    "rows": 5,
    "columns": 4
  },
  "buttons": [
    {"label": "按钮文字", "action": {"type": "input", "value": "1"}},
    {"label": "sin", "action": {"type": "expression", "expression": "sin(x)"}},
    {"label": "房贷", "action": {"type": "multiParamFunction", "value": "贷款计算"}}
  ]
}
```

⚠️ **重要约束**：
1. 绝对不能使用JavaScript语法
2. 表达式必须是math_expressions库支持的数学表达式
3. 不支持进制转换功能（二进制、八进制、十六进制）
4. 不支持位运算操作
5. 所有功能必须在上述支持列表中

💡 **成功案例**：
- 折扣计算器：使用 `x*0.8` 表达式
- 小费计算器：使用 `x*0.15` 表达式  
- 单位换算：使用 `x*2.54` 表达式
- 复利计算：使用 `复利计算` 多参数函数
- 科学计算：使用 `sin(x)`, `cos(x)`, `sqrt(x)` 表达式

现在开始根据用户需求设计计算器功能，严格遵守以上语法规范！"""

# AI二次校验和修复系统提示 - 强化无效按键检测
VALIDATION_PROMPT = """你是配置修复专家。检查并修复生成的计算器配置。

🔧 必须修复的问题：
1. 缺失字段：确保layout有rows、columns、buttons
2. 空按钮数组：如果buttons为空，补充基础按钮
3. 错误字段名：text->label, position->gridPosition
4. 错误action格式：修复数学函数格式
5. 数据类型：确保数值字段为正确类型
6. 布局混乱：修复按键位置错误

🚨 **无效按键检测与清理**：
```
必须移除的无效按键：
❌ label为空、null或undefined的按键
❌ label只包含空格的按键
❌ 没有action或action为空的按键
❌ gridPosition超出合理范围的按键
❌ 重复功能的按键（如多个相同的数字按键）

有效按键标准：
✅ label: 非空字符串（如"1", "+", "sin", "AC"）
✅ action: 正确的动作对象
✅ gridPosition: 在合理范围内的位置
✅ type: 有效的按键类型
```

🚨 **多参数函数必需按键检测与自动添加**：
```
自动检测规则（关键修复）：
✅ 扫描所有按键，检查是否存在multiParamFunction类型按键
✅ 如果发现多参数函数按键，检查是否同时存在：
   - parameterSeparator类型的逗号按键（必需）
   - functionExecute类型的执行按键（必需）
✅ 如果缺少，立即自动添加到合适位置
✅ 自动调整布局rows和columns以容纳新增按键

自动添加的按键模板：
逗号按键：{"id": "btn_comma_auto", "label": ",", "action": {"type": "parameterSeparator"}, "gridPosition": {"row": 6, "column": 3}, "type": "secondary"}
执行按键：{"id": "btn_execute_auto", "label": "执行", "action": {"type": "functionExecute"}, "gridPosition": {"row": 6, "column": 4}, "type": "operator"}

位置选择策略：
1. 优先使用布局的最后一行右侧位置
2. 如果最后一行已满，扩展到新行
3. 确保逗号在执行键左侧（操作顺序逻辑）
4. 自动更新layout.rows和layout.columns
```

🚨 按钮字段规范：
- 必需字段：id, label, action, gridPosition, type
- gridPosition格式：{"row": 数字, "column": 数字}
- action格式：{"type": "类型", "value": "值"} 或 {"type": "expression", "expression": "表达式"}

📐 **严格布局规则（禁止无效按键）**：
```
标准布局（5行×4列 = 20个位置最多）：
行1: [AC] [±] [%] [÷]      - 功能行
行2: [7] [8] [9] [×]       - 数字+运算符
行3: [4] [5] [6] [-]       - 数字+运算符  
行4: [1] [2] [3] [+]       - 数字+运算符
行5: [0] [.] [=] [功能]     - 底行

扩展布局（最多6行×5列 = 30个位置）：
只在用户明确需要科学函数时才使用第5列和第6行

⚠️ 严禁超出6行×5列的限制
⚠️ 必须清理所有无效和空的按键
```

🔧 **位置建议**：
- 数字0: row=5,col=0 | 数字1: row=4,col=0 | 数字2: row=4,col=1 | 数字3: row=4,col=2
- 数字4: row=3,col=0 | 数字5: row=3,col=1 | 数字6: row=3,col=2
- 数字7: row=2,col=0 | 数字8: row=2,col=1 | 数字9: row=2,col=2
- 运算符÷: row=1,col=3 | ×: row=2,col=3 | -: row=3,col=3 | +: row=4,col=3
- 等号=: row=5,col=2 | 小数点.: row=5,col=1 | AC: row=1,col=0

🚨 数学函数修复：
❌ 错误：Math.sin(x), Math.sqrt(x), parseInt(x)
✅ 正确：sin(x), sqrt(x), x*x

🎯 科学函数位置：
- 优先使用column=4,5,6放置sin, cos, tan, log, ln, sqrt, x², x³等
- 保持功能按钮的逻辑分组

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
    """切换AI模型"""
    global current_model_key
    
    if model_key not in AVAILABLE_MODELS:
        raise HTTPException(status_code=400, detail=f"不支持的模型: {model_key}")
    
    old_model = current_model_key
    current_model_key = model_key
    
    # 重新初始化模型
    try:
        initialize_genai()
        return {
            "message": f"成功切换模型: {old_model} → {model_key}",
            "old_model": AVAILABLE_MODELS[old_model]["name"],
            "new_model": AVAILABLE_MODELS[model_key]["name"],
            "model_key": model_key
        }
    except Exception as e:
        # 如果切换失败，回滚到原模型
        current_model_key = old_model
        raise HTTPException(status_code=500, detail=f"切换模型失败: {str(e)}")

@app.post("/customize")
async def customize_calculator(request: CustomizationRequest) -> CalculatorConfig:
    try:
        # 🛡️ 图像生成工坊保护检查
        protected_fields = []
        workshop_protection_info = ""
        
        if request.current_config and request.has_image_workshop_content:
            # 检测图像生成工坊生成的内容
            theme = request.current_config.get('theme', {})
            layout = request.current_config.get('layout', {})
            app_background = request.current_config.get('appBackground', {})
            
            # 🎨 检查APP背景配置（优先级最高）
            if app_background.get('backgroundImageUrl'):
                protected_fields.extend([
                    'appBackground.backgroundImageUrl',
                    'appBackground.backgroundType',
                    'appBackground.backgroundColor',
                    'appBackground.backgroundGradient',
                    'appBackground.backgroundOpacity'
                ])
            
            # 检查主题背景图
            if theme.get('backgroundImage'):
                protected_fields.extend(['theme.backgroundImage', 'theme.backgroundColor', 'theme.backgroundGradient'])
            
            # 检查背景图案
            if theme.get('backgroundPattern'):
                protected_fields.extend(['theme.backgroundPattern', 'theme.patternColor', 'theme.patternOpacity'])
            
            # 检查按钮背景图
            for button in layout.get('buttons', []):
                if button.get('backgroundImage'):
                    protected_fields.append(f'button.{button.get("id", "unknown")}.backgroundImage')
            
            if protected_fields:
                workshop_protection_info = f"""
🛡️ 【图像生成工坊保护】
检测到以下内容由图像生成工坊生成，AI设计师严格禁止修改：
{chr(10).join([f"- {field}" for field in protected_fields])}

⚠️ 如需修改这些图像内容，请使用图像生成工坊，或开启全新对话重新设计。
AI设计师只能修改按钮功能逻辑，不能覆盖工坊生成的图像内容。
"""
        
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

{workshop_protection_info}

🎯 【用户当前需求】
{request.user_input}

🚨 【严格执行要求】
1. 只修改用户明确要求的功能或外观
2. 禁止添加用户未要求的新功能
3. 禁止更改用户未提及的颜色、布局、按钮
4. 如果用户只要求改颜色，就只改颜色
5. 如果用户只要求添加某个功能，就只添加该功能
6. 严格保持所有未提及的配置不变
7. 🛡️ 严格遵守图像生成工坊保护规则，不得修改受保护的图像字段

请严格按照用户需求生成配置JSON，不得超出要求范围。
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
            json_start = response_text.find('[')
            json_end = response_text.rfind(']')
            if json_start != -1 and json_end != -1:
                config_json = response_text[json_start:json_end+1]
            else:
                config_json = response_text
        
        print(f"🔍 提取的JSON长度: {len(config_json)} 字符")
        print(f"🔍 JSON前100字符: {config_json[:100]}")
        
        try:
            # AI现在应该返回完整的配置JSON
            ai_generated_config = json.loads(config_json)
            if not isinstance(ai_generated_config, dict):
                raise HTTPException(status_code=500, detail="AI未能生成有效的配置JSON")
            
            # 🧹 清理AI生成的格式问题（如渐变色格式）
            ai_generated_config = clean_gradient_format(ai_generated_config)
            
            # 🛡️ 图像生成工坊保护：直接移除AI输出中的受保护字段
            if request.has_image_workshop_content:
                ai_generated_config = remove_protected_fields_from_ai_output(ai_generated_config, protected_fields)
            
            # 🛡️ 图像生成工坊保护：强制保持受保护的字段
            if request.current_config and protected_fields:
                final_config = copy.deepcopy(ai_generated_config)
                current_theme = request.current_config.get('theme', {})
                current_layout = request.current_config.get('layout', {})
                current_app_background = request.current_config.get('appBackground', {})
                
                # 🎨 保护APP背景配置（优先级最高）
                app_bg_fields = ['appBackground.backgroundImageUrl', 'appBackground.backgroundType', 
                                'appBackground.backgroundColor', 'appBackground.backgroundGradient', 
                                'appBackground.backgroundOpacity']
                if any(field in protected_fields for field in app_bg_fields):
                    final_config['appBackground'] = current_app_background
                
                # 保护主题中的图像字段
                if 'theme.backgroundImage' in protected_fields:
                    final_config.setdefault('theme', {})['backgroundImage'] = current_theme.get('backgroundImage')
                if 'theme.backgroundColor' in protected_fields:
                    final_config.setdefault('theme', {})['backgroundColor'] = current_theme.get('backgroundColor')
                if 'theme.backgroundGradient' in protected_fields:
                    final_config.setdefault('theme', {})['backgroundGradient'] = current_theme.get('backgroundGradient')
                if 'theme.backgroundPattern' in protected_fields:
                    final_config.setdefault('theme', {})['backgroundPattern'] = current_theme.get('backgroundPattern')
                    final_config.setdefault('theme', {})['patternColor'] = current_theme.get('patternColor')
                    final_config.setdefault('theme', {})['patternOpacity'] = current_theme.get('patternOpacity')
                
                # 保护按钮中的背景图
                current_buttons = {btn.get('id'): btn for btn in current_layout.get('buttons', [])}
                final_buttons = final_config.get('layout', {}).get('buttons', [])
                for button in final_buttons:
                    button_id = button.get('id')
                    if f'button.{button_id}.backgroundImage' in protected_fields:
                        current_button = current_buttons.get(button_id, {})
                        if current_button.get('backgroundImage'):
                            button['backgroundImage'] = current_button['backgroundImage']
            else:
                # 如果没有当前配置，直接使用AI生成的配置
                if not request.current_config:
                    final_config = ai_generated_config
                else:
                    # 有当前配置但没有保护字段，进行智能合并
                    # 这里的问题：AI虽然不输出样式字段，但AI输出的JSON结构可能包含空的样式字段
                    # 我们需要只合并AI实际有内容的字段，而不是全量覆盖
                    final_config = copy.deepcopy(request.current_config)
                    
                    # 智能合并AI生成的主题更改（只合并非空字段）
                    if 'theme' in ai_generated_config and ai_generated_config['theme']:
                        current_theme = final_config.setdefault('theme', {})
                        ai_theme = ai_generated_config['theme']
                        
                        # 只更新AI实际输出的非空字段
                        for key, value in ai_theme.items():
                            if value is not None and value != "":
                                current_theme[key] = value
                    
                    # 智能合并AI生成的布局更改
                    if 'layout' in ai_generated_config and ai_generated_config['layout']:
                        current_layout = final_config.setdefault('layout', {})
                        ai_layout = ai_generated_config['layout']
                        
                        # 对于布局，我们主要关心buttons数组的更新
                        if 'buttons' in ai_layout:
                            current_layout['buttons'] = ai_layout['buttons']
                        
                        # 其他布局字段只在非空时更新
                        for key, value in ai_layout.items():
                            if key != 'buttons' and value is not None and value != "":
                                current_layout[key] = value
            
            # 🧹 首先清理无效按键
            final_config = clean_invalid_buttons(final_config)
            
            # 运行修复和验证程序
            fixed_config = await fix_calculator_config(
                request.user_input, 
                request.current_config, # 传入旧配置以供参考
                final_config # 传入清理并合并后的配置进行修复
            )
            
        except json.JSONDecodeError as e:
            print(f"❌ JSON解析失败: {str(e)}")
            print(f"📄 原始响应: {response_text[:500]}")
            raise HTTPException(status_code=500, detail=f"AI生成的JSON格式无效: {str(e)}")
        
        print("✅ AI响应处理和样式保护完成")
        
        # 创建完整的配置对象
        app_background_data = fixed_config.get('appBackground')
        app_background = AppBackground(**app_background_data) if app_background_data else None
        
        config = CalculatorConfig(
            id=f"calc_{int(time.time())}",
            name=fixed_config.get('name', '自定义计算器'),
            description=fixed_config.get('description', '由AI修复的计算器配置'),
            theme=CalculatorTheme(**fixed_config.get('theme', {})),
            layout=CalculatorLayout(**fixed_config.get('layout', {})),
            version="1.0.0",
            createdAt=datetime.now().isoformat(),
            authorPrompt=request.user_input,
            thinkingProcess=response_text if "思考过程" in response_text else None,
            aiResponse=f"✅ 成功修复计算器配置",
            appBackground=app_background
        )
        
        return config
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"修复计算器配置时出错: {str(e)}")
        raise HTTPException(status_code=500, detail=f"修复计算器配置失败: {str(e)}")

def remove_protected_fields_from_ai_output(config_dict: dict, protected_fields: list) -> dict:
    """
    直接从AI输出中移除受保护的字段，确保AI设计师无法影响图像生成工坊的内容
    """
    if not protected_fields:
        return config_dict
    
    # 深拷贝配置以避免修改原始数据
    cleaned_config = copy.deepcopy(config_dict)
    
    print(f"🛡️ 开始清理AI输出中的受保护字段: {protected_fields}")
    
    # 🎨 清理APP背景中的受保护字段
    app_bg_protected_fields = [
        'backgroundImageUrl', 'backgroundType', 'backgroundColor',
        'backgroundGradient', 'backgroundOpacity', 'backgroundBlendMode',
        'parallaxEffect', 'parallaxIntensity'
    ]
    
    if 'appBackground' in cleaned_config:
        for field in app_bg_protected_fields:
            if f'appBackground.{field}' in protected_fields or 'appBackground.*' in protected_fields:
                if field in cleaned_config['appBackground']:
                    print(f"🧹 移除AI输出中的APP背景字段: appBackground.{field}")
                    del cleaned_config['appBackground'][field]
    
    # 清理主题中的受保护字段
    theme_protected_fields = [
        'backgroundColor', 'backgroundGradient', 'backgroundImage',
        'backgroundPattern', 'patternColor', 'patternOpacity',
        'displayBackgroundColor', 'displayBackgroundGradient',
        'primaryButtonColor', 'primaryButtonGradient', 'primaryButtonTextColor',
        'secondaryButtonColor', 'secondaryButtonGradient', 'secondaryButtonTextColor',
        'operatorButtonColor', 'operatorButtonGradient', 'operatorButtonTextColor',
        'fontSize', 'fontFamily', 'hasGlowEffect', 'shadowColor',
        'buttonElevation', 'buttonShadowColors'
    ]
    
    if 'theme' in cleaned_config:
        for field in theme_protected_fields:
            if f'theme.{field}' in protected_fields or 'theme.*' in protected_fields:
                if field in cleaned_config['theme']:
                    print(f"🧹 移除AI输出中的主题字段: theme.{field}")
                    del cleaned_config['theme'][field]
    
    # 清理按钮中的受保护字段
    button_protected_fields = [
        'backgroundColor', 'textColor', 'backgroundImage', 'customIcon',
        'fontSize', 'borderRadius', 'elevation', 'shadowColor',
        'gradientColors', 'backgroundPattern', 'patternColor'
    ]
    
    if 'layout' in cleaned_config and 'buttons' in cleaned_config['layout']:
        for button in cleaned_config['layout']['buttons']:
            button_id = button.get('id', 'unknown')
            for field in button_protected_fields:
                field_path = f'button.{button_id}.{field}'
                if field_path in protected_fields or f'button.*.{field}' in protected_fields:
                    if field in button:
                        print(f"🧹 移除AI输出中的按钮字段: {field_path}")
                        del button[field]
    
    print(f"🛡️ 完成清理受保护字段")
    return cleaned_config

def clean_gradient_format(config_dict: dict) -> dict:
    """清理AI生成的渐变色格式，将对象格式转换为数组格式"""
    def process_gradient(gradient_value):
        if isinstance(gradient_value, dict):
            # AI生成的格式：{"colors": ["#FF0000", "#800000"], "direction": "vertical"}
            if "colors" in gradient_value:
                return gradient_value["colors"]
            # 其他对象格式，提取颜色数组
            elif "type" in gradient_value and "colors" in gradient_value:
                return gradient_value["colors"]
        elif isinstance(gradient_value, list):
            # 已经是正确格式
            return gradient_value
        return None
    
    # 处理主题中的渐变色字段
    if "theme" in config_dict:
        theme = config_dict["theme"]
        gradient_fields = [
            "backgroundGradient", "displayBackgroundGradient", 
            "primaryButtonGradient", "secondaryButtonGradient", 
            "operatorButtonGradient"
        ]
        
        for field in gradient_fields:
            if field in theme and theme[field] is not None:
                cleaned_gradient = process_gradient(theme[field])
                if cleaned_gradient is not None:
                    theme[field] = cleaned_gradient
                else:
                    # 如果无法解析，移除该字段
                    del theme[field]
    
    # 处理按钮中的渐变色字段
    if "layout" in config_dict and "buttons" in config_dict["layout"]:
        for button in config_dict["layout"]["buttons"]:
            if "gradientColors" in button and button["gradientColors"] is not None:
                cleaned_gradient = process_gradient(button["gradientColors"])
                if cleaned_gradient is not None:
                    button["gradientColors"] = cleaned_gradient
                else:
                    del button["gradientColors"]
    
    return config_dict

def clean_invalid_buttons(config_dict: dict) -> dict:
    """清理无效按键，确保所有按键都有实际功能"""
    if "layout" not in config_dict or "buttons" not in config_dict["layout"]:
        return config_dict
    
    original_buttons = config_dict["layout"]["buttons"]
    valid_buttons = []
    
    print(f"🔍 开始清理无效按键，原始按键数量: {len(original_buttons)}")
    
    for button in original_buttons:
        # 检查按键是否有效
        is_valid = True
        invalid_reasons = []
        
        # 检查label
        if not button.get("label") or str(button.get("label")).strip() == "":
            is_valid = False
            invalid_reasons.append("label为空")
        
        # 检查action
        action = button.get("action")
        if not action or not isinstance(action, dict) or not action.get("type"):
            is_valid = False
            invalid_reasons.append("action无效")
        
        # 检查gridPosition
        grid_pos = button.get("gridPosition")
        if not grid_pos or not isinstance(grid_pos, dict):
            is_valid = False
            invalid_reasons.append("gridPosition无效")
        else:
            row = grid_pos.get("row", 0)
            col = grid_pos.get("column", 0)
            # 限制在合理范围内：最多6行×5列
            if row < 1 or row > 6 or col < 0 or col > 4:
                is_valid = False
                invalid_reasons.append(f"位置超出范围(row={row}, col={col})")
        
        # 检查是否重复
        if is_valid:
            # 检查是否已存在相同label的按键
            existing_labels = [btn.get("label") for btn in valid_buttons]
            if button.get("label") in existing_labels:
                is_valid = False
                invalid_reasons.append("重复按键")
        
        if is_valid:
            valid_buttons.append(button)
        else:
            print(f"❌ 移除无效按键: {button.get('label', '未知')} - {', '.join(invalid_reasons)}")
    
    # 更新按键列表
    config_dict["layout"]["buttons"] = valid_buttons
    
    # 更新rows和columns以适应实际按键
    if valid_buttons:
        max_row = max(btn.get("gridPosition", {}).get("row", 1) for btn in valid_buttons)
        max_col = max(btn.get("gridPosition", {}).get("column", 0) for btn in valid_buttons)
        config_dict["layout"]["rows"] = max_row
        config_dict["layout"]["columns"] = max_col + 1  # column是0-based
    
    print(f"✅ 按键清理完成，有效按键数量: {len(valid_buttons)}")
    
    # 🚨 多参数函数必需按键检测与自动添加
    has_multi_param_functions = any(
        btn.get("action", {}).get("type") == "multiParamFunction" 
        for btn in valid_buttons
    )
    
    if has_multi_param_functions:
        print("🔍 检测到多参数函数，检查是否需要添加逗号和执行按键")
        
        # 检查是否已存在逗号分隔符和执行按键
        has_comma = any(
            btn.get("action", {}).get("type") == "parameterSeparator"
            for btn in valid_buttons
        )
        has_execute = any(
            btn.get("action", {}).get("type") == "functionExecute"
            for btn in valid_buttons
        )
        
        # 计算下一个可用位置
        if valid_buttons:
            max_row = max(btn.get("gridPosition", {}).get("row", 1) for btn in valid_buttons)
            max_col = max(btn.get("gridPosition", {}).get("column", 0) for btn in valid_buttons)
        else:
            max_row = 5
            max_col = 3
        
        # 自动添加缺失的按键
        if not has_comma:
            comma_button = {
                "id": "btn_comma_auto",
                "label": ",",
                "action": {"type": "parameterSeparator"},
                "gridPosition": {"row": max_row + 1, "column": max_col},
                "type": "secondary"
            }
            valid_buttons.append(comma_button)
            print("✅ 自动添加逗号分隔符按键")
            max_col += 1
        
        if not has_execute:
            execute_button = {
                "id": "btn_execute_auto", 
                "label": "执行",
                "action": {"type": "functionExecute"},
                "gridPosition": {"row": max_row + 1, "column": max_col},
                "type": "operator"
            }
            valid_buttons.append(execute_button)
            print("✅ 自动添加执行按键")
        
        # 更新布局尺寸
        if valid_buttons:
            max_row = max(btn.get("gridPosition", {}).get("row", 1) for btn in valid_buttons)
            max_col = max(btn.get("gridPosition", {}).get("column", 0) for btn in valid_buttons)
            config_dict["layout"]["rows"] = max_row
            config_dict["layout"]["columns"] = max_col + 1
            print(f"📐 更新布局尺寸: {max_row}行 × {max_col + 1}列")
    
    # 更新最终按键列表
    config_dict["layout"]["buttons"] = valid_buttons
    
    return config_dict

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

class ImageGenerationRequest(BaseModel):
    prompt: str = Field(..., description="图像生成提示词")
    style: Optional[str] = Field(default="realistic", description="图像风格")
    size: Optional[str] = Field(default="1024x1024", description="图像尺寸")
    quality: Optional[str] = Field(default="standard", description="图像质量")

class AppBackgroundRequest(BaseModel):
    prompt: str = Field(..., description="背景图生成提示词")
    style: Optional[str] = Field(default="modern", description="背景风格")
    size: Optional[str] = Field(default="1080x1920", description="背景图尺寸，适配手机屏幕")
    quality: Optional[str] = Field(default="high", description="图像质量")
    theme: Optional[str] = Field(default="calculator", description="主题类型：calculator, abstract, nature, tech等")

@app.post("/generate-image")
async def generate_image(request: ImageGenerationRequest):
    """使用Gemini 2.0 Flash原生图像生成功能"""
    try:
        # 构建优化的图像生成提示词
        enhanced_prompt = f"""
        Generate a high-quality image for calculator theme:
        {request.prompt}
        
        Style: {request.style}
        Requirements:
        - High resolution and professional quality
        - Suitable for calculator app background or button design
        - Clean, modern aesthetic
        - Good contrast for readability
        """
        
        print(f"🎨 开始生成图像，提示词: {enhanced_prompt}")
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成图像 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        response = image_model.generate_content(
            contents=[enhanced_prompt],
            generation_config=generation_config
        )
        
        # 检查响应中是否包含图像
        if hasattr(response, 'parts') and response.parts:
            for part in response.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    # 获取生成的图像数据
                    image_data = part.inline_data.data
                    mime_type = part.inline_data.mime_type
                    
                    # 检查数据是否已经是base64格式
                    if isinstance(image_data, bytes):
                        # 如果是bytes，需要转换为base64
                        import base64
                        image_base64_data = base64.b64encode(image_data).decode('utf-8')
                    else:
                        # 如果已经是字符串，直接使用
                        image_base64_data = str(image_data)
                    
                    # 将图像数据转换为base64 URL
                    image_base64 = f"data:{mime_type};base64,{image_base64_data}"
                    
                    print(f"✅ 图像生成成功，MIME类型: {mime_type}")
                    
                    return {
                        "success": True,
                        "image_url": image_base64,
                        "image_data": image_base64_data,
                        "mime_type": mime_type,
                        "original_prompt": request.prompt,
                        "enhanced_prompt": enhanced_prompt,
                        "style": request.style,
                        "size": request.size,
                        "quality": request.quality,
                        "message": "图像生成成功"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图像，返回错误
        raise HTTPException(status_code=500, detail="未能生成图像，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"图像生成失败: {str(e)}")
        # 返回占位符图像作为备用方案
        placeholder_url = f"https://via.placeholder.com/{request.size.replace('x', 'x')}/4A90E2/FFFFFF?text=AI+Image+Error"
        
        return {
            "success": False,
            "image_url": placeholder_url,
            "original_prompt": request.prompt,
            "error": str(e),
            "message": f"图像生成失败，使用占位符: {str(e)}"
        }

@app.post("/generate-pattern")
async def generate_pattern(request: ImageGenerationRequest):
    """使用Gemini 2.0 Flash生成按钮背景图案"""
    try:
        # 针对按钮图案的特殊处理
        pattern_prompt = f"""
        Generate a seamless pattern for calculator button background:
        {request.prompt}
        
        Requirements:
        - Seamless and tileable pattern
        - Suitable for button background use
        - Subtle and not distracting from text
        - Style: {request.style}
        - High contrast for text readability
        - Professional and clean design
        - 256x256 pixels optimal size
        """
        
        print(f"🎨 开始生成图案，提示词: {pattern_prompt}")
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成图案 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        response = image_model.generate_content(
            contents=[pattern_prompt],
            generation_config=generation_config
        )
        
        # 检查响应中是否包含图像
        if hasattr(response, 'parts') and response.parts:
            for part in response.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    # 获取生成的图像数据
                    image_data = part.inline_data.data
                    mime_type = part.inline_data.mime_type
                    
                    # 检查数据是否已经是base64格式
                    if isinstance(image_data, bytes):
                        # 如果是bytes，需要转换为base64
                        import base64
                        pattern_base64_data = base64.b64encode(image_data).decode('utf-8')
                    else:
                        # 如果已经是字符串，直接使用
                        pattern_base64_data = str(image_data)
                    
                    # 将图像数据转换为base64 URL
                    pattern_base64 = f"data:{mime_type};base64,{pattern_base64_data}"
                    
                    print(f"✅ 图案生成成功，MIME类型: {mime_type}")
                    
                    return {
                        "success": True,
                        "pattern_url": pattern_base64,
                        "image_data": pattern_base64_data,
                        "mime_type": mime_type,
                        "original_prompt": request.prompt,
                        "enhanced_prompt": pattern_prompt,
                        "style": request.style,
                        "is_seamless": True,
                        "message": "图案生成成功"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图案，返回错误
        raise HTTPException(status_code=500, detail="未能生成图案，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"图案生成失败: {str(e)}")
        # 返回占位符图案作为备用方案
        placeholder_url = f"https://via.placeholder.com/256x256/4A90E2/FFFFFF?text=Pattern+Error"
        
        return {
            "success": False,
            "pattern_url": placeholder_url,
            "original_prompt": request.prompt,
            "error": str(e),
            "message": f"图案生成失败，使用占位符: {str(e)}"
        }

@app.post("/generate-app-background")
async def generate_app_background(request: AppBackgroundRequest):
    """生成APP整体背景图"""
    try:
        # 构建专门的APP背景图生成提示词
        background_prompt = f"""
        Generate a beautiful background image for a calculator mobile app:
        {request.prompt}
        
        Requirements:
        - Mobile app background (portrait orientation {request.size})
        - Style: {request.style} with {request.theme} theme
        - Subtle and elegant, won't interfere with UI elements
        - Good contrast for calculator buttons and display
        - Professional and modern aesthetic
        - High quality and resolution
        - Colors should complement calculator interface
        - Avoid too busy patterns that distract from functionality
        
        Theme context: {request.theme}
        Quality: {request.quality}
        """
        
        print(f"🎨 开始生成APP背景图，提示词: {background_prompt}")
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成背景图 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        response = image_model.generate_content(
            contents=[background_prompt],
            generation_config=generation_config
        )
        
        # 检查响应中是否包含图像
        if hasattr(response, 'parts') and response.parts:
            for part in response.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    # 获取生成的图像数据
                    image_data = part.inline_data.data
                    mime_type = part.inline_data.mime_type
                    
                    # 检查数据是否已经是base64格式
                    if isinstance(image_data, bytes):
                        # 如果是bytes，需要转换为base64
                        import base64
                        background_base64_data = base64.b64encode(image_data).decode('utf-8')
                    else:
                        # 如果已经是字符串，直接使用
                        background_base64_data = str(image_data)
                    
                    # 将图像数据转换为base64 URL
                    background_base64 = f"data:{mime_type};base64,{background_base64_data}"
                    
                    print(f"✅ APP背景图生成成功，MIME类型: {mime_type}")
                    
                    return {
                        "success": True,
                        "background_url": background_base64,
                        "image_data": background_base64_data,
                        "mime_type": mime_type,
                        "original_prompt": request.prompt,
                        "enhanced_prompt": background_prompt,
                        "style": request.style,
                        "theme": request.theme,
                        "size": request.size,
                        "quality": request.quality,
                        "message": "APP背景图生成成功",
                        "usage_tips": "此背景图已优化用于计算器应用，确保UI元素的可读性"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成背景图，返回错误
        raise HTTPException(status_code=500, detail="未能生成APP背景图，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"APP背景图生成失败: {str(e)}")
        # 返回占位符背景图作为备用方案
        placeholder_url = f"https://via.placeholder.com/{request.size.replace('x', 'x')}/1E1E1E/FFFFFF?text=Background+Error"
        
        return {
            "success": False,
            "background_url": placeholder_url,
            "original_prompt": request.prompt,
            "error": str(e),
            "message": f"APP背景图生成失败，使用占位符: {str(e)}"
        }

@app.get("/background-presets")
async def get_background_presets():
    """获取预设的背景图模板"""
    return {
        "success": True,
        "presets": [
            {
                "id": "modern_gradient",
                "name": "现代渐变",
                "description": "简洁的渐变背景，适合现代风格",
                "prompt": "modern gradient background with subtle geometric patterns",
                "style": "modern",
                "theme": "calculator",
                "preview_url": "https://via.placeholder.com/300x500/4A90E2/FFFFFF?text=Modern+Gradient"
            },
            {
                "id": "tech_circuit",
                "name": "科技电路",
                "description": "科技感电路板背景，适合数字风格",
                "prompt": "futuristic circuit board pattern with neon accents",
                "style": "cyberpunk",
                "theme": "tech",
                "preview_url": "https://via.placeholder.com/300x500/0F0F23/00FF88?text=Tech+Circuit"
            },
            {
                "id": "minimal_abstract",
                "name": "极简抽象",
                "description": "简约抽象几何图形背景",
                "prompt": "minimal abstract geometric shapes with soft colors",
                "style": "minimal",
                "theme": "abstract",
                "preview_url": "https://via.placeholder.com/300x500/F5F5F5/333333?text=Minimal+Abstract"
            },
            {
                "id": "nature_calm",
                "name": "自然宁静",
                "description": "自然风景背景，营造宁静氛围",
                "prompt": "calm nature landscape with soft lighting",
                "style": "realistic",
                "theme": "nature",
                "preview_url": "https://via.placeholder.com/300x500/87CEEB/FFFFFF?text=Nature+Calm"
            },
            {
                "id": "dark_professional",
                "name": "专业深色",
                "description": "专业的深色背景，适合商务使用",
                "prompt": "professional dark background with subtle texture",
                "style": "professional",
                "theme": "calculator",
                "preview_url": "https://via.placeholder.com/300x500/1A1A1A/FFFFFF?text=Dark+Professional"
            }
        ]
    }

class TextImageRequest(BaseModel):
    prompt: str = Field(..., description="创意字符生成描述，如'用橘猫身体组成数字'")
    text: str = Field(..., description="要生成的字符/文字内容")
    style: Optional[str] = Field(default="modern", description="视觉风格：modern, neon, gold, silver, fire, ice, galaxy等")
    size: Optional[str] = Field(default="512x512", description="图像尺寸")
    background: Optional[str] = Field(default="transparent", description="背景类型：transparent, dark, light, gradient")
    effects: Optional[List[str]] = Field(default=[], description="视觉效果列表")

@app.post("/generate-text-image")
async def generate_text_image(request: TextImageRequest):
    """生成创意字符图片 - 用指定元素构造字符形状"""
    try:
        print(f"🎨 正在生成创意字符图片...")
        print(f"字符内容: {request.text}")
        print(f"原始创意描述: {request.prompt}")
        print(f"风格: {request.style}")
        
        # 🧹 清理用户输入，去除描述性文字，只保留创意核心
        def clean_user_prompt(prompt: str) -> str:
            """清理用户输入的提示词，去除描述性文字，只保留创意核心"""
            if not prompt:
                return ""
            
            # 需要过滤的描述性词汇和短语
            descriptive_phrases = [
                "生成", "图片", "效果", "光影", "文字", "数字", "字符", "符号",
                "为", "的", "进行", "制作", "创建", "设计", "绘制",
                "生成光影效果", "光影效果图片", "效果图片", "文字图片", 
                "数字图片", "字符图片", "背景图", "按键", "按钮",
                "白底", "透明", "背景", "底色", "不能有其他字出现",
                "生成光影效果的图片", "为文字.*?生成.*?图片", "光影文字", "特效"
            ]
            
            cleaned = prompt.strip()
            
            # 移除描述性短语
            import re
            for phrase in descriptive_phrases:
                # 使用正则表达式匹配包含这些短语的部分
                pattern = f"[，。、]*{re.escape(phrase)}[^，。]*"
                cleaned = re.sub(pattern, "", cleaned, flags=re.IGNORECASE)
                
                # 移除完整短语
                cleaned = cleaned.replace(phrase, "")
            
            # 清理多余的标点符号和空格
            cleaned = re.sub(r'[，。、；：！？\s]+', ' ', cleaned)
            cleaned = re.sub(r'^[，。、；：！？\s]+|[，。、；：！？\s]+$', '', cleaned)
            cleaned = re.sub(r'\s+', ' ', cleaned).strip()
            
            return cleaned
        
        # 清理用户输入
        cleaned_prompt = clean_user_prompt(request.prompt) if request.prompt else ""
        print(f"清理后创意描述: {cleaned_prompt}")
        
        # 🎨 构建创意字符生成提示词，用指定元素构造字符形状
        # 根据风格选择不同的视觉风格描述
        style_effects = {
            "modern": "in sleek modern style",
            "neon": "in vibrant neon style with bright colors",
            "gold": "in luxurious golden metallic style", 
            "silver": "in polished silver metallic style",
            "fire": "in fiery red/orange style",
            "ice": "in crystal clear ice style",
            "galaxy": "in cosmic space style with stars",
            "glass": "in transparent glass crystal style"
        }
        
        # 获取对应风格的效果描述，默认为现代风格
        style_effect = style_effects.get(request.style, style_effects["modern"])
        
        # 🎨 创意字符构造：极简提示词，避免AI误解指令为显示内容
        if cleaned_prompt and cleaned_prompt.strip():
            # 极简直接指令，避免任何可能被误解的英文描述
            detailed_prompt = f"""Show number "{request.text}" made from {cleaned_prompt}. Pure visual art only. No text anywhere. Clean {request.background} background."""
        else:
            # 标准设计，同样极简
            detailed_prompt = f"""Show number "{request.text}" {style_effect}. Pure visual art only. No text anywhere. Clean {request.background} background."""

        print(f"🚀 使用提示词: {detailed_prompt}")

        # 使用图像生成专用模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        # 生成图像
        response = image_model.generate_content(
            contents=[detailed_prompt],
            generation_config=generation_config
        )
        
        # 检查响应中是否包含图像
        if hasattr(response, 'parts') and response.parts:
            for part in response.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    # 获取生成的图像数据
                    image_data = part.inline_data.data
                    mime_type = part.inline_data.mime_type
                    
                    # 检查数据是否已经是base64格式
                    if isinstance(image_data, bytes):
                        # 如果是bytes，需要转换为base64
                        import base64
                        text_image_base64_data = base64.b64encode(image_data).decode('utf-8')
                    else:
                        # 如果已经是字符串，直接使用
                        text_image_base64_data = str(image_data)
                    
                    # 将图像数据转换为base64 URL
                    text_image_base64 = f"data:{mime_type};base64,{text_image_base64_data}"
                    
                    print(f"✅ 创意字符图片生成成功: '{request.text}'，MIME类型: {mime_type}")
                    
                    return {
                        "success": True,
                        "image_url": text_image_base64,
                        "text": request.text,
                        "style": request.style,
                        "size": request.size,
                        "background": request.background,
                        "effects": request.effects,
                        "mime_type": mime_type,
                        "original_prompt": request.prompt,
                        "cleaned_prompt": cleaned_prompt,
                        "enhanced_prompt": detailed_prompt,
                        "message": f"创意字符 '{request.text}' 生成成功"
                    }
        
        # 检查是否有文本响应
        if hasattr(response, 'text') and response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图像，返回错误
        raise Exception("未找到生成的图像数据")
        
    except Exception as e:
        print(f"❌ 创意字符图片生成失败: {str(e)}")
        
        # 返回错误信息
        return {
            "success": False,
            "error": str(e),
            "text": request.text,
            "message": f"生成创意字符 '{request.text}' 失败: {str(e)}"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080))) 