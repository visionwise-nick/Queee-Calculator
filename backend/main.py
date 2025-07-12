from fastapi import FastAPI, HTTPException, BackgroundTasks
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
import uuid
import threading
from enum import Enum
# 添加图像生成相关导入
import requests
import base64
from io import BytesIO

app = FastAPI(title="Queee Calculator AI Backend (Async)", version="3.0.0")

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔧 新增：任务状态枚举
class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

# 🔧 新增：任务存储 - 使用文件系统持久化
import os
import json
TASKS_DIR = "/tmp/tasks"
os.makedirs(TASKS_DIR, exist_ok=True)
tasks_lock = threading.Lock()

# 🔧 新增：任务模型
class Task(BaseModel):
    id: str
    type: str  # customize, generate-image, generate-pattern, generate-app-background, generate-text-image
    status: TaskStatus
    request_data: Dict[str, Any]
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    progress: Optional[float] = None  # 0.0-1.0

class TaskResponse(BaseModel):
    task_id: str
    status: TaskStatus
    message: str
    
class TaskStatusResponse(BaseModel):
    task_id: str
    status: TaskStatus
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    progress: Optional[float] = None
    created_at: datetime
    updated_at: datetime

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

# 🔧 新增：任务管理函数
def create_task(task_type: str, request_data: Dict[str, Any]) -> str:
    """创建新任务"""
    task_id = str(uuid.uuid4())
    now = datetime.now()
    
    task = Task(
        id=task_id,
        type=task_type,
        status=TaskStatus.PENDING,
        request_data=request_data,
        created_at=now,
        updated_at=now
    )
    
    # 保存到文件系统
    task_file = os.path.join(TASKS_DIR, f"{task_id}.json")
    with tasks_lock:
        with open(task_file, 'w', encoding='utf-8') as f:
            task_dict = task.dict()
            # 处理datetime序列化
            task_dict['created_at'] = task_dict['created_at'].isoformat()
            task_dict['updated_at'] = task_dict['updated_at'].isoformat()
            json.dump(task_dict, f, ensure_ascii=False, indent=2)
    
    return task_id

def get_task(task_id: str) -> Optional[Task]:
    """获取任务"""
    task_file = os.path.join(TASKS_DIR, f"{task_id}.json")
    
    if not os.path.exists(task_file):
        return None
    
    try:
        with tasks_lock:
            with open(task_file, 'r', encoding='utf-8') as f:
                task_dict = json.load(f)
                # 处理datetime反序列化
                task_dict['created_at'] = datetime.fromisoformat(task_dict['created_at'])
                task_dict['updated_at'] = datetime.fromisoformat(task_dict['updated_at'])
                return Task(**task_dict)
    except Exception as e:
        print(f"❌ 读取任务文件失败 {task_id}: {e}")
        return None

def update_task_status(task_id: str, status: TaskStatus, result: Optional[Dict[str, Any]] = None, error: Optional[str] = None, progress: Optional[float] = None):
    """更新任务状态"""
    task = get_task(task_id)
    if task is None:
        print(f"❌ 任务不存在: {task_id}")
        return
    
    # 更新任务状态
    task.status = status
    task.updated_at = datetime.now()
    if result is not None:
        task.result = result
    if error is not None:
        task.error = error
    if progress is not None:
        task.progress = progress
    
    # 保存到文件系统
    task_file = os.path.join(TASKS_DIR, f"{task_id}.json")
    try:
        with tasks_lock:
            with open(task_file, 'w', encoding='utf-8') as f:
                task_dict = task.dict()
                # 处理datetime序列化
                task_dict['created_at'] = task_dict['created_at'].isoformat()
                task_dict['updated_at'] = task_dict['updated_at'].isoformat()
                json.dump(task_dict, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"❌ 保存任务状态失败 {task_id}: {e}")

def cleanup_old_tasks():
    """清理超过24小时的旧任务"""
    try:
        now = datetime.now()
        to_remove = []
        
        # 扫描任务目录
        for filename in os.listdir(TASKS_DIR):
            if not filename.endswith('.json'):
                continue
                
            task_file = os.path.join(TASKS_DIR, filename)
            try:
                with open(task_file, 'r', encoding='utf-8') as f:
                    task_dict = json.load(f)
                    created_at = datetime.fromisoformat(task_dict['created_at'])
                    
                    if (now - created_at).total_seconds() > 24 * 3600:  # 24小时
                        to_remove.append(task_file)
            except Exception as e:
                print(f"❌ 读取任务文件时出错 {filename}: {e}")
                to_remove.append(task_file)  # 损坏的文件也删除
        
        # 删除过期任务文件
        with tasks_lock:
            for task_file in to_remove:
                try:
                    os.remove(task_file)
                except Exception as e:
                    print(f"❌ 删除任务文件失败 {task_file}: {e}")
                    
        if to_remove:
            print(f"🧹 清理了 {len(to_remove)} 个过期任务")
    except Exception as e:
        print(f"❌ 清理任务时出错: {e}")

# 🔧 新增：后台任务处理函数
def process_task_in_background(task_id: str):
    """在后台处理任务"""
    task = get_task(task_id)
    if not task:
        return
    
    try:
        # 更新任务状态为处理中
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.1)
        
        # 根据任务类型分发处理
        if task.type == "customize":
            result = process_customize_task(task_id, task.request_data)
        elif task.type == "generate-image":
            result = process_generate_image_task(task_id, task.request_data)
        elif task.type == "generate-pattern":
            result = process_generate_pattern_task(task_id, task.request_data)
        elif task.type == "generate-app-background":
            result = process_generate_app_background_task(task_id, task.request_data)
        elif task.type == "generate-text-image":
            result = process_generate_text_image_task(task_id, task.request_data)
        else:
            raise ValueError(f"未知任务类型: {task.type}")
        
        # 任务完成
        update_task_status(task_id, TaskStatus.COMPLETED, result=result, progress=1.0)
        print(f"✅ 任务 {task_id} ({task.type}) 完成")
        
    except Exception as e:
        print(f"❌ 任务 {task_id} ({task.type}) 失败: {str(e)}")
        update_task_status(task_id, TaskStatus.FAILED, error=str(e))

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
    buttonOpacity: Optional[float] = None  # 🔧 新增：按键透明度控制
    displayOpacity: Optional[float] = None  # 🔧 新增：显示区域透明度控制

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

