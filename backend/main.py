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
    type: str  # input, operator, equals, clear, clearAll, backspace, decimal, negate, expression, multiParamFunction, parameterSeparator, functionExecute
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

# 优化的AI系统提示 - 修复按键功能问题
SYSTEM_PROMPT = """你是专业的计算器功能设计大师。你的唯一任务是根据用户的功能需求，修改计算器按钮布局。

🎯 你的任务：
1. **只输出`"buttons"`数组**：你的输出必须是一个JSON数组，只包含`buttons`。不要输出包含`theme`或`layout`的完整JSON对象。
2. **绝对禁止修改样式**：不要在任何按钮对象中包含颜色、字体、背景等样式字段。
3. **保持现有按钮**：不要删除或修改现有按钮的`id`或`gridPosition`，除非用户明确要求。只添加新功能按钮。
4. **确保功能完整**：所有按钮必须有正确的`action`定义。

➡️ 你的输出格式必须是：
[
  { "id": "btn1", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 0, "column": 0}, "type": "primary" },
  { "id": "btn2", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 0, "column": 1}, "type": "operator" }
]

⚠️ 严格禁止：
- 输出`theme`对象。
- 输出`layout`对象。
- 在按钮中包含任何样式字段 (`backgroundColor`, `fontSize`, `backgroundImage`, etc.)。

只关注功能，忽略所有外观。基于`current_config`中的按钮进行修改。
"""

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

🚨 【严格执行要求】
1. 只修改用户明确要求的功能或外观
2. 禁止添加用户未要求的新功能
3. 禁止更改用户未提及的颜色、布局、按钮
4. 如果用户只要求改颜色，就只改颜色
5. 如果用户只要求添加某个功能，就只添加该功能
6. 严格保持所有未提及的配置不变

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
            # AI现在应该只返回一个按钮数组
            buttons_list = json.loads(config_json)
            if not isinstance(buttons_list, list):
                raise HTTPException(status_code=500, detail="AI未能生成有效的按钮列表JSON")
            
            # 如果没有当前配置，无法继续
            if not request.current_config:
                raise HTTPException(status_code=400, detail="无法在没有当前配置的情况下进行纯功能修改")
            
            # 🛡️ 绝对样式保护：构建最终配置
            # 1. 深度复制现有配置作为基础
            final_config = request.current_config.copy(deep=True)
            
            # 2. 用AI生成的按钮列表替换布局中的按钮
            final_config['layout']['buttons'] = buttons_list
            
            # 3. 运行修复和验证程序
            #    我们传入完整的final_config，让fixer能够修复其中的新按钮布局
            fixed_config = await fix_calculator_config(
                request.user_input, 
                request.current_config, # 传入旧配置以供参考
                final_config # 传入合并后的配置进行修复
            )
            
        except json.JSONDecodeError as e:
            print(f"❌ JSON解析失败: {str(e)}")
            print(f"📄 原始响应: {response_text[:500]}")
            raise HTTPException(status_code=500, detail=f"AI生成的JSON格式无效: {str(e)}")
        
        print("✅ AI响应处理和样式保护完成")
        
        # 创建完整的配置对象
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080))) 