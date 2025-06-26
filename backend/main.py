import os
import google.generativeai as genai
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import uuid
from datetime import datetime
from typing import Optional, Dict, Any

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
    version: str
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
    
    # 可选择的模型版本 - 按性能排序
    MODEL_OPTIONS = {
        "gemini-2.5-pro": "最强性能版本",
        "gemini-2.5-flash": "最新版本，性能更强",
        "gemini-1.5-flash": "快速响应", 
        "gemini-1.5-pro": "更强推理能力，但响应较慢"
    }
    
    # 优先使用最新版本，如果不可用则降级
    selected_model = "gemini-2.5-pro"  # 切换到 gemini-2.5-pro
    
    # 配置安全设置以允许创意内容生成
    safety_settings = [
        {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT", 
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
    ]
    
    model = genai.GenerativeModel(
        selected_model,
        safety_settings=safety_settings
    )
    
    print(f"✅ 已加载模型: {selected_model}")
    print(f"📝 模型说明: {MODEL_OPTIONS.get(selected_model, '未知模型')}")
    
except KeyError:
    print("❌ 错误：请设置 'GOOGLE_API_KEY' 环境变量。")
    model = None
except Exception as e:
    print(f"❌ 模型初始化失败: {e}")
    model = None

# --- System Prompt for AI ---
# 这是最关键的部分，它"教"AI如何成为一个计算器设计师
SYSTEM_PROMPT = """
你是一个专业的计算器设计师AI专家。你拥有深厚的UI/UX设计经验和色彩理论知识。

**核心任务**: 根据用户的自然语言描述，生成一个精确的JSON格式计算器配置。

**严格要求**:
1. 输出必须是纯JSON，无任何解释、注释或markdown标记
2. 严格遵循预定义的JSON结构
3. 确保所有颜色值使用有效的十六进制格式（#RRGGBB）
4. 所有按钮必须有合理的网格位置，不能重叠
5. 主题配色必须协调且具有良好的对比度
6. 必须包含音效配置（soundEffects数组）
7. 必须包含所需的所有字段（id, name, description, version, createdAt, authorPrompt等）

**重要**: 如果用户要求自定义按钮功能或布局，你必须修改相应的按钮配置，不能使用标准模板！

**设计原则**:
- 考虑色彩心理学和用户体验
- 确保文字在背景上有足够的对比度
- 按钮布局要符合标准计算器的使用习惯
- 特效使用要适度，不影响功能性
- 音效搭配要与主题风格一致，音量设置合理
- 如果用户要求特殊功能按钮（如小费计算），必须替换相应的标准按钮

**音效搭配指南**:
- 赛博朋克/科技风: 使用电子音效 "sounds/cyberpunk/cyber_click.wav"
- 自然/温暖风: 使用自然音效 "sounds/nature/wood_tap.wav"
- 极简/现代风: 使用轻柔音效 "sounds/minimal/soft_tick.wav"
- 默认主题: 使用标准音效 "sounds/click_soft.wav"
- 音量建议: buttonPress(0.6-0.8), calculation(0.7-0.9), error(0.5-0.7), clear(0.5-0.7)

这是JSON的结构定义：
{
  "id": "string (一个唯一的标识符，可以使用UUID)",
  "name": "string (根据用户描述生成的名字)",
  "version": "1.0.0",
  "theme": {
    "name": "string (主题名称)",
    "backgroundColor": "string (CSS颜色, e.g., '#RRGGBB')",
    "displayBackgroundColor": "string",
    "displayTextColor": "string",
    "primaryButtonColor": "string",
    "primaryButtonTextColor": "string",
    "secondaryButtonColor": "string",
    "secondaryButtonTextColor": "string",
    "operatorButtonColor": "string",
    "operatorButtonTextColor": "string",
    "backgroundImage": "string (可选的URL)",
    "fontFamily": "string (可选的字体名称)",
    "fontSize": "number",
    "buttonBorderRadius": "number",
    "hasGlowEffect": "boolean",
    "shadowColor": "string (可选, e.g., '#RRGGBB')",
    "soundEffects": [
      {
        "trigger": "string (buttonPress|calculation|error|clear)",
        "soundUrl": "string (音效文件路径)",
        "volume": "number (0.0-1.0之间的音量)"
      }
    ]
  },
  "layout": {
    "name": "string (布局名称)",
    "rows": "integer",
    "columns": "integer",
    "buttons": [
      {
        "id": "string (e.g., 'btn-7')",
        "label": "string (e.g., '7')",
        "action": { "type": "string (input|operator|clear|equals|...)", "value": "string (e.g., '7', '+', 'C')" },
        "gridPosition": { "row": "integer", "column": "integer", "columnSpan": "integer (可选)" },
        "type": "string (primary|secondary|operator)",
        "isWide": "boolean (可选)"
      }
    ],
    "description": "string (对这个设计的简短描述)"
  }
}

这是一个标准的计算器布局，你可以此为基础进行修改：
- 4列，6行 (包括显示屏占用的行)
- 按钮类型 'primary' 用于数字, 'secondary' 用于 C/±/%, 'operator' 用于 +-*/=
- 按钮从上到下，从左到右排列。
- 0 按钮通常是 'isWide': true 并且 columnSpan: 2。

示例1（标准主题）：
用户请求: "我想要一个赛博朋克风格的计算器，黑底配霓虹蓝的按键。"
你的回答应该是完整的JSON，包含所有必需字段：
{
  "id": "cyber-calc-2024",
  "name": "赛博朋克计算器",
  "description": "科幻风格的霓虹蓝计算器，带有发光效果",
  "version": "1.0.0",
  "createdAt": "2024-01-01T12:00:00.000Z",
  "authorPrompt": "我想要一个赛博朋克风格的计算器，黑底配霓虹蓝的按键。",
  "theme": {
    "name": "赛博朋克",
    "backgroundColor": "#0A0A0A",
    "displayBackgroundColor": "#1A1A1A",
    "displayTextColor": "#00FFFF",
    "primaryButtonColor": "#1C1C1C",
    "primaryButtonTextColor": "#00FFFF",
    "secondaryButtonColor": "#330033",
    "secondaryButtonTextColor": "#FF00FF",
    "operatorButtonColor": "#003366",
    "operatorButtonTextColor": "#00FFFF",
    "fontSize": 24.0,
    "buttonBorderRadius": 12.0,
    "hasGlowEffect": true,
    "shadowColor": "#00FFFF",
    "soundEffects": [
      {
        "trigger": "buttonPress",
        "soundUrl": "sounds/cyberpunk/cyber_click.wav",
        "volume": 0.8
      },
      {
        "trigger": "calculation",
        "soundUrl": "sounds/cyberpunk/cyber_beep.wav",
        "volume": 0.9
      },
      {
        "trigger": "error",
        "soundUrl": "sounds/error.wav",
        "volume": 0.7
      },
      {
        "trigger": "clear",
        "soundUrl": "sounds/clear.wav",
        "volume": 0.6
      }
    ]
  },
  "layout": {
    "name": "标准计算器布局",
    "rows": 6,
    "columns": 4,
    "hasDisplay": true,
    "displayRowSpan": 1,
    "description": "经典4x6布局",
    "buttons": [
      {"id": "clear", "label": "AC", "action": {"type": "clearAll"}, "gridPosition": {"row": 1, "column": 0}, "type": "secondary"},
      {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 1, "column": 1}, "type": "secondary"},
      {"id": "percentage", "label": "%", "action": {"type": "percentage"}, "gridPosition": {"row": 1, "column": 2}, "type": "secondary"},
      {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 1, "column": 3}, "type": "operator"},
      {"id": "seven", "label": "7", "action": {"type": "input", "value": "7"}, "gridPosition": {"row": 2, "column": 0}, "type": "primary"},
      {"id": "eight", "label": "8", "action": {"type": "input", "value": "8"}, "gridPosition": {"row": 2, "column": 1}, "type": "primary"},
      {"id": "nine", "label": "9", "action": {"type": "input", "value": "9"}, "gridPosition": {"row": 2, "column": 2}, "type": "primary"},
      {"id": "multiply", "label": "×", "action": {"type": "operator", "value": "*"}, "gridPosition": {"row": 2, "column": 3}, "type": "operator"},
      {"id": "four", "label": "4", "action": {"type": "input", "value": "4"}, "gridPosition": {"row": 3, "column": 0}, "type": "primary"},
      {"id": "five", "label": "5", "action": {"type": "input", "value": "5"}, "gridPosition": {"row": 3, "column": 1}, "type": "primary"},
      {"id": "six", "label": "6", "action": {"type": "input", "value": "6"}, "gridPosition": {"row": 3, "column": 2}, "type": "primary"},
      {"id": "subtract", "label": "−", "action": {"type": "operator", "value": "-"}, "gridPosition": {"row": 3, "column": 3}, "type": "operator"},
      {"id": "one", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 4, "column": 0}, "type": "primary"},
      {"id": "two", "label": "2", "action": {"type": "input", "value": "2"}, "gridPosition": {"row": 4, "column": 1}, "type": "primary"},
      {"id": "three", "label": "3", "action": {"type": "input", "value": "3"}, "gridPosition": {"row": 4, "column": 2}, "type": "primary"},
      {"id": "add", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 4, "column": 3}, "type": "operator"},
      {"id": "zero", "label": "0", "action": {"type": "input", "value": "0"}, "gridPosition": {"row": 5, "column": 0, "columnSpan": 2}, "type": "primary", "isWide": true},
      {"id": "decimal", "label": ".", "action": {"type": "decimal"}, "gridPosition": {"row": 5, "column": 2}, "type": "primary"},
      {"id": "equals", "label": "=", "action": {"type": "equals"}, "gridPosition": {"row": 5, "column": 3}, "type": "operator"}
    ]
  }
}

示例2（自定义功能）：
用户请求: "创建一个带有小费15%按钮的计算器，替换%按钮"
你必须修改按钮配置，将百分比按钮替换为小费按钮：
{
  "id": "tip-calc-2024",
  "name": "小费计算器",
  "description": "专为餐厅小费计算设计的计算器",
  "version": "1.0.0",
  "createdAt": "2024-01-01T12:00:00.000Z",
  "authorPrompt": "创建一个带有小费15%按钮的计算器，替换%按钮",
  "theme": { ... 适合的主题配色 ... },
  "layout": {
    "name": "小费计算器布局",
    "rows": 6,
    "columns": 4,
    "hasDisplay": true,
    "displayRowSpan": 1,
    "description": "带有小费功能的计算器布局",
    "buttons": [
      {"id": "clear", "label": "AC", "action": {"type": "clearAll"}, "gridPosition": {"row": 1, "column": 0}, "type": "secondary"},
      {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 1, "column": 1}, "type": "secondary"},
      {"id": "tip15", "label": "小费15%", "action": {"type": "tip", "value": "0.15"}, "gridPosition": {"row": 1, "column": 2}, "type": "special", "customColor": "#28a745"},
      ... 其他按钮保持标准 ...
    ]
  }
}

示例3（金融功能）：
用户请求: "专业理财师计算器，添加复利、税后、ROI按钮"
生成带有金融功能的计算器：
{
  ... 基础配置 ...
  "layout": {
    "buttons": [
      {"id": "clear", "label": "AC", "action": {"type": "clearAll"}, "gridPosition": {"row": 1, "column": 0}, "type": "secondary"},
      {"id": "compoundInterest", "label": "复利", "action": {"type": "financial", "value": "compoundInterest"}, "gridPosition": {"row": 1, "column": 1}, "type": "special"},
      {"id": "afterTax", "label": "税后", "action": {"type": "financial", "value": "afterTax"}, "gridPosition": {"row": 1, "column": 2}, "type": "special"},
      {"id": "roi", "label": "ROI", "action": {"type": "financial", "value": "roi"}, "gridPosition": {"row": 2, "column": 2}, "type": "special"},
      ... 其他按钮 ...
    ]
  }
}

现在，请根据用户的请求生成配置。
"""

# --- API Endpoint ---
class GenerateRequest(BaseModel):
    prompt: str

# --- 验证Prompt ---
VALIDATION_PROMPT = """
你是一个专业的JSON格式验证专家。你的任务是验证给定的JSON是否符合计算器配置的规范。

请检查以下方面：
1. 所有必需的字段是否存在 (id, name, description, theme, layout, version, createdAt)
2. 颜色值是否为有效的十六进制格式 (#RRGGBB)
3. 按钮配置是否合理 (位置不重叠，类型正确)
4. 数据类型是否正确 (字符串、数字、布尔值)
5. 按钮布局是否符合标准计算器习惯

如果JSON格式正确且符合规范，请回复: "VALID"
如果有问题，请回复: "INVALID: [具体问题描述]"

请验证以下JSON配置:
"""

async def validate_config_with_ai(config_json: str) -> tuple[bool, str]:
    """使用AI验证生成的配置是否符合规范"""
    try:
        validation_prompt = f"{VALIDATION_PROMPT}\n\n{config_json}"
        
        response = model.generate_content(
            validation_prompt,
            generation_config={
                "temperature": 0.1,  # 验证时使用更低的温度
                "max_output_tokens": 500,
            }
        )
        
        result = response.text.strip()
        
        if result.startswith("VALID"):
            return True, "配置验证通过"
        elif result.startswith("INVALID:"):
            return False, result[8:].strip()  # 去掉"INVALID:"前缀
        else:
            return False, f"验证结果不明确: {result}"
            
    except Exception as e:
        print(f"AI验证过程出错: {e}")
        return False, f"验证过程出错: {str(e)}"

def basic_json_validation(config: Dict[str, Any]) -> tuple[bool, str]:
    """基础的JSON结构验证"""
    required_fields = ['id', 'name', 'description', 'theme', 'layout', 'version', 'createdAt']
    
    # 检查必需字段
    for field in required_fields:
        if field not in config:
            return False, f"缺少必需字段: {field}"
    
    # 检查主题配置
    theme = config.get('theme', {})
    theme_required = ['name', 'backgroundColor', 'displayTextColor']
    for field in theme_required:
        if field not in theme:
            return False, f"主题缺少必需字段: {field}"
    
    # 检查颜色格式
    color_fields = [
        'backgroundColor', 'displayBackgroundColor', 'displayTextColor',
        'primaryButtonColor', 'secondaryButtonColor', 'operatorButtonColor'
    ]
    
    for field in color_fields:
        color = theme.get(field)
        if color and not (isinstance(color, str) and color.startswith('#') and len(color) == 7):
            return False, f"颜色格式错误: {field} = {color}"
    
    # 检查布局配置
    layout = config.get('layout', {})
    if 'buttons' not in layout:
        return False, "布局缺少按钮配置"
    
    buttons = layout.get('buttons', [])
    if len(buttons) < 10:  # 至少应该有10个基本按钮
        return False, f"按钮数量过少: {len(buttons)}"
    
    return True, "基础验证通过"

def auto_fix_json(json_str: str) -> str:
    """尝试自动修复常见的JSON格式问题"""
    try:
        # 移除BOM和额外空白
        json_str = json_str.strip().lstrip('\ufeff')
        
        # 尝试找到JSON的开始和结束
        start_idx = json_str.find('{')
        end_idx = json_str.rfind('}')
        
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            json_str = json_str[start_idx:end_idx + 1]
        
        # 修复常见的格式问题
        # 1. 修复单引号为双引号
        json_str = json_str.replace("'", '"')
        
        # 2. 修复trailing comma（尾随逗号）
        import re
        json_str = re.sub(r',(\s*[}\]])', r'\1', json_str)
        
        # 3. 确保键名都有双引号
        json_str = re.sub(r'(\w+):', r'"\1":', json_str)
        
        return json_str
    except Exception as e:
        print(f"JSON自动修复失败: {e}")
        return json_str

def add_missing_fields(config: Dict[str, Any], user_prompt: str) -> Dict[str, Any]:
    """为AI生成的配置添加缺失的必需字段"""
    import uuid
    from datetime import datetime
    
    # 确保基础字段存在
    if 'id' not in config:
        config['id'] = str(uuid.uuid4())[:8]
    if 'version' not in config:
        config['version'] = '1.0.0'
    if 'createdAt' not in config:
        config['createdAt'] = datetime.now().isoformat()
    if 'authorPrompt' not in config:
        config['authorPrompt'] = user_prompt
    if 'description' not in config:
        config['description'] = f"根据用户需求生成: {user_prompt[:50]}{'...' if len(user_prompt) > 50 else ''}"
    
    # 确保theme有soundEffects
    if 'theme' in config and 'soundEffects' not in config['theme']:
        # 根据主题名称选择音效
        theme_name = config['theme'].get('name', '').lower()
        if 'cyber' in theme_name or '赛博' in theme_name:
            config['theme']['soundEffects'] = [
                {"trigger": "buttonPress", "soundUrl": "sounds/cyberpunk/cyber_click.wav", "volume": 0.8},
                {"trigger": "calculation", "soundUrl": "sounds/cyberpunk/cyber_beep.wav", "volume": 0.9},
                {"trigger": "error", "soundUrl": "sounds/error.wav", "volume": 0.7},
                {"trigger": "clear", "soundUrl": "sounds/clear.wav", "volume": 0.6}
            ]
        elif any(word in theme_name for word in ['nature', '自然', '木', '森林']):
            config['theme']['soundEffects'] = [
                {"trigger": "buttonPress", "soundUrl": "sounds/nature/wood_tap.wav", "volume": 0.7},
                {"trigger": "calculation", "soundUrl": "sounds/nature/wind_chime.wav", "volume": 0.8},
                {"trigger": "error", "soundUrl": "sounds/error.wav", "volume": 0.6},
                {"trigger": "clear", "soundUrl": "sounds/clear.wav", "volume": 0.5}
            ]
        elif any(word in theme_name for word in ['minimal', '极简', '简约']):
            config['theme']['soundEffects'] = [
                {"trigger": "buttonPress", "soundUrl": "sounds/minimal/soft_tick.wav", "volume": 0.6},
                {"trigger": "calculation", "soundUrl": "sounds/minimal/gentle_pop.wav", "volume": 0.8},
                {"trigger": "error", "soundUrl": "sounds/error.wav", "volume": 0.5},
                {"trigger": "clear", "soundUrl": "sounds/clear.wav", "volume": 0.5}
            ]
        else:
            # 默认音效
            config['theme']['soundEffects'] = [
                {"trigger": "buttonPress", "soundUrl": "sounds/click_soft.wav", "volume": 0.7},
                {"trigger": "calculation", "soundUrl": "sounds/calculate.wav", "volume": 0.8},
                {"trigger": "error", "soundUrl": "sounds/error.wav", "volume": 0.6},
                {"trigger": "clear", "soundUrl": "sounds/clear.wav", "volume": 0.6}
            ]
    
    return config

def get_fallback_template(user_prompt: str) -> Dict[str, Any]:
    """生成备用模板配置"""
    current_time = datetime.now().isoformat()
    config_id = str(uuid.uuid4())[:8]
    
    # 根据用户描述选择主题颜色
    prompt_lower = user_prompt.lower()
    
    if any(word in prompt_lower for word in ['赛博朋克', 'cyberpunk', '霓虹', '蓝色']):
        theme_colors = {
            "backgroundColor": "#000012",
            "displayBackgroundColor": "#001122",
            "displayTextColor": "#00FFFF",
            "primaryButtonColor": "#003366",
            "primaryButtonTextColor": "#FFFFFF",
            "secondaryButtonColor": "#004477",
            "secondaryButtonTextColor": "#00FFFF",
            "operatorButtonColor": "#0088FF",
            "operatorButtonTextColor": "#FFFFFF"
        }
        theme_name = "赛博朋克风格"
    elif any(word in prompt_lower for word in ['暖', '橙', '温暖', '阳光']):
        theme_colors = {
            "backgroundColor": "#FFF8F0",
            "displayBackgroundColor": "#FFE4B5",
            "displayTextColor": "#8B4513",
            "primaryButtonColor": "#DEB887",
            "primaryButtonTextColor": "#654321",
            "secondaryButtonColor": "#F4A460",
            "secondaryButtonTextColor": "#654321",
            "operatorButtonColor": "#FF8C00",
            "operatorButtonTextColor": "#FFFFFF"
        }
        theme_name = "温暖橙色风格"
    else:
        # 默认深色主题
        theme_colors = {
            "backgroundColor": "#1A1A1A",
            "displayBackgroundColor": "#2A2A2A",
            "displayTextColor": "#FFFFFF",
            "primaryButtonColor": "#3A3A3A",
            "primaryButtonTextColor": "#FFFFFF",
            "secondaryButtonColor": "#4A4A4A",
            "secondaryButtonTextColor": "#FFFFFF",
            "operatorButtonColor": "#FF6B35",
            "operatorButtonTextColor": "#FFFFFF"
        }
        theme_name = "现代深色风格"
    
    return {
        "id": config_id,
        "name": f"AI生成的{theme_name}计算器",
        "description": f"根据用户描述生成的个性化计算器：{user_prompt[:50]}{'...' if len(user_prompt) > 50 else ''}",
        "version": "1.0.0",
        "createdAt": current_time,
        "authorPrompt": user_prompt,
        "theme": {
            "name": theme_name,
            "fontSize": 18.0,
            "buttonBorderRadius": 8.0,
            "hasGlowEffect": 'cyberpunk' in prompt_lower or '赛博朋克' in prompt_lower,
            **theme_colors
        },
        "layout": {
            "name": "标准计算器布局",
            "rows": 6,
            "columns": 4,
            "hasDisplay": True,
            "displayRowSpan": 1,
            "description": "标准的四列六行计算器布局",
            "buttons": [
                {"id": "clear", "label": "C", "action": {"type": "clearAll"}, "gridPosition": {"row": 1, "column": 0}, "type": "secondary", "isWide": False, "isHigh": False},
                {"id": "negate", "label": "±", "action": {"type": "negate"}, "gridPosition": {"row": 1, "column": 1}, "type": "secondary", "isWide": False, "isHigh": False},
                {"id": "percentage", "label": "%", "action": {"type": "percentage"}, "gridPosition": {"row": 1, "column": 2}, "type": "secondary", "isWide": False, "isHigh": False},
                {"id": "divide", "label": "÷", "action": {"type": "operator", "value": "/"}, "gridPosition": {"row": 1, "column": 3}, "type": "operator", "isWide": False, "isHigh": False},
                {"id": "seven", "label": "7", "action": {"type": "input", "value": "7"}, "gridPosition": {"row": 2, "column": 0}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "eight", "label": "8", "action": {"type": "input", "value": "8"}, "gridPosition": {"row": 2, "column": 1}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "nine", "label": "9", "action": {"type": "input", "value": "9"}, "gridPosition": {"row": 2, "column": 2}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "multiply", "label": "×", "action": {"type": "operator", "value": "*"}, "gridPosition": {"row": 2, "column": 3}, "type": "operator", "isWide": False, "isHigh": False},
                {"id": "four", "label": "4", "action": {"type": "input", "value": "4"}, "gridPosition": {"row": 3, "column": 0}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "five", "label": "5", "action": {"type": "input", "value": "5"}, "gridPosition": {"row": 3, "column": 1}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "six", "label": "6", "action": {"type": "input", "value": "6"}, "gridPosition": {"row": 3, "column": 2}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "subtract", "label": "-", "action": {"type": "operator", "value": "-"}, "gridPosition": {"row": 3, "column": 3}, "type": "operator", "isWide": False, "isHigh": False},
                {"id": "one", "label": "1", "action": {"type": "input", "value": "1"}, "gridPosition": {"row": 4, "column": 0}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "two", "label": "2", "action": {"type": "input", "value": "2"}, "gridPosition": {"row": 4, "column": 1}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "three", "label": "3", "action": {"type": "input", "value": "3"}, "gridPosition": {"row": 4, "column": 2}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "add", "label": "+", "action": {"type": "operator", "value": "+"}, "gridPosition": {"row": 4, "column": 3}, "type": "operator", "isWide": False, "isHigh": False},
                {"id": "zero", "label": "0", "action": {"type": "input", "value": "0"}, "gridPosition": {"row": 5, "column": 0, "columnSpan": 2}, "type": "primary", "isWide": True, "isHigh": False},
                {"id": "decimal", "label": ".", "action": {"type": "decimal"}, "gridPosition": {"row": 5, "column": 2}, "type": "primary", "isWide": False, "isHigh": False},
                {"id": "equals", "label": "=", "action": {"type": "equals"}, "gridPosition": {"row": 5, "column": 3}, "type": "operator", "isWide": False, "isHigh": False}
            ]
        }
    }

@app.post("/generate-config", response_model=CalculatorConfig)
async def generate_config(request: GenerateRequest):
    if not model:
        raise HTTPException(status_code=500, detail="AI服务未配置，请检查服务器日志和环境变量。")

    user_prompt = request.prompt
    full_prompt = f"{SYSTEM_PROMPT}\n\n用户请求: \"{user_prompt}\""

    # 最多重试3次以提高成功率
    max_retries = 3
    last_error = None
    
    for attempt in range(max_retries):
        try:
            print(f"🔄 尝试生成配置 (第 {attempt + 1}/{max_retries} 次)")
            
            # 配置生成参数以提高准确率
            generation_config = {
                "temperature": 0.2,  # 稍微增加一点创造性，但仍然保持较低水平
                "max_output_tokens": 8192,
                "top_p": 0.8,
                "top_k": 40,
            }
            
            response = model.generate_content(
                full_prompt,
                generation_config=generation_config,
                safety_settings=safety_settings,
            )
            
            if not response.text:
                raise ValueError("AI未返回任何内容")
            
            # 清理AI返回的文本
            cleaned_response_text = response.text.strip()
            
            # 移除可能的markdown代码块标记
            if '```json' in cleaned_response_text:
                start = cleaned_response_text.find('```json') + 7
                end = cleaned_response_text.find('```', start)
                if end != -1:
                    cleaned_response_text = cleaned_response_text[start:end].strip()
            elif '```' in cleaned_response_text:
                cleaned_response_text = cleaned_response_text.replace('```', '').strip()
            
            print(f"🤖 AI生成的原始文本长度: {len(cleaned_response_text)}")
            
            # 解析JSON - 先尝试自动修复
            try:
                ai_json = json.loads(cleaned_response_text)
            except json.JSONDecodeError as je:
                print(f"⚠️  JSON解析失败，尝试自动修复: {je}")
                # 尝试自动修复JSON
                fixed_json_str = auto_fix_json(cleaned_response_text)
                try:
                    ai_json = json.loads(fixed_json_str)
                    print("✅ JSON自动修复成功")
                except json.JSONDecodeError as je2:
                    raise ValueError(f"JSON解析失败，自动修复也失败: {je2}")
            
            # 第一步：基础验证
            is_valid, validation_msg = basic_json_validation(ai_json)
            if not is_valid:
                raise ValueError(f"基础验证失败: {validation_msg}")
            
            print(f"✅ 基础验证通过: {validation_msg}")
            
            # 第二步：AI二次校验（降低严格度）
            is_ai_valid, ai_validation_msg = await validate_config_with_ai(cleaned_response_text)
            if not is_ai_valid:
                print(f"⚠️  AI验证警告: {ai_validation_msg}")
                # 只要基础验证通过，AI验证失败也继续处理
                print("📝 基础验证已通过，忽略AI验证结果，继续处理...")
            else:
                print(f"✅ AI二次验证通过: {ai_validation_msg}")
            
            # 第三步：补充缺失字段
            ai_json = add_missing_fields(ai_json, user_prompt)
            print("🔧 已补充缺失的必需字段")
            
            # 验证Pydantic模型
            config = CalculatorConfig.parse_obj(ai_json)
            
            print(f"🎉 配置生成成功: {config.name}")
            return config

        except Exception as e:
            last_error = e
            print(f"❌ 第 {attempt + 1} 次尝试失败: {e}")
            
            if attempt < max_retries - 1:
                print("🔄 准备重试...")
            else:
                print("💥 所有尝试都失败了")

    # 所有重试都失败后，使用备用模板
    print("🔧 AI生成失败，使用智能备用模板...")
    try:
        fallback_config = get_fallback_template(user_prompt)
        config = CalculatorConfig.parse_obj(fallback_config)
        print(f"✅ 备用模板生成成功: {config.name}")
        return config
    except Exception as fallback_error:
        error_detail = f"AI生成失败，备用模板也失败。AI错误: {last_error}，模板错误: {fallback_error}"
        print(f"💥 彻底失败: {error_detail}")
        raise HTTPException(
            status_code=500, 
            detail=error_detail
        )

@app.get("/")
def read_root():
    return {"message": "Queee Calculator AI Backend is running!"} 

# 启动代码 - 使用uvicorn运行ASGI应用
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port) 