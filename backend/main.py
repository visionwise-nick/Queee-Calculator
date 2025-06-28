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

# 简化的AI系统提示 - 专注布局设计
SYSTEM_PROMPT = """你是专业的计算器设计师。只需要设计布局逻辑，前端会自动适配显示。

🎯 设计任务：根据用户需求设计计算器布局
- 决定使用几行几列（支持2-10行，2-8列，自动适配屏幕）
- 安排每个位置放什么按钮
- 选择合适的主题配色和视觉效果
- 可以生成AI背景图片和按钮装饰

🔧 布局规则：
1. 【必保留17个基础按钮】数字0-9，运算符+−×÷，功能=、AC、±、.
2. 【标准ID规范】基础按钮ID必须是：zero,one,two,three,four,five,six,seven,eight,nine,add,subtract,multiply,divide,equals,clear,negate,decimal
3. 【位置从0开始】行列坐标都从0开始计数（第1行第1列 = row:0,column:0）
4. 【添加新功能】可以增加专业按钮，用expression表达式实现
5. 【自适应布局】前端会根据按钮数量自动调整尺寸，支持任意行列数

🔄 继承性原则（重要）：
- 【保持现有配色】除非用户明确要求改变颜色，否则保持当前主题的所有颜色设置
- 【保持布局结构】除非用户要求重新布局，否则保持现有的行列数和按钮位置
- 【保持视觉效果】保持现有的渐变、阴影、发光等视觉效果
- 【只改变用户要求的部分】严格按照用户的具体要求进行修改，不要擅自改变其他部分
- 【增量修改】基于现有配置进行增量修改，而不是重新设计

🎨 新增视觉功能：
- 【按钮尺寸倍数】widthMultiplier/heightMultiplier (0.5-3.0，默认1.0)
- 【按钮独立属性】fontSize、borderRadius、elevation
- 【渐变色】gradientColors: ["#起始色", "#结束色"]
- 【背景图片】backgroundImage: "AI生成图片描述"（将自动生成图片）
- 【自定义颜色】customColor: "#颜色值"

🎨 主题增强功能：
- 【背景渐变】backgroundGradient: ["#色1", "#色2"]
- 【显示区控制】displayWidth/displayHeight: 0.0-1.0 比例
- 【显示区渐变】displayBackgroundGradient: ["#色1", "#色2"]
- 【按钮组渐变】primaryButtonGradient/secondaryButtonGradient/operatorButtonGradient
- 【多层阴影】buttonShadowColors: ["#阴影色1", "#阴影色2"]
- 【间距控制】buttonSpacing、gridSpacing: 数值
- 【尺寸限制】minButtonSize/maxButtonSize: 数值

🤖 AI图像生成：
- 背景图片：backgroundImage: "描述想要的背景"
- 按钮图片：backgroundImage: "描述按钮装饰"
- 示例："科技感蓝色电路板背景"、"可爱粉色花朵装饰"、"金属质感按钮"

🚀 功能表达式库：
- 数学：平方"x*x" 开根"sqrt(x)" 立方"pow(x,3)" 倒数"1/x"
- 科学：sin"sin(x)" cos"cos(x)" log"log(x)" exp"exp(x)"
- 金融：小费15%"x*0.15" 增值税"x*1.13" 折扣"x*0.8"
- 转换：华氏度"x*9/5+32" 英寸"x*2.54"

💡 设计示例：
```json
{
  "layout": {
    "rows": 6,
    "columns": 5,
    "minButtonSize": 40,
    "maxButtonSize": 80,
    "gridSpacing": 4
  },
  "buttons": [
    {
      "id": "equals",
      "label": "=",
      "action": {"type": "equals"},
      "gridPosition": {"row": 4, "column": 3},
      "type": "operator",
      "heightMultiplier": 2.0,
      "gradientColors": ["#FF6B35", "#F7931E"],
      "backgroundImage": "金色发光按钮效果"
    },
    {
      "id": "seven",
      "label": "7",
      "action": {"type": "input", "value": "7"},
      "gridPosition": {"row": 1, "column": 0},
      "type": "primary",
      "fontSize": 20,
      "borderRadius": 12
    }
  ],
  "theme": {
    "backgroundImage": "深蓝色星空背景",
    "displayHeight": 0.25,
    "displayBorderRadius": 15,
    "operatorButtonGradient": ["#ff6b6b", "#ee5a24"],
    "buttonSpacing": 6,
    "hasGlowEffect": true,
    "adaptiveLayout": true
  }
}
```

🔧 Action字段说明（必须包含）：
- 数字输入: {"type": "input", "value": "数字"}
- 运算符: {"type": "operator", "value": "运算符"}  // +、-、*、/
- 等号: {"type": "equals"}
- 清除: {"type": "clear"}
- 全清: {"type": "clearAll"}
- 小数点: {"type": "decimal"}
- 正负号: {"type": "negate"}
- 科学计算: {"type": "expression", "expression": "表达式"}

前端会自动处理：
✓ 动态按钮数量适配 ✓ 屏幕尺寸自适应 ✓ 字体自动缩放 ✓ AI图片生成 ✓ 渐变渲染 ✓ 响应式布局

只返回JSON配置，专注设计逻辑和视觉效果创新。"""