# 修复后的AI系统提示 - 继承式功能设计
SYSTEM_PROMPT = """你是专业的计算器功能设计大师。你的职责是在现有配置基础上进行精确的增删改，绝不全盘推翻。

🎯 **核心使命 - 继承式修改**：
你必须将现有配置视为神圣不可侵犯的基础，只对用户明确要求的部分进行修改。

🚨 **继承式修改的铁律**：
```
🔒 **绝对禁止行为**：
❌ 删除现有按键（除非用户明确要求删除）
❌ 更改现有按键的ID（这是图像关联的生命线）
❌ 重新设计整个计算器布局
❌ 改变未被用户提及的任何属性
❌ 随意调整已有按键的位置或功能
❌ 减少现有按键的数量
❌ 全盘重新创建配置

✅ **必须遵循的原则**：
✅ 保持现有所有按键不变（除非用户明确要求修改）
✅ 新增功能在现有布局基础上扩展
✅ 只修改用户明确要求的具体部分
✅ 保持按键ID的绝对稳定性
✅ 保持现有按键的功能完整性
✅ 在现有配置基础上累积改进
✅ 优先扩展布局而不是替换现有按键

🎯 **操作指南**：
• 用户说"添加sin函数" → 在现有布局基础上添加sin按键，保持所有现有按键不变
• 用户说"改成蓝色主题" → 只修改主题颜色，保持所有按键布局和功能不变
• 用户说"修改加号按钮" → 只修改btn_add按钮，保持所有其他按键不变
• 用户说"添加科学函数" → 扩展布局添加科学函数按键，保持现有按键不变
• 用户说"重新排列" → 保持所有按键ID和功能，只调整gridPosition
```

🔍 **配置分析流程**：
1. **深度分析现有配置**：理解当前有哪些按键，它们的ID、位置、功能
2. **识别用户需求**：确定用户要求修改、添加或删除什么
3. **制定保护策略**：列出需要保护的现有按键和功能
4. **设计增量方案**：在现有基础上设计最小化的改动
5. **确保功能完整性**：验证修改后所有现有功能仍然可用

🛡️ **现有按键保护机制**：
```javascript
// 现有按键必须100%保留的示例
如果当前配置有：
{
  "id": "btn_1", "label": "1", "action": {"type": "input", "value": "1"}, 
  "gridPosition": {"row": 4, "column": 0}, "type": "primary"
}

那么在新配置中必须完全保留这个按键，包括：
- id: "btn_1" (绝对不能改)
- label: "1" (除非用户明确要求改)
- action: {"type": "input", "value": "1"} (除非用户明确要求改)
- gridPosition: {"row": 4, "column": 0} (除非用户明确要求重新排列)
- type: "primary" (除非用户明确要求改)
```

🔄 **增量修改策略**：
```
场景1：用户要求"添加sin函数"
步骤1：保留现有所有按键（数字0-9、运算符+、-、*、/、=等）
步骤2：在现有布局基础上找到合适位置添加sin按键
步骤3：如果需要，扩展布局行数或列数来容纳新按键
步骤4：确保新按键不影响现有按键的功能

场景2：用户要求"修改加号按钮的样式"
步骤1：找到现有的加号按钮（通常是btn_add）
步骤2：只修改用户要求的样式属性
步骤3：保持其他所有按键完全不变
步骤4：保持加号按钮的核心功能不变

场景3：用户要求"重新排列布局"
步骤1：保持所有现有按键的ID和功能
步骤2：只调整gridPosition属性
步骤3：确保新布局逻辑合理
步骤4：不删除任何现有按键
```

🧠 **智能配置合并算法**：
```python
# 伪代码示例：如何正确合并配置
def merge_configs(current_config, user_request):
    # 1. 深度分析现有配置
    existing_buttons = current_config.layout.buttons
    existing_theme = current_config.theme
    
    # 2. 识别用户需求
    requested_changes = analyze_user_request(user_request)
    
    # 3. 保护现有按键
    protected_buttons = []
    for button in existing_buttons:
        if button.id not in requested_changes.buttons_to_modify:
            protected_buttons.append(button)  # 完全保留
    
    # 4. 只修改用户要求的部分
    modified_buttons = modify_only_requested_buttons(
        existing_buttons, requested_changes
    )
    
    # 5. 添加新按键（如果需要）
    new_buttons = add_new_buttons_if_requested(requested_changes)
    
    # 6. 合并所有按键
    final_buttons = protected_buttons + modified_buttons + new_buttons
    
    return final_buttons
```

🎯 **任务输出要求**：
1. **完整保留现有配置结构**：包含theme、layout、buttons等所有字段
2. **按键ID绝对稳定**：现有按键ID必须保持不变
3. **功能累积增强**：在现有功能基础上添加新功能
4. **布局智能扩展**：如果需要空间，扩展布局而不是替换现有按键
5. **配置向下兼容**：确保现有的图像工坊内容仍然有效

🔧 **支持的Action类型和配置规范**：

## 1. 基础输入类型
```json
{"type": "input", "value": "0-9"}          // 数字输入
{"type": "decimal"}                        // 小数点
{"type": "operator", "value": "+|-|*|/"}   // 基础运算符
{"type": "equals"}                         // 等号计算
{"type": "clear"}                          // 清除当前
{"type": "clearAll"}                       // 全部清除
{"type": "backspace"}                      // 退格
{"type": "negate"}                         // 正负号切换
```

## 2. 单参数数学函数（expression类型）
```json
// 🟢 三角函数（支持度数和弧度）
{"type": "expression", "expression": "sin(x)"}      // 正弦
{"type": "expression", "expression": "cos(x)"}      // 余弦
{"type": "expression", "expression": "tan(x)"}      // 正切
{"type": "expression", "expression": "asin(x)"}     // 反正弦
{"type": "expression", "expression": "acos(x)"}     // 反余弦
{"type": "expression", "expression": "atan(x)"}     // 反正切

// 🟢 对数和指数函数
{"type": "expression", "expression": "log(x)"}      // 自然对数
{"type": "expression", "expression": "log10(x)"}    // 常用对数
{"type": "expression", "expression": "log2(x)"}     // 二进制对数
{"type": "expression", "expression": "exp(x)"}      // e^x
{"type": "expression", "expression": "pow(2,x)"}    // 2^x
{"type": "expression", "expression": "pow(10,x)"}   // 10^x

// 🟢 幂和根函数
{"type": "expression", "expression": "x*x"}         // x²平方
{"type": "expression", "expression": "pow(x,3)"}    // x³立方
{"type": "expression", "expression": "pow(x,4)"}    // x⁴四次方
{"type": "expression", "expression": "sqrt(x)"}     // √x 平方根
{"type": "expression", "expression": "pow(x,1/3)"}  // ∛x 立方根

// 🟢 其他数学函数
{"type": "expression", "expression": "1/x"}         // 倒数
{"type": "expression", "expression": "abs(x)"}      // 绝对值
{"type": "expression", "expression": "x!"}          // 阶乘（整数）

// 🟢 百分比和倍数运算
{"type": "expression", "expression": "x*0.01"}      // 百分比转换
{"type": "expression", "expression": "x*0.15"}      // 15%计算
{"type": "expression", "expression": "x*0.18"}      // 18%计算
{"type": "expression", "expression": "x*0.20"}      // 20%计算
{"type": "expression", "expression": "x*1.13"}      // 含税价格（13%）
{"type": "expression", "expression": "x*0.85"}      // 85折价格

// 🟢 单位转换
{"type": "expression", "expression": "x*9/5+32"}    // 摄氏度→华氏度
{"type": "expression", "expression": "(x-32)*5/9"}  // 华氏度→摄氏度
{"type": "expression", "expression": "x*2.54"}      // 英寸→厘米
{"type": "expression", "expression": "x/2.54"}      // 厘米→英寸
{"type": "expression", "expression": "x*0.3048"}    // 英尺→米
{"type": "expression", "expression": "x/0.3048"}    // 米→英尺
{"type": "expression", "expression": "x*0.453592"}  // 磅→公斤
{"type": "expression", "expression": "x/0.453592"}  // 公斤→磅
{"type": "expression", "expression": "x*28.3495"}   // 盎司→克
{"type": "expression", "expression": "x/28.3495"}   // 克→盎司
```

## 3. 多参数函数（multiParamFunction类型）
```json
// 🟢 数学函数
{"type": "multiParamFunction", "value": "pow"}          // 幂运算 pow(x,y)
{"type": "multiParamFunction", "value": "log"}          // 对数 log(x,base)
{"type": "multiParamFunction", "value": "atan2"}        // 反正切 atan2(y,x)
{"type": "multiParamFunction", "value": "hypot"}        // 斜边长度
{"type": "multiParamFunction", "value": "max"}          // 最大值
{"type": "multiParamFunction", "value": "min"}          // 最小值
{"type": "multiParamFunction", "value": "avg"}          // 平均值
{"type": "multiParamFunction", "value": "gcd"}          // 最大公约数
{"type": "multiParamFunction", "value": "lcm"}          // 最小公倍数

// 🔢 进制转换函数
{"type": "multiParamFunction", "value": "进制转换"}      // 进制转换：数字,目标进制 或 数字,源进制,目标进制
{"type": "multiParamFunction", "value": "baseconvert"}  // 英文别名：baseconvert(数字,目标进制)
{"type": "multiParamFunction", "value": "十进制转二进制"} // 十进制转二进制：数字
{"type": "multiParamFunction", "value": "dec2bin"}      // 英文别名：dec2bin(数字)
{"type": "multiParamFunction", "value": "十进制转八进制"} // 十进制转八进制：数字
{"type": "multiParamFunction", "value": "dec2oct"}      // 英文别名：dec2oct(数字)
{"type": "multiParamFunction", "value": "十进制转十六进制"} // 十进制转十六进制：数字
{"type": "multiParamFunction", "value": "dec2hex"}      // 英文别名：dec2hex(数字)
{"type": "multiParamFunction", "value": "二进制转十进制"} // 二进制转十进制：数字
{"type": "multiParamFunction", "value": "bin2dec"}      // 英文别名：bin2dec(数字)
{"type": "multiParamFunction", "value": "八进制转十进制"} // 八进制转十进制：数字
{"type": "multiParamFunction", "value": "oct2dec"}      // 英文别名：oct2dec(数字)
{"type": "multiParamFunction", "value": "十六进制转十进制"} // 十六进制转十进制：数字
{"type": "multiParamFunction", "value": "hex2dec"}      // 英文别名：hex2dec(数字)

// 🟢 金融计算
{"type": "multiParamFunction", "value": "复利计算"}      // 复利：本金,年利率,年数
{"type": "multiParamFunction", "value": "汇率转换"}      // 汇率：金额,汇率
{"type": "multiParamFunction", "value": "贷款计算"}      // 贷款计算(金额,利率,年数)
{"type": "multiParamFunction", "value": "loanpayment"}  // 英文别名
{"type": "multiParamFunction", "value": "mortgage"}     // 抵押贷款(房价,首付%,年数,利率)
{"type": "multiParamFunction", "value": "投资回报"}      // 投资回报率
{"type": "multiParamFunction", "value": "抵押贷款"}      // 抵押贷款
{"type": "multiParamFunction", "value": "年金计算"}      // 年金计算
```

## 4. 自定义复合功能（customFunction类型）
```json
// 🚀 房贷计算器示例
{"type": "customFunction", "value": "mortgage_calculator", "parameters": {"annualRate": 3.5, "years": 30}}

// 🚀 定制复利计算器
{"type": "customFunction", "value": "compound_calculator", "parameters": {"rate": 4.2, "years": 10}}

// 🚀 货币转换器
{"type": "customFunction", "value": "currency_converter", "parameters": {"fromCurrency": "USD", "toCurrency": "CNY", "rate": 7.2}}

// 🚀 折扣计算器
{"type": "customFunction", "value": "discount_calculator", "parameters": {"discountRate": 25, "taxRate": 13}}

// 🚀 工程计算器
{"type": "customFunction", "value": "engineering_calculator", "parameters": {"unit": "metric", "precision": 4}}

// 🚀 BMI计算器
{"type": "customFunction", "value": "bmi_calculator", "parameters": {"height": 175}}

// 🚀 燃油效率计算器
{"type": "customFunction", "value": "fuel_efficiency", "parameters": {"unit": "L/100km", "pricePerLiter": 8.5}}

// 🚀 进制转换器
{"type": "customFunction", "value": "base_converter", "parameters": {"supportedBases": [2, 8, 10, 16]}}

// 🚀 程序员计算器
{"type": "customFunction", "value": "programmer_calculator", "parameters": {"defaultBase": 10, "showBinary": true, "showHex": true}}
```

## 5. 多参数函数辅助按键（重要）
```json
{"type": "parameterSeparator"}   // 逗号分隔符（多参数输入必需）
{"type": "functionExecute"}      // 执行函数（多参数计算必需）
```

🚨 **多参数函数自动检测规则**：
如果现有配置或新增按键包含任何多参数函数，必须确保存在逗号和执行按键。如果没有，自动添加：
```json
{"id": "btn_comma", "label": ",", "action": {"type": "parameterSeparator"}, "gridPosition": {"row": 6, "column": 3}, "type": "secondary"}
{"id": "btn_execute", "label": "执行", "action": {"type": "functionExecute"}, "gridPosition": {"row": 6, "column": 4}, "type": "operator"}
```

🚨 **严禁使用的语法**：
❌ JavaScript语法：Math.sin(x), parseInt(x), Number(x).toString()
❌ 不存在的函数：calculateMortgage, loanCalculator
❌ 复杂逻辑：if/else/loop语句
❌ 字符串操作：字符串拼接、替换等

📐 **布局扩展策略**：
```
继承现有布局：
1. 保持现有按键的row和column不变
2. 新按键使用未占用的位置
3. 如果空间不足，扩展rows或columns
4. 优先使用第6-12行来放置新功能
5. 保持布局的逻辑性和美观性

推荐扩展顺序：
- 第6行：科学函数（sin, cos, tan, log, sqrt等）
- 第7行：高级函数（x^y, x!, 1/x等）
- 第8行：单位转换（°F→°C, in→cm等）
- 第9行：进制转换（十→二, 二→十等）
- 第10-12行：自定义功能和专业功能
```

🎨 **按键布局建议**：
保持传统计算器布局：
- 数字0-9：保持传统位置
- 基础运算符：保持右侧列
- 新增功能：扩展到第6-12行
- 逗号和执行键：第6行右侧

🔧 **输出格式要求**：
```json
{
  "id": "calc_xxx",
  "name": "计算器名称",
  "description": "描述",
  "theme": {
    "name": "主题名称"
  },
  "layout": {
    "name": "布局名称", 
    "rows": 数字,
    "columns": 数字,
    "buttons": [
      // 所有现有按键必须保留
      // 新按键添加到合适位置
    ]
  },
  "version": "1.0.0",
  "createdAt": "ISO时间戳"
}
```

🎯 **记住你的使命**：
你是现有配置的守护者，用户功能需求的实现者。永远在现有基础上累积改进，绝不全盘推翻。每一个现有按键都是用户宝贵的资产，必须小心保护。

现在，根据用户的具体需求，在完全保留现有配置的基础上，进行精确的增量修改。"""

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

