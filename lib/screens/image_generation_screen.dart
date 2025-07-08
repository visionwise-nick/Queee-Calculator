import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../services/ai_service.dart';
import '../services/task_service.dart'; // 🔧 新增：导入任务服务
import '../providers/calculator_provider.dart';
import '../widgets/generation_status_widget.dart'; // 🔧 新增：导入状态显示组件
import 'dart:convert';
import 'dart:typed_data';

class ImageGenerationScreen extends StatefulWidget {
  final CalculatorConfig currentConfig;
  final Function(CalculatorConfig) onConfigUpdated;

  const ImageGenerationScreen({
    Key? key,
    required this.currentConfig,
    required this.onConfigUpdated,
  }) : super(key: key);

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _appBgPromptController = TextEditingController();
  final TextEditingController _buttonBgPromptController = TextEditingController();
  
  bool _isGeneratingAppBg = false;
  bool _isGeneratingButtonBg = false;
  String? _generatedAppBgUrl;

  // 🔧 修正透明度控制变量概念
  double _buttonOpacity = 0.7;     // 按键透明度 - 让背景图可以透过来
  double _displayOpacity = 0.7;    // 显示区域透明度 - 让背景图可以透过来

  // 按键背景图相关状态
  Set<String> _selectedButtonBgIds = {}; // 多选按键ID集合（按键背景图）
  bool _selectAllBg = false;
  bool _isGeneratingButtonPattern = false;
  final TextEditingController _buttonPatternPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 改为2个tab
    
    // 🔧 从现有配置中加载透明度设置
    final appBackground = widget.currentConfig.appBackground;
    if (appBackground != null) {
      _buttonOpacity = appBackground.buttonOpacity ?? 0.7;
      _displayOpacity = appBackground.displayOpacity ?? 0.7;
      _generatedAppBgUrl = appBackground.backgroundImageUrl; // 加载现有背景图
    }
    
