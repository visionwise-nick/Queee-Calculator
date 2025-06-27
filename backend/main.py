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
    aiResponse: Optional[str] = None  # AI的回复消息

class CustomizationRequest(BaseModel):
    user_input: str = Field(..., description="用户的自然语言描述")
    conversation_history: Optional[List[Dict[str, str]]] = Field(default=[], description="对话历史")
    current_config: Optional[Dict[str, Any]] = Field(default=None, description="当前计算器配置")

# 简化的AI系统提示 - 专注布局设计
SYSTEM_PROMPT = """你是专业的计算器设计师。只需要设计布局逻辑，前端会自动适配显示。

🎯 设计任务：根据用户需求设计计算器布局
- 决定使用几行几列（如4行5列、6行4列等）
- 安排每个位置放什么按钮
- 选择合适的主题配色

🔧 布局规则：
1. 【必保留17个基础按钮】数字0-9，运算符+−×÷，功能=、AC、±、.
2. 【标准ID规范】基础按钮ID必须是：zero,one,two,three,four,five,six,seven,eight,nine,add,subtract,multiply,divide,equals,clear,negate,decimal
3. 【位置从0开始】行列坐标都从0开始计数（第1行第1列 = row:0,column:0）
4. 【添加新功能】可以增加专业按钮，用expression表达式实现

🚀 功能表达式库：
- 数学：平方"x*x" 开根"sqrt(x)" 立方"pow(x,3)" 倒数"1/x"
- 科学：sin"sin(x)" cos"cos(x)" log"log(x)" exp"exp(x)"
- 金融：小费15%"x*0.15" 增值税"x*1.13" 折扣"x*0.8"
- 转换：华氏度"x*9/5+32" 英寸"x*2.54"

🎨 只需要指定：
- name: 计算器名称
- description: 功能描述
- layout.rows: 总行数
- layout.columns: 总列数
- layout.buttons: 每个按钮的id、label、action、gridPosition(row,column)、type
- theme: 基础配色方案

前端会自动处理：
✓ 按钮大小适配
✓ 显示区域调整
✓ 间距计算
✓ 字体缩放
✓ 屏幕适配

示例布局思路：
- 简单：4行4列 = 16个位置，适合基础计算器
- 标准：5行4列 = 20个位置，可加几个科学功能
- 丰富：6行5列 = 30个位置，专业计算器
- 复杂：8行6列 = 48个位置，全功能计算器

只返回JSON配置，专注设计逻辑，无需考虑显示技术细节。"""

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
主题: {theme.get('name', '未知主题')}
按钮数量: {len(buttons)}
布局: {layout.get('rows', '?')}行×{layout.get('columns', '?')}列

🎨 当前主题配色 (保持不变除非用户明确要求修改):
- 背景色: {theme.get('backgroundColor', '未知')}
- 显示屏: {theme.get('displayBackgroundColor', '未知')}
- 显示文字: {theme.get('displayTextColor', '未知')}
- 主要按钮: {theme.get('primaryButtonColor', '未知')}
- 主要按钮文字: {theme.get('primaryButtonTextColor', '未知')}
- 次要按钮: {theme.get('secondaryButtonColor', '未知')}
- 运算符按钮: {theme.get('operatorButtonColor', '未知')}
- 字体大小: {theme.get('fontSize', '未知')}
- 按钮圆角: {theme.get('buttonBorderRadius', '未知')}

🔘 当前按钮布局 (保持不变除非用户明确要求修改):
{chr(10).join([f"- {btn.get('label', '?')} ({btn.get('type', '?')}) 位置: {btn.get('gridPosition', {}).get('row', '?')},{btn.get('gridPosition', {}).get('column', '?')}" for btn in buttons[:10]])}
{f'... 还有 {len(buttons)-10} 个按钮' if len(buttons) > 10 else ''}