📐 **布局规则（支持大型布局）**：
```
标准布局（5行×4列 = 20个位置）：
行1: [AC] [±] [%] [÷]      - 功能行
行2: [7] [8] [9] [×]       - 数字+运算符
行3: [4] [5] [6] [-]       - 数字+运算符  
行4: [1] [2] [3] [+]       - 数字+运算符
行5: [0] [.] [=] [功能]     - 底行

扩展布局（支持最多12行×10列 = 120个位置）：
✅ 可以根据用户需求扩展到任意合理大小
✅ 支持专业计算器和复杂功能布局
✅ 每个位置都可以放置有用的功能按键

布局扩展建议：
- 行1-5: 基础数字和运算符（保持传统布局）
- 行6-8: 科学函数区域
- 行9-10: 工程函数和单位转换
- 行11-12: 专业功能和自定义功能
- 列5-10: 按功能分组扩展
```

🔧 **位置建议**：
- 数字0: row=5,col=0 | 数字1: row=4,col=0 | 数字2: row=4,col=1 | 数字3: row=4,col=2
- 数字4: row=3,col=0 | 数字5: row=3,col=1 | 数字6: row=3,col=2
- 数字7: row=2,col=0 | 数字8: row=2,col=1 | 数字9: row=2,col=2
- 运算符÷: row=1,col=3 | ×: row=2,col=3 | -: row=3,col=3 | +: row=4,col=3
- 等号=: row=5,col=2 | 小数点.: row=5,col=1 | AC: row=1,col=0

🚨 **数学函数和进制转换修复**：
❌ 错误JavaScript语法：
   - Math.sin(x), Math.sqrt(x), parseInt(x)
   - Number(x).toString(8), Number(x).toString(16)
   - x.toString(2), x.toString(8), x.toString(16)
   - parseInt(x, 2), parseInt(x, 8), parseInt(x, 16)

✅ 正确表达式语法：
   - sin(x), sqrt(x), x*x
   - dec2oct(x), dec2hex(x), dec2bin(x)
   - bin2dec(x), oct2dec(x), hex2dec(x)