    // 🔧 添加调试信息
    print('🔧 透明度初始化：按键透明度=${_buttonOpacity}，显示区域透明度=${_displayOpacity}');
    print('🔧 现有背景图：${_generatedAppBgUrl != null ? "存在(${_generatedAppBgUrl!.length}字符)" : "无"}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appBgPromptController.dispose();
    _buttonBgPromptController.dispose();
    _buttonPatternPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.palette, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 8),
            Text(
              '🎨 图像生成工坊',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.orange.shade600),
            onPressed: _showResetDialog,
            tooltip: '恢复默认',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(
              icon: Icon(Icons.texture),
              text: '按键',
            ),
            Tab(
              icon: Icon(Icons.wallpaper),
              text: 'APP背景',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔧 新增：全局生成状态栏
          const GlobalGenerationStatusBar(),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildButtonBackgroundTab(), // 按键背景tab放到第一个
                _buildAppBackgroundTab(),    // APP背景tab放到第二个
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔧 新增：独立的透明度控制区域（放在最上面）
          _buildOpacityControlCard(),
          const SizedBox(height: 20),
          
          // 自定义生成区域
          _buildCustomGenerationCard(),
          const SizedBox(height: 20),
          
          // 快速选择区域
          _buildQuickSelectionCard(),
          const SizedBox(height: 20),
          
          // 预览和应用区域
          if (_generatedAppBgUrl != null) _buildPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildQuickSelectionCard() {
    final quickPrompts = [
      {
        'title': '🌟 现代几何',
        'prompt': '优雅的现代几何背景，深蓝色渐变配金色线条，适合专业计算器',
        'color': Colors.blue,
      },
      {
        'title': '🌙 夜间护眼',
        'prompt': '深色护眼背景，温暖的橙色光晕，适合夜间使用的计算器',
        'color': Colors.indigo,
      },
      {
        'title': '🎮 科技未来',
        'prompt': '赛博朋克风格背景，霓虹蓝紫色调，科技感十足的计算器界面',
        'color': Colors.purple,
      },
      {
        'title': '🌸 温馨粉色',
        'prompt': '柔和的粉色渐变背景，配白色几何图案，温馨可爱的计算器',
        'color': Colors.pink,
      },
      {
        'title': '🍃 自然绿意',
        'prompt': '自然绿色渐变背景，带有叶子纹理，清新自然的计算器界面',
        'color': Colors.green,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.flash_on, color: Colors.amber.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '快速选择',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: quickPrompts.asMap().entries.map((entry) {
                final prompt = entry.value;
                final isLast = entry.key == quickPrompts.length - 1;
                
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _appBgPromptController.text = prompt['prompt'] as String;
                          _generateAppBackground();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(minHeight: 60),
                          decoration: BoxDecoration(
                            color: (prompt['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (prompt['color'] as Color).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: prompt['color'] as Color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      prompt['title'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      prompt['prompt'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCustomGenerationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '自定义生成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 快速示例
            Text(
              '快速示例',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '深蓝渐变 🌊💙',
                '科技感 ⚡🔋',
                '简约白色 ⚪🤍',
                '夜空星辰 🌌⭐',
                '温暖橙色 🍊🔥',
                '森林绿 🌿🍃',
                '紫色梦幻 💜🌈',
                '金属质感 ⚙️✨',
                '极简黑色 ⚫🖤',
                '粉色温馨 🌸💕',
              ].map((example) => 
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    String prompt = '';
                    if (example.contains('深蓝渐变')) prompt = '深蓝色渐变背景，从深蓝到浅蓝的平滑过渡，现代简约风格';
                    else if (example.contains('科技感')) prompt = '科技感背景，深色底配蓝色线条，未来主义设计风格';
                    else if (example.contains('简约白色')) prompt = '简约白色背景，纯净素雅，带有微妙纹理';
                    else if (example.contains('夜空星辰')) prompt = '夜空背景，深蓝色底配闪烁星点，浪漫神秘风格';
                    else if (example.contains('温暖橙色')) prompt = '温暖的橙色渐变背景，充满活力的暖色调';
                    else if (example.contains('森林绿')) prompt = '清新的绿色背景，自然森林风格，宁静舒适';
                    else if (example.contains('紫色梦幻')) prompt = '紫色梦幻背景，神秘优雅的紫色渐变效果';
                    else if (example.contains('金属质感')) prompt = '金属质感背景，银灰色金属纹理，工业现代风格';
                    else if (example.contains('极简黑色')) prompt = '极简黑色背景，纯黑或深灰，现代高端风格';
                    else if (example.contains('粉色温馨')) prompt = '温馨粉色背景，柔和的粉色调，甜美可爱风格';
                    _appBgPromptController.text = prompt;
                  },
                  backgroundColor: Colors.grey.shade100,
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            
            // 提示词输入
            TextField(
              controller: _appBgPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述你想要的APP背景图...\n例如：深蓝色渐变背景，带有金色几何图案',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGeneratingAppBg ? null : _generateAppBackground,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGeneratingAppBg
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '🎨 生成APP背景',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '生成成功',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 预览图片
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _base64ToBytes(_generatedAppBgUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _generatedAppBgUrl = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('重新生成'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyAppBackground,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('应用背景'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 选择按键（放在最上面）
          _buildMultiButtonBgSelectionCard(),
          const SizedBox(height: 20),
          
          // 自定义生成区域（包含快速示例）
          _buildButtonPatternGenerationCard(),
        ],
      ),
    );
  }

  Widget _buildMultiButtonBgSelectionCard() {
    final buttons = widget.currentConfig.layout.buttons;
    final layout = widget.currentConfig.layout;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.texture, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '选择按键',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 全选按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectAllBg,
                      onChanged: (value) {
                        setState(() {
                          _selectAllBg = value ?? false;
                          if (_selectAllBg) {
                            _selectedButtonBgIds = buttons.map((b) => b.id).toSet();
                          } else {
                            _selectedButtonBgIds.clear();
                          }
                        });
                      },
                    ),
                    const Text('全选'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 按照实际计算器布局显示按键
            _buildCalculatorLayoutGrid(buttons, layout),
            
            if (_selectedButtonBgIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '已选择 ${_selectedButtonBgIds.length} 个按键',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorLayoutGrid(List<CalculatorButton> buttons, CalculatorLayout layout) {
    // 按行分组按钮
    Map<int, List<CalculatorButton>> buttonsByRow = {};
    for (final button in buttons) {
      final row = button.gridPosition.row;
      buttonsByRow.putIfAbsent(row, () => []).add(button);
    }
    
    final sortedRows = buttonsByRow.keys.toList()..sort();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用宽度
        final availableWidth = constraints.maxWidth - 32; // 减去左右边距
        final buttonSize = (availableWidth - (layout.columns - 1) * 6) / layout.columns; // 减去间距
        final finalButtonSize = buttonSize.clamp(40.0, 70.0); // 限制按钮大小
        
        return Column(
          children: sortedRows.map((rowIndex) {
            final rowButtons = buttonsByRow[rowIndex] ?? [];
            rowButtons.sort((a, b) => a.gridPosition.column.compareTo(b.gridPosition.column));
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildRowButtons(rowButtons, layout.columns, finalButtonSize),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<Widget> _buildRowButtons(List<CalculatorButton> rowButtons, int totalColumns, double buttonSize) {
    List<Widget> rowWidgets = [];
    
    for (int col = 0; col < totalColumns; col++) {
      // 查找当前列的按钮
      CalculatorButton? button;
      for (final btn in rowButtons) {
        if (btn.gridPosition.column == col) {
          button = btn;
          break;
        }
      }
      
      if (button != null) {
        final isSelected = _selectedButtonBgIds.contains(button.id);
        final width = button.widthMultiplier > 1 ? 
            (buttonSize * button.widthMultiplier) + (6.0 * (button.widthMultiplier - 1)) : buttonSize;
        
        rowWidgets.add(
          Container(
            width: width,
            height: buttonSize,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedButtonBgIds.remove(button!.id);
                    } else {
                      _selectedButtonBgIds.add(button!.id);
                    }
                    _selectAllBg = _selectedButtonBgIds.length == widget.currentConfig.layout.buttons.length;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orange
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.orange,
                          size: 12,
                        ),
                      Flexible(
                        child: Text(
                          button.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey.shade700,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      if (isSelected)
                        Text(
                          '已选择',
                          style: TextStyle(
                            fontSize: 6,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        // 如果按钮宽度倍数大于1，跳过相应的列
        if (button.widthMultiplier > 1) {
          col += (button.widthMultiplier - 1).round();
        }
      } else {
        // 空位置
        rowWidgets.add(
          Container(
            width: buttonSize,
            height: buttonSize,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return rowWidgets;
  }

  Widget _buildButtonPatternGenerationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '自定义生成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 快速示例
            Text(
              '快速示例',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '几何图案',
                '自然纹理',
                '科技线条',
                '抽象艺术',
                '金属质感',
                '木纹材质',
                '水晶质感',
                '霓虹风格',
                '机械风格',
                '大理石纹',
                '渐变色彩',
                '极简风格',
              ].map((example) => 
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    String prompt = '';
                    if (example.contains('几何图案')) prompt = '简洁的几何图案背景，文字清晰可读，适合按键使用的现代设计';
                    else if (example.contains('自然纹理')) prompt = '自然纹理背景，叶子或水波纹理，清新自然风格，确保文字清晰';
                    else if (example.contains('科技线条')) prompt = '科技感线条图案，未来主义设计风格，文字突出显示';
                    else if (example.contains('抽象艺术')) prompt = '抽象艺术图案，色彩丰富的创意设计，文字对比度高';
                    else if (example.contains('金属质感')) prompt = '金属质感纹理，工业风格的按键背景，文字有光泽效果';
                    else if (example.contains('木纹材质')) prompt = '真实木纹纹理，自然温暖的木质感，文字清晰可见';
                    else if (example.contains('水晶质感')) prompt = '透明水晶质感，带有光泽和折射效果的现代设计，文字有反光效果';
                    else if (example.contains('霓虹风格')) prompt = '霓虹灯风格，充满活力的发光效果，适合动感按键，文字发光';
                    else if (example.contains('机械风格')) prompt = '机械工业风格，齿轮和螺丝纹理，精密感设计，文字有金属感';
                    else if (example.contains('大理石纹')) prompt = '优雅的大理石纹理，自然石材质感，高档奢华风格，文字有质感';
                    else if (example.contains('渐变色彩')) prompt = '平滑的渐变色彩，现代时尚的色彩过渡效果，文字有渐变效果';
                    else if (example.contains('极简风格')) prompt = '极简主义设计，纯净的色彩和线条，现代简约风格，文字简洁明了';
                    _buttonPatternPromptController.text = prompt;
                  },
                  backgroundColor: Colors.grey.shade100,
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            
            // 提示词输入
            TextField(
              controller: _buttonPatternPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述你想要的按键背景图案...\n例如：简洁的几何图案，适合计算器按键的现代设计\n\n🔧 注意：生成的图案会包含按键文字符号',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateButtonPatterns,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGeneratingButtonPattern
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '🎨 生成按键背景图',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateButtonPatterns() async {
    // 检查条件并给出提示
    if (_isGeneratingButtonPattern) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成中，请稍候...')),
      );
      return;
    }
    
    if (_buttonPatternPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入背景图案描述')),
      );
      return;
    }
    
    if (_selectedButtonBgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要生成背景图的按键')),
      );
      return;
    }

    setState(() {
      _isGeneratingButtonPattern = true;
    });

    try {
      await _generateSelectedButtonPatterns();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingButtonPattern = false;
        });
      }
    }
  }

  Future<void> _generateSelectedButtonPatterns() async {
    final buttons = widget.currentConfig.layout.buttons;
    final selectedButtons = buttons.where((b) => _selectedButtonBgIds.contains(b.id)).toList();
    final basePrompt = _buttonPatternPromptController.text.trim();
    
    try {
      // 🔧 使用异步任务服务提交按键背景图生成任务
      final taskIds = <String>[];
      
      for (final button in selectedButtons) {
        // 🔧 优化提示词，强调简洁性和文字可读性
        final prompt = '$basePrompt - 简洁的背景图案，为按键"${button.label}"设计，确保文字"${button.label}"清晰突出显示，背景图案简单不抢夺文字焦点';
        
        final taskId = await TaskService.submitButtonPatternTask(
          prompt: prompt,
          style: 'simple', // 🔧 改为simple风格，降低复杂度，让文字更突出
          size: '32x32',   // 🔧 降低分辨率从48x48到32x32，减少过度细节
        );
        
        taskIds.add(taskId);
        
        // 注册任务完成回调
        TaskService.registerTaskCallback(taskId, (task) {
          if (task.status == TaskStatus.completed && task.result != null) {
            _onButtonPatternGenerated(task, button);
          } else if (task.status == TaskStatus.failed) {
            _onButtonPatternGenerationFailed(task, button);
          }
        });
        
        // 添加短暂延迟避免任务提交过于频繁
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 显示提交成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 已提交 ${selectedButtons.length} 个按键背景图生成任务，正在后台处理...'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: '查看进度',
            textColor: Colors.white,
            onPressed: () {
              // 用户可以查看进度
            },
          ),
        ),
      );
      
    } catch (e) {
      // 任务提交失败，回退到同步方式
      print('异步任务提交失败，回退到同步方式: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 后台服务不可用，正在同步处理...')),
      );
      
      // 回退到同步生成
      for (int i = 0; i < selectedButtons.length; i++) {
        final button = selectedButtons[i];
        // 🔧 优化提示词，强调简洁性和文字可读性
        final prompt = '$basePrompt - 简洁的背景图案，为按键"${button.label}"设计，确保文字"${button.label}"清晰突出显示，背景图案简单不抢夺文字焦点';
        
        try {
          final result = await AIService.generatePattern(
            prompt: prompt,
            style: 'simple', // 🔧 改为simple风格，保持一致性
            size: '32x32',   // 🔧 降低分辨率，保持一致性
          );

          if (result['success'] == true && result['pattern_url'] != null) {
            _updateButtonPattern(button, result['pattern_url']);
          }
        } catch (syncError) {
          print('生成按键${button.label}背景图失败: $syncError');
        }
        
        // 添加短暂延迟避免API限制
        if (i < selectedButtons.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已为 ${selectedButtons.length} 个按键生成背景图案！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 🔧 新增：按键背景图生成完成回调
  void _onButtonPatternGenerated(GenerationTask task, CalculatorButton button) async {
    if (!mounted) return;
    
    try {
      // 解析生成结果
      final resultData = json.decode(task.result!);
      final patternUrl = resultData['pattern_url'];
      
      if (patternUrl != null) {
        _updateButtonPattern(button, patternUrl);
        
        // 🔧 强制刷新界面状态以确保按键背景图更新显示
        if (mounted) {
          setState(() {
            // 触发widget重建，确保按键背景图更新显示
          });
        }
        
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 按键"${button.label}"背景图生成完成并已自动应用！'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
    } catch (e) {
      print('解析按键背景图生成结果失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('😅 按键"${button.label}"背景图生成完成，但应用时遇到问题：$e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// 🔧 新增：按键背景图生成失败回调
  void _onButtonPatternGenerationFailed(GenerationTask task, CalculatorButton button) async {
    if (!mounted) return;
    
    final errorMsg = task.error ?? '未知错误';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('😓 按键"${button.label}"背景图生成失败：$errorMsg'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateButtonPattern(CalculatorButton button, String patternUrl) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    final updatedButton = CalculatorButton(
      id: button.id,
      label: button.label,
      action: button.action,
      gridPosition: button.gridPosition,
      type: button.type,
      customColor: button.customColor,
      isWide: button.isWide,
      widthMultiplier: button.widthMultiplier,
      heightMultiplier: button.heightMultiplier,
      gradientColors: button.gradientColors,
      backgroundImage: patternUrl, // 更新背景图
      fontSize: button.fontSize,
      borderRadius: button.borderRadius,
      elevation: button.elevation,
      width: button.width,
      height: button.height,
      backgroundColor: button.backgroundColor,
      textColor: button.textColor,
      borderColor: button.borderColor,
      borderWidth: button.borderWidth,
      shadowColor: button.shadowColor,
      shadowOffset: button.shadowOffset,
      shadowRadius: button.shadowRadius,
      opacity: button.opacity,
      rotation: button.rotation,
      scale: button.scale,
      backgroundPattern: button.backgroundPattern,
      patternColor: button.patternColor,
      patternOpacity: button.patternOpacity,
      animation: button.animation,
      animationDuration: button.animationDuration,
      customIcon: button.customIcon,
      iconSize: button.iconSize,
      iconColor: button.iconColor,
    );

    final updatedButtons = provider.config.layout.buttons.map((b) {
      return b.id == button.id ? updatedButton : b;
    }).toList();

    final updatedLayout = CalculatorLayout(
      name: provider.config.layout.name,
      rows: provider.config.layout.rows,
      columns: provider.config.layout.columns,
      buttons: updatedButtons,
      description: provider.config.layout.description,
      minButtonSize: provider.config.layout.minButtonSize,
      maxButtonSize: provider.config.layout.maxButtonSize,
      gridSpacing: provider.config.layout.gridSpacing,
    );

    final updatedConfig = CalculatorConfig(
      id: provider.config.id,
      name: provider.config.name,
      description: provider.config.description,
      theme: provider.config.theme,
      layout: updatedLayout,
      appBackground: provider.config.appBackground, // 🔧 保留原有的APP背景设置，不要清空
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    provider.applyConfig(updatedConfig);
  }

  Future<void> _generateAppBackground() async {
    if (_appBgPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入背景描述')),
      );
      return;
    }

    try {
      // 🔧 使用异步任务服务提交APP背景图生成任务
      final taskId = await TaskService.submitAppBackgroundTask(
        prompt: _appBgPromptController.text.trim(),
        style: 'modern',
        size: '1440x2560', // 🔧 提高分辨率从1080x1920到1440x2560，解决模糊问题
        quality: 'ultra', // 🔧 提升质量从high到ultra，获得更清晰的背景图
        theme: 'calculator',
      );
      
      // 显示提交成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎨 APP背景图生成任务已提交，正在后台处理...'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: '查看进度',
            textColor: Colors.white,
            onPressed: () {
              // 用户可以查看进度
            },
          ),
        ),
      );
      
      // 注册任务完成回调
      TaskService.registerTaskCallback(taskId, (task) {
        if (task.status == TaskStatus.completed && task.result != null) {
          _onAppBackgroundGenerated(task);
        } else if (task.status == TaskStatus.failed) {
          _onAppBackgroundGenerationFailed(task);
        }
      });
      
    } catch (e) {
      // 任务提交失败，回退到同步方式
      print('异步任务提交失败，回退到同步方式: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 后台服务不可用，正在同步处理...')),
      );
      
      // 回退到同步生成
      setState(() {
        _isGeneratingAppBg = true;
        _generatedAppBgUrl = null;
      });

      try {
        final result = await AIService.generateAppBackground(
          prompt: _appBgPromptController.text.trim(),
          style: 'modern',
          size: '1440x2560', // 🔧 提高分辨率，保持一致性
          quality: 'ultra',  // 🔧 提升质量，保持一致性
          theme: 'calculator',
        );

        if (result['success'] == true && result['background_url'] != null) {
          if (mounted) {
            setState(() {
              _generatedAppBgUrl = result['background_url'];
            });
            // 生成成功后直接应用背景
            _applyAppBackground();
          }
        } else {
          throw Exception(result['message'] ?? '生成失败');
        }
      } catch (syncError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('生成失败: $syncError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isGeneratingAppBg = false;
          });
        }
      }
    }
  }

  /// 🔧 新增：APP背景图生成完成回调
  void _onAppBackgroundGenerated(GenerationTask task) async {
    if (!mounted) return;
    
    try {
      // 解析生成结果
      final resultData = json.decode(task.result!);
      final backgroundUrl = resultData['background_url'];
      
      if (backgroundUrl != null) {
        // 🔧 强制刷新界面状态
        if (mounted) {
          setState(() {
            _generatedAppBgUrl = backgroundUrl;
          });
        }
        
        // 自动应用背景
        _applyAppBackground();
        
        // 🔧 强制刷新整个页面以确保更新生效
        if (mounted) {
          setState(() {
            // 触发完整的widget重建
          });
        }
        
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ APP背景图生成完成并已自动应用！'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '查看',
                textColor: Colors.white,
                onPressed: () {
                  // 滚动到预览区域
                },
              ),
            ),
          );
        }
      }
      
    } catch (e) {
      print('解析APP背景图生成结果失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('😅 生成完成，但应用时遇到问题：$e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// 🔧 新增：APP背景图生成失败回调
  void _onAppBackgroundGenerationFailed(GenerationTask task) async {
    if (!mounted) return;
    
    final errorMsg = task.error ?? '未知错误';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('😓 APP背景图生成失败：$errorMsg'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: () {
            _generateAppBackground();
          },
        ),
      ),
    );
  }

  void _applyAppBackground() {
    if (_generatedAppBgUrl == null) return;

    // 🔧 添加调试信息
    print('🔧 应用APP背景图，URL长度：${_generatedAppBgUrl!.length}');
    
    final newAppBackground = AppBackgroundConfig(
      backgroundImageUrl: _generatedAppBgUrl,
      backgroundType: 'image',
      backgroundOpacity: 1.0, // 🔧 背景图保持不透明，让背景图清晰可见
      buttonOpacity: _buttonOpacity,    // 🔧 按键透明度，让背景图透过来
      displayOpacity: _displayOpacity,  // 🔧 显示区域透明度，让背景图透过来
    );

    final updatedConfig = CalculatorConfig(
      id: widget.currentConfig.id,
      name: widget.currentConfig.name,
      description: widget.currentConfig.description,
      theme: widget.currentConfig.theme,
      layout: widget.currentConfig.layout,
      appBackground: newAppBackground,
      version: widget.currentConfig.version,
      createdAt: widget.currentConfig.createdAt,
      authorPrompt: widget.currentConfig.authorPrompt,
      thinkingProcess: widget.currentConfig.thinkingProcess,
      aiResponse: widget.currentConfig.aiResponse,
    );

    // 🔧 强制更新provider配置
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    provider.applyConfig(updatedConfig);
    
    // 🔧 同时更新父组件配置
    widget.onConfigUpdated(updatedConfig);
    
    // 🔧 添加调试信息
    print('🔧 APP背景图应用成功：按键透明度=${_buttonOpacity}，显示区域透明度=${_displayOpacity}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 背景已应用！按键透明度：${(_buttonOpacity * 100).round()}%，显示区域透明度：${(_displayOpacity * 100).round()}%'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 🔧 新增：独立的透明度控制卡片
  Widget _buildOpacityControlCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.opacity, color: Colors.purple.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '透明度控制',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 🔧 新增：快速预设按钮
                PopupMenuButton<double>(
                  icon: Icon(Icons.tune, color: Colors.purple.shade600),
                  tooltip: '快速预设',
                  onSelected: (value) {
                    setState(() {
                      _buttonOpacity = value;
                      _displayOpacity = value;
                    });
                    _applyOpacityChanges();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1.0,
                      child: Text('完全不透明 (100%)'),
                    ),
                    const PopupMenuItem(
                      value: 0.8,
                      child: Text('轻微透明 (80%)'),
                    ),
                    const PopupMenuItem(
                      value: 0.6,
                      child: Text('中等透明 (60%)'),
                    ),
                    const PopupMenuItem(
                      value: 0.4,
                      child: Text('高度透明 (40%)'),
                    ),
                    const PopupMenuItem(
                      value: 0.2,
                      child: Text('极度透明 (20%)'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 说明文字
            Text(
              '调节界面元素透明度，让APP背景图更好地显示',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // 显示区域透明度滑块
            Row(
              children: [
                Icon(Icons.monitor, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text('显示区域透明度', style: TextStyle(color: Colors.grey.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_displayOpacity * 100).round()}%', 
                    style: TextStyle(
                      color: Colors.purple.shade700, 
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _displayOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: Colors.purple.shade600,
              inactiveColor: Colors.purple.shade100,
              onChanged: (value) {
                setState(() {
                  _displayOpacity = value;
                });
              },
              onChangeEnd: (value) {
                _applyOpacityChanges();
              },
            ),
            const SizedBox(height: 16),
            
            // 按键透明度滑块
            Row(
              children: [
                Icon(Icons.keyboard, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text('按键透明度', style: TextStyle(color: Colors.grey.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_buttonOpacity * 100).round()}%', 
                    style: TextStyle(
                      color: Colors.purple.shade700, 
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _buttonOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: Colors.purple.shade600,
              inactiveColor: Colors.purple.shade100,
              onChanged: (value) {
                setState(() {
                  _buttonOpacity = value;
                });
              },
              onChangeEnd: (value) {
                _applyOpacityChanges();
              },
            ),
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _buttonOpacity = 1.0;
                        _displayOpacity = 1.0;
                      });
                      _applyOpacityChanges();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重置'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyOpacityChanges,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('立即应用'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 新增：应用透明度变化
  void _applyOpacityChanges() {
    // 获取当前provider和配置
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    final currentAppBackground = provider.config.appBackground;
    
    // 🔧 创建或更新APP背景配置，即使没有背景图也应该应用透明度
    final updatedAppBackground = AppBackgroundConfig(
      backgroundImageUrl: currentAppBackground?.backgroundImageUrl, // 可以为null
      backgroundType: currentAppBackground?.backgroundType ?? 'color',
      backgroundColor: currentAppBackground?.backgroundColor,
      backgroundGradient: currentAppBackground?.backgroundGradient,
      backgroundOpacity: currentAppBackground?.backgroundOpacity ?? 1.0,
      buttonOpacity: _buttonOpacity,      // 🔧 总是应用按键透明度
      displayOpacity: _displayOpacity,    // 🔧 总是应用显示区域透明度
    );

    final updatedConfig = CalculatorConfig(
      id: provider.config.id,
      name: provider.config.name,
      description: provider.config.description,
      theme: provider.config.theme,
      layout: provider.config.layout,
      appBackground: updatedAppBackground, // 🔧 总是更新APP背景配置
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    // 🔧 强制刷新provider配置
    provider.applyConfig(updatedConfig);
    widget.onConfigUpdated(updatedConfig);
    
    // 🔧 添加调试信息
    print('🔧 透明度应用成功：按键透明度=${_buttonOpacity}，显示区域透明度=${_displayOpacity}');
    
    // 显示应用成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 透明度已应用！按键: ${(_buttonOpacity * 100).round()}%, 显示区域: ${(_displayOpacity * 100).round()}%'),
        backgroundColor: Colors.purple.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('恢复默认设置'),
          ],
        ),
        content: const Text('要恢复默认设置吗？\n\n这将清除所有按键背景图和APP背景图，恢复到原始样式。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetToDefault();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('恢复默认', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefault() async {
    try {
      // 清除所有按键背景图
      final buttons = widget.currentConfig.layout.buttons;
      final updatedButtons = buttons.map((button) {
        return CalculatorButton(
          id: button.id,
          label: button.label,
          action: button.action,
          gridPosition: button.gridPosition,
          type: button.type,
          customColor: button.customColor,
          isWide: button.isWide,
          widthMultiplier: button.widthMultiplier,
          heightMultiplier: button.heightMultiplier,
          gradientColors: button.gradientColors,
          backgroundImage: null, // 清除背景图
          fontSize: button.fontSize,
          borderRadius: button.borderRadius,
          elevation: button.elevation,
          width: button.width,
          height: button.height,
          backgroundColor: button.backgroundColor,
          textColor: button.textColor,
          borderColor: button.borderColor,
          borderWidth: button.borderWidth,
          shadowColor: button.shadowColor,
          shadowOffset: button.shadowOffset,
          shadowRadius: button.shadowRadius,
          opacity: button.opacity,
          rotation: button.rotation,
          scale: button.scale,
          backgroundPattern: button.backgroundPattern,
          patternColor: button.patternColor,
          patternOpacity: button.patternOpacity,
          animation: button.animation,
          animationDuration: button.animationDuration,
          customIcon: button.customIcon,
          iconSize: button.iconSize,
          iconColor: button.iconColor,
        );
      }).toList();

      final updatedLayout = CalculatorLayout(
        name: widget.currentConfig.layout.name,
        rows: widget.currentConfig.layout.rows,
        columns: widget.currentConfig.layout.columns,
        buttons: updatedButtons,
        description: widget.currentConfig.layout.description,
        minButtonSize: widget.currentConfig.layout.minButtonSize,
        maxButtonSize: widget.currentConfig.layout.maxButtonSize,
        gridSpacing: widget.currentConfig.layout.gridSpacing,
      );

      // 清除APP背景图
      final updatedConfig = CalculatorConfig(
        id: widget.currentConfig.id,
        name: widget.currentConfig.name,
        description: widget.currentConfig.description,
        theme: widget.currentConfig.theme,
        layout: updatedLayout,
        appBackground: null, // 清除APP背景
        version: widget.currentConfig.version,
        createdAt: widget.currentConfig.createdAt,
        authorPrompt: widget.currentConfig.authorPrompt,
        thinkingProcess: widget.currentConfig.thinkingProcess,
        aiResponse: widget.currentConfig.aiResponse,
      );

      widget.onConfigUpdated(updatedConfig);
      
      // 清除本地状态
      setState(() {
        _selectedButtonBgIds.clear();
        _selectAllBg = false;
        _generatedAppBgUrl = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已恢复默认设置！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('恢复失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Uint8List _base64ToBytes(String base64String) {
    if (base64String.startsWith('data:')) {
      base64String = base64String.split(',')[1];
    }
    return base64Decode(base64String);
  }
} 