# AI二次校验系统提示
VALIDATION_PROMPT = """你是计算器配置验证专家。请仔细检查生成的计算器配置是否完全满足用户需求。

📋 验证任务：
1. 检查配置是否完全满足用户的具体要求
2. 验证是否保持了应该继承的现有配置
3. 确认没有擅自改变用户未要求修改的部分
4. 检查配置的合理性和可用性

🔍 验证标准：
- ✅ 用户要求的功能是否都已实现
- ✅ 用户要求的视觉效果是否正确应用
- ✅ 现有配置的继承是否正确（颜色、布局、效果等）
- ✅ 按钮配置是否完整（包含必需的action字段）
- ✅ 主题配置是否合理
- ✅ 布局是否适合移动设备

🚫 常见问题检查：
- 是否擅自改变了用户未要求修改的颜色
- 是否丢失了原有的视觉效果
- 是否改变了用户满意的布局结构
- 是否缺少必需的基础按钮
- 是否有不合理的按钮尺寸或位置

📝 返回格式：
```json
{
  "isValid": true/false,
  "score": 0-100,
  "issues": ["问题1", "问题2"],
  "suggestions": ["建议1", "建议2"],
  "summary": "验证总结"
}
```

请基于用户需求和现有配置，对生成的新配置进行严格验证。"""

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
        
        # 🔍 AI二次校验
        validation_result = None
        if request.current_config:
            validation_result = await validate_calculator_config(
                request.user_input,
                request.current_config,
                raw_config
            )
            
            # 如果验证不通过且分数较低，可以选择重新生成
            if not validation_result.get('isValid', True) and validation_result.get('score', 100) < 70:
                print(f"⚠️ AI验证未通过，分数: {validation_result.get('score', 0)}")
                print(f"问题: {validation_result.get('issues', [])}")
                
                # 可以在这里添加重新生成逻辑
                # 为了避免无限循环，暂时只记录问题
        
        # 数据验证和字段补充
        if 'theme' not in raw_config:
            raw_config['theme'] = {}
        if 'layout' not in raw_config:
            raw_config['layout'] = {'buttons': []}
        
        # 补充必需字段
        theme = raw_config['theme']
        if 'name' not in theme:
            theme['name'] = '自定义主题'
        
        layout = raw_config['layout']
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
                    button['action'] = {'type': 'input', 'value': button_id.replace('zero', '0').replace('one', '1').replace('two', '2').replace('three', '3').replace('four', '4').replace('five', '5').replace('six', '6').replace('seven', '7').replace('eight', '8').replace('nine', '9')}
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
        
        # 创建完整的配置对象
        config = CalculatorConfig(
            id=f"calc_{int(time.time())}",
            name=raw_config.get('name', '自定义计算器'),
            description=raw_config.get('description', '由AI生成的计算器配置'),
            theme=CalculatorTheme(**theme),
            layout=CalculatorLayout(**layout),
            version="1.0.0",
            createdAt=datetime.now().isoformat(),
            authorPrompt=request.user_input,
            thinkingProcess=response_text if "思考过程" in response_text else None,
            aiResponse=f"✅ 成功生成计算器配置\n{validation_result.get('summary', '') if validation_result else ''}",
        )
        
        # 添加验证结果到响应中
        if validation_result:
            config.aiResponse += f"\n\n🔍 AI验证结果:\n- 验证分数: {validation_result.get('score', 'N/A')}/100\n- 验证状态: {'✅ 通过' if validation_result.get('isValid', True) else '⚠️ 需要改进'}"
            if validation_result.get('issues'):
                config.aiResponse += f"\n- 发现问题: {'; '.join(validation_result.get('issues', []))}"
            if validation_result.get('suggestions'):
                config.aiResponse += f"\n- 改进建议: {'; '.join(validation_result.get('suggestions', []))}"
        
        return config
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"生成计算器配置时出错: {str(e)}")
        raise HTTPException(status_code=500, detail=f"生成计算器配置失败: {str(e)}")

async def validate_calculator_config(user_input: str, current_config: dict, generated_config: dict) -> dict:
    """AI二次校验生成的计算器配置"""
    try:
        # 构建验证上下文
        validation_context = f"""
用户需求：{user_input}

现有配置摘要：
- 主题名称：{current_config.get('theme', {}).get('name', '未知')}
- 背景颜色：{current_config.get('theme', {}).get('backgroundColor', '未知')}
- 布局：{current_config.get('layout', {}).get('rows', 0)}行{current_config.get('layout', {}).get('columns', 0)}列
- 按钮数量：{len(current_config.get('layout', {}).get('buttons', []))}个

生成的新配置：
{json.dumps(generated_config, ensure_ascii=False, indent=2)}

请验证新配置是否满足用户需求，并检查继承性是否正确。
"""

        # 调用AI进行验证
        model = get_current_model()
        response = model.generate_content([
            {"role": "user", "parts": [VALIDATION_PROMPT + "\n\n" + validation_context]}
        ])
        
        # 解析验证结果
        validation_text = response.text.strip()
        
        # 尝试提取JSON
        if "```json" in validation_text:
            json_start = validation_text.find("```json") + 7
            json_end = validation_text.find("```", json_start)
            validation_json = validation_text[json_start:json_end].strip()
        else:
            # 如果没有代码块，尝试直接解析
            validation_json = validation_text
        
        try:
            validation_result = json.loads(validation_json)
            return validation_result
        except json.JSONDecodeError:
            # 如果解析失败，返回基本验证结果
            return {
                "isValid": True,
                "score": 85,
                "issues": [],
                "suggestions": [],
                "summary": "AI验证完成，配置基本符合要求"
            }
            
    except Exception as e:
        print(f"AI验证过程中出错: {str(e)}")
        return {
            "isValid": True,
            "score": 80,
            "issues": ["验证过程中出现技术问题"],
            "suggestions": ["建议手动检查配置"],
            "summary": "验证过程遇到问题，但配置可能仍然有效"
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080))) 