🚨 **进制转换专用修复规则**：
发现JavaScript进制转换语法时，必须替换为：
- Number(x).toString(8) → dec2oct(x)
- Number(x).toString(16) → dec2hex(x)
- Number(x).toString(2) → dec2bin(x)
- parseInt(x, 2) → bin2dec(x)
- parseInt(x, 8) → oct2dec(x)
- parseInt(x, 16) → hex2dec(x)

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
            # 优先使用用户明确指定的保护字段
            if request.workshop_protected_fields:
                protected_fields = request.workshop_protected_fields.copy()
                print(f"🛡️ 使用用户指定的保护字段: {protected_fields}")
            else:
                # 自动检测图像生成工坊生成的内容
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
                
                print(f"🛡️ 自动检测的保护字段: {protected_fields}")
            
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
            # 🔧 完整传递当前配置JSON，确保AI能准确继承
            current_config_json = json.dumps(request.current_config, ensure_ascii=False, indent=2)
            theme = request.current_config.get('theme', {})
            layout = request.current_config.get('layout', {})
            buttons = layout.get('buttons', [])
            
            current_config_info = f"""
📋 【当前计算器完整配置 - 必须严格继承】
```json
{current_config_json}
```

🚨 【严格继承要求】
1. **按键ID保持一致**: 所有现有按键的ID绝对不能更改，这样可以保持图像内容关联
2. **只修改用户要求的部分**: 如果用户只说"添加sin函数"，就只添加sin按钮，其他按钮保持原样
3. **保持布局结构**: 不要随意改变现有按钮的位置，除非用户明确要求
4. **保持主题一致**: 除非用户明确要求改变颜色或样式，否则保持所有主题设置不变
5. **增量修改**: 在现有基础上添加或修改，而不是重新设计

🎯 【操作策略】
- 如果用户要求添加功能：在现有布局基础上添加新按钮
- 如果用户要求修改某个按钮：只修改该按钮的属性，保持其他按钮不变
- 如果用户要求改变样式：只修改明确提到的样式属性
- 如果用户要求改变布局：保持现有按钮ID，只调整位置

⚠️ 【禁止操作】
- 不要更改现有按钮的ID
- 不要删除现有按钮，除非用户明确要求
- 不要改变未被用户提及的任何属性
- 不要重新设计整个计算器，只做增量改进
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
            
            # 🛡️ 图像生成工坊保护：优先保护字段，然后清理
            if request.current_config and protected_fields:
                final_config = copy.deepcopy(ai_generated_config)
                current_theme = request.current_config.get('theme', {})
                current_layout = request.current_config.get('layout', {})
                current_app_background = request.current_config.get('appBackground', {})
                
                # 🎨 保护APP背景配置（优先级最高）- 字段级别保护
                app_bg_fields = ['appBackground.backgroundImageUrl', 'appBackground.backgroundType', 
                                'appBackground.backgroundColor', 'appBackground.backgroundGradient', 
                                'appBackground.backgroundOpacity', 'appBackground.buttonOpacity',
                                'appBackground.displayOpacity']
                
                # 检查是否有APP背景字段需要保护
                protected_app_bg_fields = [field for field in app_bg_fields if field in protected_fields]
                if protected_app_bg_fields:
                    # 🔧 字段级别保护 - 确保AI生成的配置中有完整的appBackground
                    if 'appBackground' not in final_config:
                        final_config['appBackground'] = {}
                    
                    # 逐个保护字段
                    for field in protected_app_bg_fields:
                        field_name = field.split('.')[1]  # 去掉appBackground.前缀
                        if field_name in current_app_background:
                            final_config['appBackground'][field_name] = current_app_background[field_name]
                            print(f"🛡️ 保护APP背景字段: {field} = {current_app_background[field_name]}")
                
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
                    # 🔧 新的继承式合并策略：严格基于现有配置进行增量修改
                    print("🔧 开始继承式配置合并...")
                    final_config = copy.deepcopy(request.current_config)
                    
                    # 🔧 更新基本信息（如果AI修改了的话）
                    if 'name' in ai_generated_config and ai_generated_config['name']:
                        final_config['name'] = ai_generated_config['name']
                    if 'description' in ai_generated_config and ai_generated_config['description']:
                        final_config['description'] = ai_generated_config['description']
                    
                    # 🔧 智能合并主题更改（只合并AI实际修改的非空字段）
                    if 'theme' in ai_generated_config and ai_generated_config['theme']:
                        current_theme = final_config.setdefault('theme', {})
                        ai_theme = ai_generated_config['theme']
                        
                        # 只更新AI实际输出的非空字段
                        for key, value in ai_theme.items():
                            if value is not None and value != "" and value != "无":
                                current_theme[key] = value
                                print(f"🔧 更新主题属性: {key} = {value}")
                    
                    # 🔧 智能合并布局更改（最关键的部分）
                    if 'layout' in ai_generated_config and ai_generated_config['layout']:
                        current_layout = final_config.setdefault('layout', {})
                        ai_layout = ai_generated_config['layout']
                        
                        # 🔧 更新布局基本信息
                        if 'rows' in ai_layout and ai_layout['rows']:
                            current_layout['rows'] = ai_layout['rows']
                        if 'columns' in ai_layout and ai_layout['columns']:
                            current_layout['columns'] = ai_layout['columns']
                        
                        # 🔧 按键合并策略：保持现有按键ID，智能合并新按键
                        if 'buttons' in ai_layout and ai_layout['buttons']:
                            current_buttons = {btn['id']: btn for btn in current_layout.get('buttons', [])}
                            ai_buttons = {btn['id']: btn for btn in ai_layout['buttons']}
                            
                            # 🔧 合并按键：现有按键保持不变，新按键添加进来
                            merged_buttons = []
                            
                            # 1. 保持所有现有按键（可能被AI修改了某些属性）
                            for btn_id, current_btn in current_buttons.items():
                                if btn_id in ai_buttons:
                                    # AI修改了该按键，合并修改
                                    ai_btn = ai_buttons[btn_id]
                                    merged_btn = copy.deepcopy(current_btn)
                                    
                                    # 只更新AI实际修改的字段
                                    for key, value in ai_btn.items():
                                        if key == 'id':
                                            continue  # ID绝对不能改
                                        if value is not None and value != "":
                                            merged_btn[key] = value
                                            print(f"🔧 更新按键{btn_id}属性: {key} = {value}")
                                    
                                    merged_buttons.append(merged_btn)
                                else:
                                    # AI没有修改该按键，保持原样
                                    merged_buttons.append(current_btn)
                            
                            # 2. 添加AI新增的按键
                            for btn_id, ai_btn in ai_buttons.items():
                                if btn_id not in current_buttons:
                                    merged_buttons.append(ai_btn)
                                    print(f"🔧 添加新按键: {btn_id} - {ai_btn.get('label', '未知')}")
                            
                            current_layout['buttons'] = merged_buttons
                            print(f"🔧 按键合并完成: {len(current_buttons)} 个现有 + {len(ai_buttons) - len(current_buttons)} 个新增 = {len(merged_buttons)} 个总计")
                        
                        # 其他布局字段只在非空时更新
                        for key, value in ai_layout.items():
                            if key not in ['buttons', 'rows', 'columns'] and value is not None and value != "":
                                current_layout[key] = value
                    
                    # 🔧 合并APP背景配置（如果AI修改了的话）
                    if 'appBackground' in ai_generated_config and ai_generated_config['appBackground']:
                        current_app_bg = final_config.setdefault('appBackground', {})
                        ai_app_bg = ai_generated_config['appBackground']
                        
                        # 只更新AI实际修改的非空字段
                        for key, value in ai_app_bg.items():
                            if value is not None and value != "":
                                current_app_bg[key] = value
                                print(f"🔧 更新APP背景属性: {key} = {value}")
                    
                    print("🔧 继承式配置合并完成")
            
            # 🧹 首先清理无效按键
            final_config = clean_invalid_buttons(final_config)
            
            # 运行修复和验证程序
            fixed_config = await fix_calculator_config(
                request.user_input, 
                request.current_config, # 传入旧配置以供参考
                final_config # 传入清理并合并后的配置进行修复
            )
            
            # 🛡️ 重新应用保护逻辑（防止fix_calculator_config覆盖保护字段）
            if request.current_config and protected_fields:
                print(f"🛡️ 修复后重新应用保护逻辑: {protected_fields}")
                current_theme = request.current_config.get('theme', {})
                current_layout = request.current_config.get('layout', {})
                current_app_background = request.current_config.get('appBackground', {})
                
                # 重新保护APP背景字段
                app_bg_fields = ['appBackground.backgroundImageUrl', 'appBackground.backgroundType', 
                                'appBackground.backgroundColor', 'appBackground.backgroundGradient', 
                                'appBackground.backgroundOpacity', 'appBackground.buttonOpacity',
                                'appBackground.displayOpacity']
                
                protected_app_bg_fields = [field for field in app_bg_fields if field in protected_fields]
                if protected_app_bg_fields:
                    if 'appBackground' not in fixed_config:
                        fixed_config['appBackground'] = {}
                    
                    for field in protected_app_bg_fields:
                        field_name = field.split('.')[1]
                        if field_name in current_app_background:
                            fixed_config['appBackground'][field_name] = current_app_background[field_name]
                            print(f"🛡️ 重新保护APP背景字段: {field} = {current_app_background[field_name]}")
                
                # 重新保护主题字段
                if 'theme.backgroundImage' in protected_fields:
                    fixed_config.setdefault('theme', {})['backgroundImage'] = current_theme.get('backgroundImage')
                if 'theme.backgroundColor' in protected_fields:
                    fixed_config.setdefault('theme', {})['backgroundColor'] = current_theme.get('backgroundColor')
                if 'theme.backgroundGradient' in protected_fields:
                    fixed_config.setdefault('theme', {})['backgroundGradient'] = current_theme.get('backgroundGradient')
                
                # 重新保护按钮背景图
                current_buttons = {btn.get('id'): btn for btn in current_layout.get('buttons', [])}
                fixed_buttons = fixed_config.get('layout', {}).get('buttons', [])
                for button in fixed_buttons:
                    button_id = button.get('id')
                    if f'button.{button_id}.backgroundImage' in protected_fields:
                        current_button = current_buttons.get(button_id, {})
                        if current_button.get('backgroundImage'):
                            button['backgroundImage'] = current_button['backgroundImage']
                            print(f"🛡️ 重新保护按钮背景图: button.{button_id}.backgroundImage")
                
                print("🛡️ 重新应用保护逻辑完成")
            
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
        'parallaxEffect', 'parallaxIntensity', 'buttonOpacity', 'displayOpacity'
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

def merge_background_data(current_config: dict, generated_config: dict, protected_fields: list) -> dict:
    """
    强制合并现有配置中的背景图像数据到新生成的配置中，确保AI不会清空背景
    """
    if not current_config:
        return generated_config
    
    print(f"🔧 开始强制合并背景数据，保护字段: {len(protected_fields)}")
    
    # 确保生成的配置有正确的结构
    if 'theme' not in generated_config:
        generated_config['theme'] = {}
    if 'appBackground' not in generated_config:
        generated_config['appBackground'] = {}
    if 'layout' not in generated_config:
        generated_config['layout'] = {}
    if 'buttons' not in generated_config['layout']:
        generated_config['layout']['buttons'] = []
    
    # 🔧 强制合并APP背景数据
    current_app_bg = current_config.get('appBackground', {})
    if current_app_bg:
        generated_app_bg = generated_config['appBackground']
        
        # 强制保留所有背景相关字段
        background_fields = [
            'backgroundImageUrl', 'backgroundType', 'backgroundColor', 
            'backgroundGradient', 'backgroundOpacity', 'backgroundBlendMode',
            'parallaxEffect', 'parallaxIntensity', 'buttonOpacity', 'displayOpacity'
        ]
        
        for field in background_fields:
            if field in current_app_bg:
                generated_app_bg[field] = current_app_bg[field]
                print(f"🔧 强制保留APP背景字段: appBackground.{field}")
    
    # 🔧 强制合并主题背景数据
    current_theme = current_config.get('theme', {})
    if current_theme:
        generated_theme = generated_config['theme']
        
        # 强制保留主题背景相关字段
        theme_background_fields = [
            'backgroundImage', 'backgroundColor', 'backgroundGradient',
            'backgroundPattern', 'patternColor', 'patternOpacity'
        ]
        
        for field in theme_background_fields:
            if field in current_theme:
                generated_theme[field] = current_theme[field]
                print(f"🔧 强制保留主题背景字段: theme.{field}")
    
    # 🔧 强制重新应用按键背景图 - 参考图像生成工坊逻辑
    generated_config = force_reapply_button_background_images(current_config, generated_config)
    
    print(f"✅ 背景数据强制合并完成")
    return generated_config

def force_reapply_button_background_images(current_config: dict, generated_config: dict) -> dict:
    """
    强制重新应用按键背景图，参考图像生成工坊的实现逻辑
    确保现有按键背景图在AI生成后100%保留
    """
    print(f"🔧 开始强制重新应用按键背景图")
    
    current_buttons = current_config.get('layout', {}).get('buttons', [])
    generated_buttons = generated_config['layout']['buttons']
    
    # 创建现有按键的字典以便快速查找
    current_buttons_dict = {btn.get('id', ''): btn for btn in current_buttons}
    
    # 统计有背景图的按键
    buttons_with_background = []
    for btn in current_buttons:
        btn_id = btn.get('id', '')
        if btn.get('backgroundImage'):
            buttons_with_background.append(btn_id)
    
    if not buttons_with_background:
        print("🔧 没有发现需要保护的按键背景图")
        return generated_config
    
    print(f"🔧 发现 {len(buttons_with_background)} 个按键有背景图需要保护: {buttons_with_background}")
    
    # 对每个生成的按键强制重新应用背景图
    for i, generated_button in enumerate(generated_buttons):
        button_id = generated_button.get('id', '')
        
        if button_id in current_buttons_dict:
            current_button = current_buttons_dict[button_id]
            
            # 🔧 参考图像生成工坊 _updateButtonPattern 的逻辑
            # 如果当前按键有背景图，强制重新应用
            if current_button.get('backgroundImage'):
                print(f"🔧 强制重新应用按键背景图: {button_id}")
                
                # 🔧 创建新的按键对象，确保所有属性都被正确保留
                updated_button = {
                    'id': generated_button.get('id', current_button.get('id')),
                    'label': generated_button.get('label', current_button.get('label')),
                    'action': generated_button.get('action', current_button.get('action')),
                    'gridPosition': generated_button.get('gridPosition', current_button.get('gridPosition')),
                    'type': generated_button.get('type', current_button.get('type')),
                    'customColor': generated_button.get('customColor', current_button.get('customColor')),
                    'isWide': generated_button.get('isWide', current_button.get('isWide', False)),
                    'widthMultiplier': generated_button.get('widthMultiplier', current_button.get('widthMultiplier', 1.0)),
                    'heightMultiplier': generated_button.get('heightMultiplier', current_button.get('heightMultiplier', 1.0)),
                    'gradientColors': generated_button.get('gradientColors', current_button.get('gradientColors')),
                    'fontSize': generated_button.get('fontSize', current_button.get('fontSize')),
                    'borderRadius': generated_button.get('borderRadius', current_button.get('borderRadius')),
                    'elevation': generated_button.get('elevation', current_button.get('elevation')),
                    'width': generated_button.get('width', current_button.get('width')),
                    'height': generated_button.get('height', current_button.get('height')),
                    'backgroundColor': generated_button.get('backgroundColor', current_button.get('backgroundColor')),
                    'textColor': generated_button.get('textColor', current_button.get('textColor')),
                    'borderColor': generated_button.get('borderColor', current_button.get('borderColor')),
                    'borderWidth': generated_button.get('borderWidth', current_button.get('borderWidth')),
                    'shadowColor': generated_button.get('shadowColor', current_button.get('shadowColor')),
                    'shadowOffset': generated_button.get('shadowOffset', current_button.get('shadowOffset')),
                    'shadowRadius': generated_button.get('shadowRadius', current_button.get('shadowRadius')),
                    'opacity': generated_button.get('opacity', current_button.get('opacity')),
                    'rotation': generated_button.get('rotation', current_button.get('rotation')),
                    'scale': generated_button.get('scale', current_button.get('scale')),
                    'backgroundPattern': generated_button.get('backgroundPattern', current_button.get('backgroundPattern')),
                    'patternColor': generated_button.get('patternColor', current_button.get('patternColor')),
                    'patternOpacity': generated_button.get('patternOpacity', current_button.get('patternOpacity')),
                    'animation': generated_button.get('animation', current_button.get('animation')),
                    'animationDuration': generated_button.get('animationDuration', current_button.get('animationDuration')),
                    'customIcon': generated_button.get('customIcon', current_button.get('customIcon')),
                    'iconSize': generated_button.get('iconSize', current_button.get('iconSize')),
                    'iconColor': generated_button.get('iconColor', current_button.get('iconColor')),
                    # 🔧 最关键：强制保留背景图
                    'backgroundImage': current_button.get('backgroundImage'),
                }
                
                # 🔧 移除None值，保持配置清洁
                updated_button = {k: v for k, v in updated_button.items() if v is not None}
                
                # 🔧 替换生成的按键
                generated_buttons[i] = updated_button
                
                print(f"✅ 成功重新应用按键背景图: {button_id} -> {current_button.get('backgroundImage')[:50]}...")
    
    print(f"✅ 按键背景图强制重新应用完成")
    return generated_config

def clean_invalid_buttons(config_dict: dict, preserve_button_ids: list = None) -> dict:
    """清理无效按键，确保所有按键都有实际功能，同时保护现有按键"""
    if "layout" not in config_dict or "buttons" not in config_dict["layout"]:
        return config_dict
    
    original_buttons = config_dict["layout"]["buttons"]
    valid_buttons = []
    preserve_button_ids = preserve_button_ids or []
    
    print(f"🔍 开始清理无效按键，原始按键数量: {len(original_buttons)}")
    print(f"🛡️ 需要保护的按键ID: {preserve_button_ids}")
    
    for button in original_buttons:
        # 检查按键是否有效
        is_valid = True
        invalid_reasons = []
        button_id = button.get("id", "")
        
        # 🛡️ 特殊保护：如果是现有按键，只做基础验证
        is_existing_button = button_id in preserve_button_ids
        
        if is_existing_button:
            print(f"🛡️ 保护现有按键: {button.get('label', '未知')} ({button_id})")
            # 对现有按键只做最基础的验证，尽量保留
            if not button.get("label") or not button.get("action"):
                # 尝试修复而不是删除
                if not button.get("label"):
                    button["label"] = button_id.replace("btn_", "").upper()
                    print(f"🔧 修复按键label: {button_id} -> {button['label']}")
                if not button.get("action"):
                    button["action"] = {"type": "input", "value": "0"}
                    print(f"🔧 修复按键action: {button_id}")
            
            # 确保现有按键有gridPosition
            if not button.get("gridPosition"):
                button["gridPosition"] = {"row": 1, "column": 0}
                print(f"🔧 修复按键位置: {button_id}")
            
            valid_buttons.append(button)
            continue
        
        # 🔍 对新增按键进行严格验证
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
            # 限制在合理范围内：最多12行×10列
            if row < 1 or row > 12 or col < 0 or col > 9:
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
            print(f"❌ 移除无效新增按键: {button.get('label', '未知')} - {', '.join(invalid_reasons)}")
    
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
        # 🔧 修复：清理配置中的大量数据以避免token超限
        def clean_config_for_ai(config: dict) -> dict:
            """移除配置中的大数据字段以减少token数量"""
            if not config:
                return config
                
            cleaned = json.loads(json.dumps(config))  # 深拷贝
            
            # 移除base64图像数据
            def remove_base64_images(obj):
                if isinstance(obj, dict):
                    for key, value in list(obj.items()):
                        if isinstance(value, str) and (
                            key.endswith('Image') or 
                            key.endswith('ImageUrl') or 
                            key.endswith('backgroundImage') or
                            'image' in key.lower()
                        ) and (
                            value.startswith('data:image/') or 
                            len(value) > 1000  # 超过1000字符的可能是base64
                        ):
                            obj[key] = f"[图像数据已省略-长度:{len(value)}字符]"
                        elif isinstance(value, (dict, list)):
                            remove_base64_images(value)
                elif isinstance(obj, list):
                    for item in obj:
                        if isinstance(item, (dict, list)):
                            remove_base64_images(item)
            
            remove_base64_images(cleaned)
            return cleaned
        
        # 清理配置数据
        clean_current = clean_config_for_ai(current_config) if current_config else None
        clean_generated = clean_config_for_ai(generated_config)
        
        # 构建修复上下文
        fix_context = f"""