⚠️ 继承原则: 除非用户明确提到要修改的部分，其他所有配置必须保持完全一致！
"""
            is_iterative_request = True
            print("🔧 检测到现有配置，启用继承模式")
        
        if request.conversation_history:
            conversation_context = "\n\n📚 对话历史分析：\n"
            
            # 查找最近的AI生成配置信息
            for i, msg in enumerate(reversed(request.conversation_history[-10:])):
                role = "用户" if msg.get("role") == "user" else "AI助手"
                content = msg.get('content', '')
                conversation_context += f"{role}: {content}\n"
                
                                # 检测是否为增量修改请求 - 扩展关键词检测
                modification_keywords = [
                    '修改', '改变', '调整', '优化', '增加', '删除', '换', '改成', '变成', 
                    '把', '将', '设置', '改为', '换成', '加一个', '去掉', '改下', '换个',
                    '添加', '加', '减少', '缩小', '放大', '变大', '变小', '调大', '调小',
                    '字体', '颜色', '主题', '按钮', '布局', '描述', '功能', '样式'
                ]
                if msg.get("role") == "user" and any(keyword in content.lower() for keyword in modification_keywords):
                    is_iterative_request = True
                    print(f"🔍 检测到修改意图关键词: {[kw for kw in modification_keywords if kw in content.lower()]}")
        
        # 根据对话类型构建不同的提示策略
        if is_iterative_request and request.current_config:
            # 增量修改模式
            design_instruction = """
🔄 【增量修改模式 - 严格继承】
❗ 核心原则: 完全复制当前配置，只修改用户明确要求的部分

📋 执行步骤:
1. 从当前配置中复制所有字段（name, description, theme, layout等）
2. 识别用户要求修改的具体部分
3. 只对那些部分进行精确修改
4. 其他所有内容保持完全一致

🚫 严禁操作:
- 重新设计整体布局
- 改变用户未提及的按钮
- 修改用户未提及的颜色
- 改变按钮位置或数量（除非明确要求）
- 更换主题风格（除非明确要求）

✅ 允许操作:
- 仅修改用户明确提到的属性
- 在明确要求时添加新按钮
- 在明确要求时调整特定颜色
- 在明确要求时修改描述文字

🎯 示例:
- 用户说"字体变小" → 只修改 fontSize，其他全部保持
- 用户说"增加描述" → 只修改 description，其他全部保持
- 用户说"按钮变蓝" → 只修改相关按钮颜色，其他全部保持
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
        user_prompt = f"""用户需求：{request.user_input}

{current_config_info}

{conversation_context}

{design_instruction}

🎯 设计任务：
请设计计算器布局配置，只需要关注逻辑层面：

{'【在现有基础上调整】精确修改用户要求的部分，其他保持不变' if is_iterative_request else '【全新布局设计】根据需求创建新的计算器布局'}

布局设计重点：
1. 确定网格尺寸：几行几列（rows × columns）
2. 安排按钮位置：每个按钮放在哪个坐标
3. 选择主题配色：符合用途的颜色方案
4. 添加专业功能：用expression实现特殊计算

前端会自动处理所有显示适配：
- 按钮大小会根据行列数自动计算
- 显示区域会根据按钮密度智能调整
- 字体和间距会根据屏幕自动缩放
- 无需担心具体的像素尺寸问题

必需字段格式：
```json
{
  "name": "计算器名称",
  "description": "功能描述", 
  "theme": { 主题配色方案 },
  "layout": {
    "rows": 行数,
    "columns": 列数,
    "buttons": [
      {
        "id": "按钮ID",
        "label": "显示文字",
        "action": {"type": "操作类型", "value/expression": "参数"},
        "gridPosition": {"row": 行号, "column": 列号},
        "type": "按钮类型"
      }
    ]
  }
}
```

只返回JSON配置，专注布局逻辑设计。"""

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
        
        # 生成智能回复消息
        if is_iterative_request and request.current_config:
            # 继承修改的简洁确认
            config_data['aiResponse'] = "✅ 已按您的要求完成调整！"
        else:
            # 全新创建的欢迎消息
            config_data['aiResponse'] = f"🎉 \"{config_data.get('name', '计算器')}\" 已准备就绪！\n\n💡 提示：您可以随时说出想要的调整，我会在保持现有设计基础上进行精确修改"
        
        # 直接验证生成的配置结构，完全信任AI的输出
        calculator_config = CalculatorConfig(**config_data)
        
        return calculator_config
        
    except Exception as e:
        print(f"处理错误: {e}")
        raise HTTPException(status_code=500, detail=f"生成计算器配置失败: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000))) 