用户需求：{user_input}

现有配置摘要（需要继承的部分）：
{json.dumps(clean_current, ensure_ascii=False, indent=2) if clean_current else "无现有配置"}

生成的配置（需要修复）：
{json.dumps(clean_generated, ensure_ascii=False, indent=2)}

请修复上述配置中的问题，确保：
1. 满足用户需求
2. 继承现有配置中用户未要求修改的部分（特别是图像数据字段要保持原值）
3. 包含所有必需的基础按钮
4. 所有按钮都有正确的action字段
5. 布局结构合理
6. 保持原有的图像数据不变（backgroundImage、backgroundImageUrl等）

注意：配置中的图像数据已被省略显示，但在修复时请保持原有的图像数据字段不变。

直接返回修正后的完整JSON配置。
"""

        print(f"🔧 修复上下文长度: {len(fix_context)} 字符")

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
            
            # 🔧 重要：恢复原始图像数据
            def restore_image_data(fixed: dict, original: dict):
                """将原始配置中的图像数据恢复到修复后的配置中"""
                if not original:
                    return
                    
                def restore_images(fixed_obj, original_obj):
                    if isinstance(fixed_obj, dict) and isinstance(original_obj, dict):
                        for key, original_value in original_obj.items():
                            if isinstance(original_value, str) and (
                                key.endswith('Image') or 
                                key.endswith('ImageUrl') or 
                                key.endswith('backgroundImage') or
                                'image' in key.lower()
                            ) and (
                                original_value.startswith('data:image/') or 
                                len(original_value) > 1000
                            ):
                                # 恢复原始图像数据
                                fixed_obj[key] = original_value
                                print(f"🔧 恢复图像数据字段: {key}")
                            elif isinstance(original_value, dict) and key in fixed_obj:
                                restore_images(fixed_obj[key], original_value)
                            elif isinstance(original_value, list) and key in fixed_obj and isinstance(fixed_obj[key], list):
                                for i, item in enumerate(original_value):
                                    if i < len(fixed_obj[key]) and isinstance(item, dict) and isinstance(fixed_obj[key][i], dict):
                                        restore_images(fixed_obj[key][i], item)
            
            # 恢复当前配置和生成配置中的图像数据
            restore_image_data(fixed_config, current_config)
            restore_image_data(fixed_config, generated_config)
            
            print("✅ AI修复成功，图像数据已恢复")
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

# 🔧 新增：异步任务端点
@app.post("/tasks/submit/customize")
async def submit_customize_task(request: CustomizationRequest, background_tasks: BackgroundTasks) -> TaskResponse:
    """提交计算器定制任务"""
    try:
        # 清理过期任务
        cleanup_old_tasks()
        
        # 创建任务
        task_id = create_task("customize", request.dict())
        
        # 启动后台处理
        background_tasks.add_task(process_task_in_background, task_id)
        
        return TaskResponse(
            task_id=task_id,
            status=TaskStatus.PENDING,
            message="计算器定制任务已提交，正在后台处理..."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"提交任务失败: {str(e)}")

@app.post("/tasks/submit/generate-image")
async def submit_generate_image_task(request: ImageGenerationRequest, background_tasks: BackgroundTasks) -> TaskResponse:
    """提交图像生成任务"""
    try:
        cleanup_old_tasks()
        task_id = create_task("generate-image", request.dict())
        background_tasks.add_task(process_task_in_background, task_id)
        
        return TaskResponse(
            task_id=task_id,
            status=TaskStatus.PENDING,
            message="图像生成任务已提交，正在后台处理..."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"提交任务失败: {str(e)}")

@app.post("/tasks/submit/generate-pattern")
async def submit_generate_pattern_task(request: ImageGenerationRequest, background_tasks: BackgroundTasks) -> TaskResponse:
    """提交按键背景图生成任务"""
    try:
        cleanup_old_tasks()
        task_id = create_task("generate-pattern", request.dict())
        background_tasks.add_task(process_task_in_background, task_id)
        
        return TaskResponse(
            task_id=task_id,
            status=TaskStatus.PENDING,
            message="按键背景图生成任务已提交，正在后台处理..."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"提交任务失败: {str(e)}")

@app.post("/tasks/submit/generate-app-background")
async def submit_generate_app_background_task(request: AppBackgroundRequest, background_tasks: BackgroundTasks) -> TaskResponse:
    """提交APP背景图生成任务"""
    try:
        cleanup_old_tasks()
        task_id = create_task("generate-app-background", request.dict())
        background_tasks.add_task(process_task_in_background, task_id)
        
        return TaskResponse(
            task_id=task_id,
            status=TaskStatus.PENDING,
            message="APP背景图生成任务已提交，正在后台处理..."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"提交任务失败: {str(e)}")

@app.post("/tasks/submit/generate-text-image")
async def submit_generate_text_image_task(request: TextImageRequest, background_tasks: BackgroundTasks) -> TaskResponse:
    """提交文字图像生成任务"""
    try:
        cleanup_old_tasks()
        task_id = create_task("generate-text-image", request.dict())
        background_tasks.add_task(process_task_in_background, task_id)
        
        return TaskResponse(
            task_id=task_id,
            status=TaskStatus.PENDING,
            message="文字图像生成任务已提交，正在后台处理..."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"提交任务失败: {str(e)}")

@app.get("/tasks/{task_id}/status")
async def get_task_status(task_id: str) -> TaskStatusResponse:
    """查询任务状态"""
    task = get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return TaskStatusResponse(
        task_id=task.id,
        status=task.status,
        result=task.result,
        error=task.error,
        progress=task.progress,
        created_at=task.created_at,
        updated_at=task.updated_at
    )

@app.get("/tasks")
async def list_tasks() -> Dict[str, Any]:
    """列出所有任务（调试用）"""
    try:
        tasks = []
        
        # 扫描任务目录
        for filename in os.listdir(TASKS_DIR):
            if not filename.endswith('.json'):
                continue
                
            task_file = os.path.join(TASKS_DIR, filename)
            try:
                with open(task_file, 'r', encoding='utf-8') as f:
                    task_dict = json.load(f)
                    tasks.append({
                        "id": task_dict["id"],
                        "type": task_dict["type"],
                        "status": task_dict["status"],
                        "created_at": task_dict["created_at"],
                        "updated_at": task_dict["updated_at"],
                        "progress": task_dict.get("progress")
                    })
            except Exception as e:
                print(f"❌ 读取任务文件时出错 {filename}: {e}")
        
        return {
            "total_tasks": len(tasks),
            "tasks": sorted(tasks, key=lambda x: x["created_at"], reverse=True)
        }
    except Exception as e:
        print(f"❌ 列出任务时出错: {e}")
        return {"total_tasks": 0, "tasks": []}

@app.delete("/tasks/{task_id}")
async def delete_task(task_id: str) -> Dict[str, str]:
    """删除任务"""
    task_file = os.path.join(TASKS_DIR, f"{task_id}.json")
    
    if not os.path.exists(task_file):
        raise HTTPException(status_code=404, detail="任务不存在")
    
    try:
        with tasks_lock:
            os.remove(task_file)
        return {"message": f"任务 {task_id} 已删除"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除任务失败: {e}")

# 🔧 新增：具体的任务处理函数
def process_customize_task(task_id: str, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """处理计算器定制任务"""
    try:
        user_input = request_data.get("user_input")
        conversation_history = request_data.get("conversation_history", [])
        current_config = request_data.get("current_config")
        has_image_workshop_content = request_data.get("has_image_workshop_content", False)
        workshop_protected_fields = request_data.get("workshop_protected_fields", [])
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.2)
        
        protected_fields = []
        workshop_protection_info = ""
        
        # 🔧 自动检测并保护现有背景图像，无论是否来自图像生成工坊
        if current_config:
            theme = current_config.get('theme', {})
            layout = current_config.get('layout', {})
            app_background = current_config.get('appBackground', {})
            
            # 🔧 自动检测APP背景并保护
            if app_background.get('backgroundImageUrl'):
                protected_fields.extend([
                    'appBackground.backgroundImageUrl',
                    'appBackground.backgroundType',
                    'appBackground.backgroundColor',
                    'appBackground.backgroundGradient',
                    'appBackground.backgroundOpacity',
                    'appBackground.buttonOpacity',      # 🔧 新增：保护按键透明度
                    'appBackground.displayOpacity',     # 🔧 新增：保护显示区域透明度
                    'appBackground.backgroundBlendMode',
                    'appBackground.parallaxEffect',
                    'appBackground.parallaxIntensity'
                ])
                print(f"🛡️ 自动检测到APP背景图像，已加入保护列表")
            
            # 🔧 保护透明度设置（即使没有背景图）
            if app_background.get('buttonOpacity') is not None:
                protected_fields.append('appBackground.buttonOpacity')
                print(f"🛡️ 自动检测到按键透明度设置，已加入保护列表")
            if app_background.get('displayOpacity') is not None:
                protected_fields.append('appBackground.displayOpacity')
                print(f"🛡️ 自动检测到显示区域透明度设置，已加入保护列表")
            
            # 🔧 自动检测主题背景并保护
            if theme.get('backgroundImage'):
                protected_fields.extend([
                    'theme.backgroundImage', 
                    'theme.backgroundColor', 
                    'theme.backgroundGradient',
                    'theme.backgroundPattern'
                ])
                print(f"🛡️ 自动检测到主题背景图像，已加入保护列表")
            
            if theme.get('backgroundPattern'):
                protected_fields.extend([
                    'theme.backgroundPattern', 
                    'theme.patternColor', 
                    'theme.patternOpacity'
                ])
                print(f"🛡️ 自动检测到主题背景图案，已加入保护列表")
            
            # 🔧 自动检测按键背景并保护
            if layout.get('buttons'):
                for button in layout['buttons']:
                    button_id = button.get('id', '')
                    if button.get('backgroundImage'):
                        protected_fields.extend([
                            f'layout.buttons[{button_id}].backgroundImage',
                            f'layout.buttons[{button_id}].backgroundColor',
                            f'layout.buttons[{button_id}].opacity',
                            f'layout.buttons[{button_id}].borderRadius'
                        ])
                        print(f"🛡️ 自动检测到按键背景图像: {button_id}，已加入保护列表")
                    if button.get('backgroundPattern'):
                        protected_fields.extend([
                            f'layout.buttons[{button_id}].backgroundPattern',
                            f'layout.buttons[{button_id}].patternColor',
                            f'layout.buttons[{button_id}].patternOpacity'
                        ])
                        print(f"🛡️ 自动检测到按键背景图案: {button_id}，已加入保护列表")
            
            # 🔧 自动检测其他图像相关属性
            if theme.get('backgroundGradient'):
                protected_fields.append('theme.backgroundGradient')
                print(f"🛡️ 自动检测到主题背景渐变，已加入保护列表")
            
            if protected_fields:
                workshop_protection_info = f"""
🛡️ **自动背景保护提醒**：
检测到以下背景图像和视觉效果将被自动保护，不会被修改：
{chr(10).join([f"• {field}" for field in protected_fields[:8]])}
{'• ...' if len(protected_fields) > 8 else ''}

⚠️ **重要**：AI设计师将保持所有现有背景图像和视觉效果不变，只修改功能性配置。
如需修改这些视觉元素，请前往图像生成工坊进行调整。
                """

        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.4)

        history_context = ""
        if conversation_history:
            history_context = "\n\n💬 **对话上下文**：\n"
            for i, msg in enumerate(conversation_history[-3:]):
                role = "用户" if msg.get("role") == "user" else "助手"
                content = msg.get("content", "")[:100]
                history_context += f"{role}: {content}\n"

        config_context = ""
        button_analysis = ""
        if current_config:
            layout_info = current_config.get('layout', {})
            theme_info = current_config.get('theme', {})
            buttons = layout_info.get('buttons', [])
            button_count = len(buttons)
            rows = layout_info.get('rows', 0)
            cols = layout_info.get('columns', 0)
            
            # 🔍 深度分析现有按键配置
            existing_buttons_by_type = {
                'numbers': [],
                'operators': [], 
                'functions': [],
                'scientific': [],
                'special': []
            }
            
            button_ids = []
            for button in buttons:
                btn_id = button.get('id', '')
                btn_label = button.get('label', '')
                btn_action = button.get('action', {})
                btn_type = btn_action.get('type', '')
                
                button_ids.append(btn_id)
                
                # 分类按键
                if btn_type == 'input' and btn_label.isdigit():
                    existing_buttons_by_type['numbers'].append(f"{btn_label}({btn_id})")
                elif btn_type == 'operator':
                    existing_buttons_by_type['operators'].append(f"{btn_label}({btn_id})")
                elif btn_type == 'expression':
                    existing_buttons_by_type['scientific'].append(f"{btn_label}({btn_id})")
                elif btn_type in ['multiParamFunction', 'customFunction']:
                    existing_buttons_by_type['functions'].append(f"{btn_label}({btn_id})")
                else:
                    existing_buttons_by_type['special'].append(f"{btn_label}({btn_id})")
            
            button_analysis = f"""
🔍 **现有按键详细分析**（必须100%保留）：
• 数字按键：{', '.join(existing_buttons_by_type['numbers']) if existing_buttons_by_type['numbers'] else '无'}
• 运算符：{', '.join(existing_buttons_by_type['operators']) if existing_buttons_by_type['operators'] else '无'}
• 科学函数：{', '.join(existing_buttons_by_type['scientific']) if existing_buttons_by_type['scientific'] else '无'}
• 高级函数：{', '.join(existing_buttons_by_type['functions']) if existing_buttons_by_type['functions'] else '无'}
• 特殊功能：{', '.join(existing_buttons_by_type['special']) if existing_buttons_by_type['special'] else '无'}

🚨 **绝对禁止删除的按键ID列表**：
{', '.join(button_ids) if button_ids else '无'}

⚠️ **继承性修改要求**：
1. 上述所有按键ID必须在新配置中完全保留
2. 只能在现有基础上添加新按键或修改用户明确要求的按键
3. 如需空间，扩展行数/列数，不要删除现有按键
4. 保持现有按键的功能和位置（除非用户明确要求改变）
            """
            
            config_context = f"""
📊 **当前配置概要**：
• 布局：{rows}行×{cols}列，共{button_count}个按键
• 主题：{theme_info.get('name', '未命名')}
• 背景色：{theme_info.get('backgroundColor', '#000000')}
• 显示区域色：{theme_info.get('displayBackgroundColor', '#222222')}
            """

        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.6)

        initialize_genai()
        model = get_current_model()

        full_prompt = f"""
{SYSTEM_PROMPT}

{workshop_protection_info}

{config_context}

{button_analysis}

{history_context}

🎯 **用户需求**：{user_input}

💡 **继承式修改提醒**：请严格基于上述现有按键分析，在保留所有现有按键的前提下，实现用户的需求。绝对不要删除任何现有按键ID。

请基于用户需求生成或修改计算器配置。"""

        start_time = time.time()
        print(f"🚀 开始AI推理 (用户输入: {user_input[:50]}...)")

        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.8)

        response = model.generate_content(full_prompt)
        
        if not response or not response.text:
            raise Exception("AI返回空响应")

        ai_response_text = response.text.strip()
        print(f"📝 AI响应文本长度: {len(ai_response_text)} 字符")

        json_match = re.search(r'```json\s*\n(.*?)\n\s*```', ai_response_text, re.DOTALL)
        if not json_match:
            json_match = re.search(r'\{.*\}', ai_response_text, re.DOTALL)
        
        if not json_match:
            raise Exception("无法从AI响应中提取JSON配置")

        json_str = json_match.group(1) if json_match.groups() else json_match.group(0)
        
        try:
            generated_config = json.loads(json_str)
        except json.JSONDecodeError as e:
            print(f"❌ JSON解析失败: {e}")
            raise Exception(f"JSON格式错误: {e}")

        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.9)

        if protected_fields:
            generated_config = remove_protected_fields_from_ai_output(generated_config, protected_fields)

        generated_config = clean_gradient_format(generated_config)
        
        # 🛡️ 获取现有按键ID列表以进行保护
        existing_button_ids = []
        if current_config and current_config.get('layout', {}).get('buttons'):
            existing_button_ids = [btn.get('id', '') for btn in current_config['layout']['buttons']]
        
        generated_config = clean_invalid_buttons(generated_config, existing_button_ids)

        try:
            if current_config:
                import asyncio
                generated_config = asyncio.run(fix_calculator_config(user_input, current_config, generated_config))
        except Exception as fix_error:
            print(f"⚠️ AI修复失败，使用原始生成结果: {fix_error}")

        # 🔧 强制合并现有配置中的背景图像数据，确保不被AI覆盖
        if current_config:
            generated_config = merge_background_data(current_config, generated_config, protected_fields)

        if not generated_config.get('layout', {}).get('buttons'):
            raise Exception("生成的配置缺少按键布局")

        generated_config['version'] = "2.0.0"
        generated_config['createdAt'] = datetime.now().isoformat()
        generated_config['authorPrompt'] = user_input
        generated_config['aiResponse'] = ai_response_text

        duration = time.time() - start_time
        print(f"✅ AI定制完成，耗时: {duration:.2f}秒")

        return {
            "success": True,
            "config": generated_config,
            "processing_time": duration,
            "protected_fields": protected_fields
        }

    except Exception as e:
        print(f"❌ 计算器定制任务失败: {str(e)}")
        raise e

def process_generate_image_task(task_id: str, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """处理图像生成任务"""
    try:
        prompt = request_data.get("prompt")
        style = request_data.get("style", "realistic")
        size = request_data.get("size", "1024x1024")
        quality = request_data.get("quality", "standard")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.2)
        
        # 构建优化的图像生成提示词
        enhanced_prompt = f"""
        Generate a high-quality image for calculator theme:
        {prompt}
        
        Style: {style}
        Requirements:
        - High resolution and professional quality
        - Suitable for calculator app background or button design
        - Clean, modern aesthetic
        - Good contrast for readability
        """
        
        print(f"🎨 开始生成图像，提示词: {enhanced_prompt}")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.4)
        
        # 初始化AI模型
        initialize_genai()
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成图像 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.6)
        
        response = image_model.generate_content(
            contents=[enhanced_prompt],
            generation_config=generation_config
        )
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.8)
        
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
                        "original_prompt": prompt,
                        "enhanced_prompt": enhanced_prompt,
                        "style": style,
                        "size": size,
                        "quality": quality,
                        "message": "图像生成成功"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图像，返回错误
        raise Exception("未能生成图像，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"❌ 图像生成任务失败: {str(e)}")
        raise e

def process_generate_pattern_task(task_id: str, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """处理按键背景图生成任务"""
    try:
        prompt = request_data.get("prompt")
        style = request_data.get("style", "minimal")
        size = request_data.get("size", "48x48")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.2)
        
        # 针对按钮图案的特殊处理
        pattern_prompt = f"""
        Generate a seamless pattern for calculator button background:
        {prompt}
        
        Requirements:
        - Seamless and tileable pattern
        - Suitable for button background use
        - Subtle and not distracting from text
        - Style: {style}
        - High contrast for text readability
        - Professional and clean design
        - 256x256 pixels optimal size
        """
        
        print(f"🎨 开始生成图案，提示词: {pattern_prompt}")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.4)
        
        # 初始化AI模型
        initialize_genai()
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成图案 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.6)
        
        response = image_model.generate_content(
            contents=[pattern_prompt],
            generation_config=generation_config
        )
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.8)
        
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
                        "original_prompt": prompt,
                        "enhanced_prompt": pattern_prompt,
                        "style": style,
                        "is_seamless": True,
                        "message": "图案生成成功"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图案，返回错误
        raise Exception("未能生成图案，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"❌ 按键背景图生成任务失败: {str(e)}")
        raise e

def process_generate_app_background_task(task_id: str, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """处理APP背景图生成任务"""
    try:
        prompt = request_data.get("prompt")
        style = request_data.get("style", "modern")
        size = request_data.get("size", "1080x1920")
        quality = request_data.get("quality", "high")
        theme = request_data.get("theme", "calculator")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.2)
        
        # 构建专门的APP背景图生成提示词
        background_prompt = f"""
        Generate a beautiful background image for a calculator mobile app:
        {prompt}
        
        Requirements:
        - Mobile app background (portrait orientation {size})
        - Style: {style} with {theme} theme
        - Subtle and elegant, won't interfere with UI elements
        - Good contrast for calculator buttons and display
        - Professional and modern aesthetic
        - High quality and resolution
        - Colors should complement calculator interface
        - Avoid too busy patterns that distract from functionality
        
        Theme context: {theme}
        Quality: {quality}
        """
        
        print(f"🎨 开始生成APP背景图，提示词: {background_prompt}")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.4)
        
        # 初始化AI模型
        initialize_genai()
        
        # 使用Gemini 2.0 Flash图像生成模型
        image_model = genai.GenerativeModel("gemini-2.0-flash-preview-image-generation")
        
        # 生成背景图 - 使用正确的配置
        generation_config = {
            "response_modalities": ["TEXT", "IMAGE"]
        }
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.6)
        
        response = image_model.generate_content(
            contents=[background_prompt],
            generation_config=generation_config
        )
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.8)
        
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
                        "original_prompt": prompt,
                        "enhanced_prompt": background_prompt,
                        "style": style,
                        "theme": theme,
                        "size": size,
                        "quality": quality,
                        "message": "APP背景图生成成功",
                        "usage_tips": "此背景图已优化用于计算器应用，确保UI元素的可读性"
                    }
        
        # 如果没有图像数据，检查文本响应
        if response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成背景图，返回错误
        raise Exception("未能生成APP背景图，请检查提示词或稍后重试")
        
    except Exception as e:
        print(f"❌ APP背景图生成任务失败: {str(e)}")
        raise e

def process_generate_text_image_task(task_id: str, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """处理文字图像生成任务"""
    try:
        prompt = request_data.get("prompt")
        text = request_data.get("text")
        style = request_data.get("style", "modern")
        size = request_data.get("size", "512x512")
        background = request_data.get("background", "transparent")
        effects = request_data.get("effects", [])
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.2)
        
        print(f"🎨 正在生成创意字符图片...")
        print(f"字符内容: {text}")
        print(f"原始创意描述: {prompt}")
        print(f"风格: {style}")
        
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
        cleaned_prompt = clean_user_prompt(prompt) if prompt else ""
        print(f"清理后创意描述: {cleaned_prompt}")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.4)
        
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
        style_effect = style_effects.get(style, style_effects["modern"])
        
        # 🎨 创意字符构造：极简提示词，避免AI误解指令为显示内容
        if cleaned_prompt and cleaned_prompt.strip():
            # 极简直接指令，避免任何可能被误解的英文描述
            detailed_prompt = f"""Show number "{text}" made from {cleaned_prompt}. Pure visual art only. No text anywhere. Clean {background} background."""
        else:
            # 标准设计，同样极简
            detailed_prompt = f"""Show number "{text}" {style_effect}. Pure visual art only. No text anywhere. Clean {background} background."""

        print(f"🚀 使用提示词: {detailed_prompt}")
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.6)
        
        # 初始化AI模型
        initialize_genai()
        
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
        
        update_task_status(task_id, TaskStatus.PROCESSING, progress=0.8)
        
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
                    
                    print(f"✅ 创意字符图片生成成功: '{text}'，MIME类型: {mime_type}")
                    
                    return {
                        "success": True,
                        "image_url": text_image_base64,
                        "text": text,
                        "style": style,
                        "size": size,
                        "background": background,
                        "effects": effects,
                        "mime_type": mime_type,
                        "original_prompt": prompt,
                        "cleaned_prompt": cleaned_prompt,
                        "enhanced_prompt": detailed_prompt,
                        "message": f"创意字符 '{text}' 生成成功"
                    }
        
        # 检查是否有文本响应
        if hasattr(response, 'text') and response.text:
            print(f"🤖 AI响应: {response.text}")
            
        # 如果没有生成图像，返回错误
        raise Exception("未找到生成的图像数据")
        
    except Exception as e:
        print(f"❌ 文字图像生成任务失败: {str(e)}")
        raise e

# 可用模型配置

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080))) 