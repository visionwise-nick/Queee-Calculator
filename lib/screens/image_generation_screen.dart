import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../services/ai_service.dart';
import '../services/config_service.dart'; // 🔧 新增：导入配置服务
import '../providers/calculator_provider.dart';
import '../widgets/ai_generation_progress_dialog.dart'; // 🔧 新增：导入进度弹窗

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
  double _appBgProgress = 0.0;
  String _appBgStatusMessage = '';
  double _buttonBgProgress = 0.0;
  String _buttonBgStatusMessage = '';

  // 🔧 修正透明度控制变量概念
  double _buttonOpacity = 0.7;     // 按键透明度 - 让背景图可以透过来
  double _displayOpacity = 0.7;    // 显示区域透明度 - 让背景图可以透过来

  // 按键背景图相关状态
  Set<String> _selectedButtonBgIds = {}; // 多选按键ID集合（按键背景图）
  bool _selectAllBg = false;
  bool _isGeneratingButtonPattern = false;
  final TextEditingController _buttonPatternPromptController = TextEditingController();
  
  // 🔧 新增：显示区背景相关状态
  bool _isGeneratingDisplayBg = false;
  String? _generatedDisplayBgUrl;
  double _displayBgProgress = 0.0;
  String _displayBgStatusMessage = '';
  final TextEditingController _displayBgPromptController = TextEditingController();
  
  // 🔧 新增：进度弹窗控制器
  final AIGenerationProgressController _progressController = AIGenerationProgressController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 🔧 改为3个tab
    
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
    _displayBgPromptController.dispose(); // 🔧 新增：清理显示区背景控制器
    _progressController.dispose(); // 🔧 新增：清理进度控制器
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
            Tab(
              icon: Icon(Icons.monitor),
              text: '显示区',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildButtonBackgroundTab(), // 按键背景tab放到第一个
              _buildAppBackgroundTab(),    // APP背景tab放到第二个
              _buildDisplayBackgroundTab(), // 🔧 新增：显示区背景tab放到第三个
            ],
          ),
          
          // 🔧 进度弹窗
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              if (!_progressController.isVisible) {
                return const SizedBox.shrink();
              }
              
              return AIGenerationProgressDialog(
                title: _progressController.title,
                description: _progressController.description,
                progress: _progressController.progress,
                statusMessage: _progressController.statusMessage,
                taskType: _progressController.taskType,
                allowCancel: _progressController.allowCancel,
                onCancel: _progressController.onCancel,
              );
            },
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
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _appBgProgress > 0 ? _appBgProgress : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _appBgStatusMessage.isNotEmpty 
                                ? _appBgStatusMessage 
                                : '正在生成...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          if (_appBgProgress > 0)
                            Text(
                              '${(_appBgProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                        ],
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

  // 🔧 新增：显示区背景标签页
  Widget _buildDisplayBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自定义生成区域
          _buildDisplayBackgroundGenerationCard(),
          const SizedBox(height: 20),
          
          // 快速选择区域
          _buildDisplayBackgroundQuickSelectionCard(),
          const SizedBox(height: 20),
          
          // 预览和应用区域
          if (_generatedDisplayBgUrl != null) _buildDisplayBackgroundPreviewCard(),
        ],
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
                  child: Stack(
                    children: [
                      Column(
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
                      // 🔧 新增：单个按键恢复默认背景按钮
                      if (button.backgroundImage != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _resetSingleButtonBackground(button!),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.restore,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
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
                const Expanded(
                  child: Text(
                    '自定义生成',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 🔧 新增：历史记录按钮
                IconButton(
                  icon: Icon(Icons.history, color: Colors.grey.shade600),
                  onPressed: _showButtonPatternHistory,
                  tooltip: '历史记录',
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
                '纸质纹理',
                '木纹质感',
                '皮革纹理',
                '金属拉丝',
                '磨砂玻璃',
                '布料织纹',
                '石材质感',
                '极简渐变',
                '水晶效果',
                '霓虹光效',
                '炫彩光谱',
                '梦幻色彩',
              ].map((example) => 
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    String prompt = '';
                    if (example.contains('纸质纹理')) prompt = '细腻的纸质纹理，米白色背景，适合小按键显示';
                    else if (example.contains('木纹质感')) prompt = '自然木纹纹理，温暖棕色调，细腻木质感';
                    else if (example.contains('皮革纹理')) prompt = '高级皮革纹理，深棕色，精细皮质感';
                    else if (example.contains('金属拉丝')) prompt = '金属拉丝纹理，银灰色，工业质感';
                    else if (example.contains('磨砂玻璃')) prompt = '磨砂玻璃质感，半透明效果，现代简约';
                    else if (example.contains('布料织纹')) prompt = '细腻布料织纹，柔和质感，舒适视觉';
                    else if (example.contains('石材质感')) prompt = '天然石材纹理，灰色调，自然质感';
                    else if (example.contains('极简渐变')) prompt = '极简双色渐变，柔和过渡，现代设计';
                    else if (example.contains('水晶效果')) prompt = '水晶表面效果，透明质感，精致美观';
                    else if (example.contains('霓虹光效')) prompt = '霓虹光效，鲜艳色彩，现代电子风格';
                    else if (example.contains('炫彩光谱')) prompt = '炫彩光谱效果，彩虹色彩，视觉冲击';
                    else if (example.contains('梦幻色彩')) prompt = '梦幻色彩组合，柔和渐变，温暖美感';
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
                hintText: '描述你想要的按键背景视觉效果...\n例如：全息彩虹渐变，丰富色彩变化\n\n🎨 新设计：丰富色彩和现代视觉效果，但保持符号简单，专注纯粹的色彩美感',
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
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _buttonBgProgress > 0 ? _buttonBgProgress : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _buttonBgStatusMessage.isNotEmpty 
                                ? _buttonBgStatusMessage 
                                : '正在生成...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_buttonBgProgress > 0)
                            Text(
                              '${(_buttonBgProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                        ],
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

    // 🔧 显示强制性进度弹窗
    _progressController.show(
      title: '🎨 正在生成按键背景图',
      description: '正在为您选择的按键生成精美的背景图案...',
      taskType: 'generate-pattern',
      allowCancel: false,
    );

    setState(() {
      _isGeneratingButtonPattern = true;
    });

    try {
      await _generateSelectedButtonPatterns();
      
      // 🔧 保存到历史记录
      await ConfigService.saveButtonPatternHistory(
        _buttonPatternPromptController.text.trim(),
      );
    } catch (e) {
      // 隐藏进度弹窗
      _progressController.hide();
      
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
          _buttonBgProgress = 0.0;
          _buttonBgStatusMessage = '';
        });
      }
    }
  }

  Future<void> _generateSelectedButtonPatterns() async {
    final buttons = widget.currentConfig.layout.buttons;
    final selectedButtons = buttons.where((b) => _selectedButtonBgIds.contains(b.id)).toList();
    final basePrompt = _buttonPatternPromptController.text.trim();
    
    if (selectedButtons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要生成背景图的按键')),
      );
      return;
    }
    
    print('🎨 开始生成 ${selectedButtons.length} 个按键背景图...');
    
    // 显示开始消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎨 正在为 ${selectedButtons.length} 个按键生成背景图案...'),
        backgroundColor: Colors.blue,
      ),
    );
    
    int successCount = 0;
    int failureCount = 0;
    
    for (int i = 0; i < selectedButtons.length; i++) {
      final button = selectedButtons[i];
      final prompt = basePrompt; // 🔧 直接使用用户的原始提示词，不添加限制性描述
      
      try {
        print('🔧 生成按键${button.label}的背景图...');
        print('   用户提示词: $prompt');
        
        final result = await AIService.generatePattern(
          prompt: prompt,
          style: 'vibrant',
          size: '128x128',
          onProgress: (progress) {
            // 计算总体进度
            final totalProgress = (i + progress) / selectedButtons.length;
            
            // 更新进度弹窗
            _progressController.updateProgress(
              totalProgress, 
              '正在生成按键 "${button.label}" 背景图... (${i + 1}/${selectedButtons.length})'
            );
            
            if (mounted) {
              setState(() {
                _buttonBgProgress = progress;
              });
            }
            print('按键${button.label}生成进度: ${(progress * 100).toInt()}%');
          },
          onStatusUpdate: (status) {
            // 更新进度弹窗状态
            _progressController.updateProgress(
              _progressController.progress, 
              '按键 "${button.label}": $status'
            );
            
            if (mounted) {
              setState(() {
                _buttonBgStatusMessage = '正在生成按键${button.label}：$status';
              });
            }
            print('按键${button.label}生成状态: $status');
          },
        );

        print('🔧 按键${button.label}生成结果: ${result.keys.toList()}');
        
        if (result['success'] == true && result['pattern_url'] != null) {
          _updateButtonPattern(button, result['pattern_url']);
          successCount++;
          print('✅ 按键${button.label}背景图生成成功！');
        } else {
          failureCount++;
          print('❌ 按键${button.label}背景图生成失败: ${result['message'] ?? '未知错误'}');
        }
      } catch (e) {
        failureCount++;
        print('❌ 生成按键${button.label}背景图失败: $e');
      }
      
      // 添加短暂延迟避免API限制
      if (i < selectedButtons.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // 隐藏进度弹窗
    _progressController.hide();
    
    // 显示最终结果
    if (mounted) {
      final message = successCount > 0 
          ? '✅ 成功生成 $successCount 个按键背景图${failureCount > 0 ? '，失败 $failureCount 个' : ''}！'
          : '❌ 所有按键背景图生成失败';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

    // 🔧 显示强制性进度弹窗
    _progressController.show(
      title: '🎨 正在生成APP背景图',
      description: '正在为您的计算器生成精美的背景图...',
      taskType: 'generate-app-background',
      allowCancel: false,
    );

    setState(() {
      _isGeneratingAppBg = true;
      _generatedAppBgUrl = null;
    });

    try {
      print('🎨 开始生成APP背景图...');
      print('   提示词: ${_appBgPromptController.text.trim()}');
      
      final result = await AIService.generateAppBackground(
        prompt: _appBgPromptController.text.trim(),
        style: 'modern',
        size: '1440x2560',
        quality: 'ultra',
        theme: 'calculator',
        onProgress: (progress) {
          // 更新进度弹窗
          String statusMessage = '正在生成背景图...';
          if (progress < 0.3) {
            statusMessage = '正在分析您的创意...';
          } else if (progress < 0.6) {
            statusMessage = '正在设计背景风格...';
          } else if (progress < 0.9) {
            statusMessage = '正在渲染高质量图像...';
          } else {
            statusMessage = '即将完成...';
          }
          
          _progressController.updateProgress(progress, statusMessage);
          
          if (mounted) {
            setState(() {
              _appBgProgress = progress;
            });
          }
          print('APP背景图生成进度: ${(progress * 100).toInt()}%');
        },
        onStatusUpdate: (status) {
          // 更新状态消息
          _progressController.updateProgress(_progressController.progress, status);
          
          if (mounted) {
            setState(() {
              _appBgStatusMessage = status;
            });
          }
          print('APP背景图生成状态: $status');
        },
      );

      // 隐藏进度弹窗
      _progressController.hide();

      print('🔧 APP背景图生成结果: ${result.keys.toList()}');
      
      if (result['success'] == true && result['background_url'] != null) {
        if (mounted) {
          setState(() {
            _generatedAppBgUrl = result['background_url'];
          });
          
          // 🔧 保存到历史记录
          await ConfigService.saveAppBackgroundHistory(
            _appBgPromptController.text.trim(),
            result['background_url'],
          );
          
          // 生成成功后直接应用背景
          _applyAppBackground();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ APP背景图生成完成！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? '生成失败');
      }
    } catch (e) {
      // 隐藏进度弹窗
      _progressController.hide();
      
      print('❌ APP背景图生成失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ APP背景图生成失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAppBg = false;
          _appBgProgress = 0.0;
          _appBgStatusMessage = '';
        });
      }
    }
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
    
    // 🔧 保存配置到本地存储
    _saveConfigToStorage(updatedConfig);
    
    // 🔧 强制重建UI
    if (mounted) {
      setState(() {
        // 触发UI重建
      });
    }
    
    // 🔧 添加调试信息
    print('🔧 APP背景图应用成功：按键透明度=${_buttonOpacity}，显示区域透明度=${_displayOpacity}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 背景已应用！按键透明度：${(_buttonOpacity * 100).round()}%，显示区域透明度：${(_displayOpacity * 100).round()}%'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 🔧 新增：保存配置到本地存储
  void _saveConfigToStorage(CalculatorConfig config) async {
    try {
      await ConfigService.saveCurrentConfig(config);
      print('✅ 配置已保存到本地存储');
    } catch (e) {
      print('❌ 保存配置失败: $e');
    }
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

  // 🔧 新增：显示APP背景历史记录
  void _showAppBackgroundHistory() async {
    final historyList = await ConfigService.loadAppBackgroundHistory();
    
    if (historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无历史记录')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('APP背景历史记录'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              final prompt = item['prompt'] as String;
              final timestamp = item['timestamp'] as int;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.wallpaper, color: Colors.blue),
                  title: Text(
                    prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _appBgPromptController.text = prompt;
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await ConfigService.deleteAppBackgroundHistoryItem(item['id']);
                      Navigator.of(context).pop();
                      _showAppBackgroundHistory();
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              await ConfigService.clearAppBackgroundHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('历史记录已清空')),
              );
            },
            child: const Text('清空全部', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔧 新增：显示按键背景图案历史记录
  void _showButtonPatternHistory() async {
    final historyList = await ConfigService.loadButtonPatternHistory();
    
    if (historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无历史记录')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.purple),
            SizedBox(width: 8),
            Text('按键背景历史记录'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              final prompt = item['prompt'] as String;
              final timestamp = item['timestamp'] as int;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.texture, color: Colors.purple),
                  title: Text(
                    prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _buttonPatternPromptController.text = prompt;
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await ConfigService.deleteButtonPatternHistoryItem(item['id']);
                      Navigator.of(context).pop();
                      _showButtonPatternHistory();
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              await ConfigService.clearButtonPatternHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('历史记录已清空')),
              );
            },
            child: const Text('清空全部', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🔧 新增：单个按键恢复默认背景
  void _resetSingleButtonBackground(CalculatorButton button) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('恢复默认背景'),
          ],
        ),
        content: Text('要恢复按键 "${button.label}" 的默认背景吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applySingleButtonReset(button);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('恢复', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔧 新增：应用单个按键恢复默认背景
  void _applySingleButtonReset(CalculatorButton button) {
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
      backgroundImage: null, // 🔧 清除背景图，恢复默认
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
      appBackground: provider.config.appBackground,
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    provider.applyConfig(updatedConfig);
    widget.onConfigUpdated(updatedConfig);
    
         ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text('✅ 按键 "${button.label}" 已恢复默认背景'),
         backgroundColor: Colors.green,
       ),
     );
   }

   // 🔧 新增：显示区背景生成相关方法
   
   /// 构建显示区背景生成卡片
   Widget _buildDisplayBackgroundGenerationCard() {
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
                   child: Icon(Icons.monitor, color: Colors.green.shade700),
                 ),
                 const SizedBox(width: 12),
                 const Expanded(
                   child: Text(
                     '自定义显示区背景',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 // 🔧 历史记录按钮
                 IconButton(
                   icon: Icon(Icons.history, color: Colors.grey.shade600),
                   onPressed: _showDisplayBackgroundHistory,
                   tooltip: '历史记录',
                 ),
               ],
             ),
             const SizedBox(height: 16),
             
             // 提示词输入
             TextField(
               controller: _displayBgPromptController,
               maxLines: 3,
               decoration: InputDecoration(
                 hintText: '描述你想要的显示区背景风格...\n例如：数字矩阵背景，科技感绿色字符流\n\n🎯 专为计算器显示区设计，突出数字和计算结果的可读性',
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
                 onPressed: _isGeneratingDisplayBg ? null : _generateDisplayBackground,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.green.shade600,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 child: _isGeneratingDisplayBg
                     ? Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           SizedBox(
                             height: 20,
                             width: 20,
                             child: CircularProgressIndicator(
                               strokeWidth: 2,
                               value: _displayBgProgress > 0 ? _displayBgProgress : null,
                               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             _displayBgStatusMessage.isNotEmpty 
                                 ? _displayBgStatusMessage 
                                 : '正在生成...',
                             style: const TextStyle(
                               fontSize: 12,
                               color: Colors.white,
                             ),
                           ),
                           if (_displayBgProgress > 0)
                             Text(
                               '${(_displayBgProgress * 100).toInt()}%',
                               style: const TextStyle(
                                 fontSize: 10,
                                 color: Colors.white70,
                               ),
                             ),
                         ],
                       )
                     : const Text(
                         '🎨 生成显示区背景',
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

   /// 构建显示区背景快速选择卡片
   Widget _buildDisplayBackgroundQuickSelectionCard() {
     final quickPrompts = [
       {
         'title': '📊 数字矩阵',
         'prompt': '数字矩阵背景，绿色字符流，科技感十足，适合计算器显示',
         'color': Colors.green,
       },
       {
         'title': '🌌 星空数字',
         'prompt': '深蓝色星空背景，闪烁的数字星点，神秘而优雅',
         'color': Colors.blue,
       },
       {
         'title': '⚡ 电路板',
         'prompt': '电路板纹理背景，蓝绿色电路线条，现代科技风格',
         'color': Colors.cyan,
       },
       {
         'title': '🔥 能量波纹',
         'prompt': '橙色能量波纹背景，动感光效，充满活力',
         'color': Colors.orange,
       },
       {
         'title': '❄️ 极简冰霜',
         'prompt': '白色极简背景，微妙的冰霜纹理，清爽简洁',
         'color': Colors.grey,
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
                     color: Colors.purple.shade100,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Icon(Icons.auto_awesome, color: Colors.purple.shade700),
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
             const SizedBox(height: 16),
             
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
                             _displayBgPromptController.text = prompt['prompt'] as String;
                             _generateDisplayBackground();
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
                               ],
                             ),
                           ),
                         ),
                       ),
                       if (!isLast) const SizedBox(height: 12),
                     ],
                   );
                 }).toList(),
               ),
             ),
           ],
         ),
       ),
     );
   }

   /// 构建显示区背景预览卡片
   Widget _buildDisplayBackgroundPreviewCard() {
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
               height: 150,
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey.shade300),
               ),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: Image.memory(
                   _base64ToBytes(_generatedDisplayBgUrl!),
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
                         _generatedDisplayBgUrl = null;
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
                     onPressed: _applyDisplayBackground,
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

   /// 生成显示区背景
   Future<void> _generateDisplayBackground() async {
     if (_displayBgPromptController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('请输入背景描述')),
       );
       return;
     }

     // 显示强制性进度弹窗
     _progressController.show(
       title: '🎨 正在生成显示区背景图',
       description: '正在为您的计算器显示区生成精美的背景图...',
       taskType: 'generate-display-background',
       allowCancel: false,
     );

     setState(() {
       _isGeneratingDisplayBg = true;
       _generatedDisplayBgUrl = null;
     });

     try {
       print('🎨 开始生成显示区背景图...');
       print('   提示词: ${_displayBgPromptController.text.trim()}');
       
       final result = await AIService.generateDisplayBackground(
         prompt: _displayBgPromptController.text.trim(),
         style: 'clean',
         size: '800x400',
         quality: 'high',
         theme: 'display',
         onProgress: (progress) {
           String statusMessage = '正在生成显示区背景...';
           if (progress < 0.3) {
             statusMessage = '正在分析显示区需求...';
           } else if (progress < 0.6) {
             statusMessage = '正在设计背景样式...';
           } else if (progress < 0.9) {
             statusMessage = '正在优化显示效果...';
           } else {
             statusMessage = '即将完成...';
           }
           
           _progressController.updateProgress(progress, statusMessage);
           
           if (mounted) {
             setState(() {
               _displayBgProgress = progress;
             });
           }
           print('显示区背景图生成进度: ${(progress * 100).toInt()}%');
         },
         onStatusUpdate: (status) {
           _progressController.updateProgress(_progressController.progress, status);
           
           if (mounted) {
             setState(() {
               _displayBgStatusMessage = status;
             });
           }
           print('显示区背景图生成状态: $status');
         },
       );

       // 隐藏进度弹窗
       _progressController.hide();

       print('🔧 显示区背景图生成结果: ${result.keys.toList()}');
       
       if (result['success'] == true && result['display_background_url'] != null) {
         if (mounted) {
           setState(() {
             _generatedDisplayBgUrl = result['display_background_url'];
           });
           
           // 保存到历史记录
           await ConfigService.saveDisplayBackgroundHistory(
             _displayBgPromptController.text.trim(),
             result['display_background_url'],
           );
           
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('✅ 显示区背景图生成完成！'),
               backgroundColor: Colors.green,
             ),
           );
         }
       } else {
         throw Exception(result['message'] ?? '生成失败');
       }
     } catch (e) {
       // 隐藏进度弹窗
       _progressController.hide();
       
       print('❌ 显示区背景图生成失败: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('❌ 显示区背景图生成失败: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     } finally {
       if (mounted) {
         setState(() {
           _isGeneratingDisplayBg = false;
           _displayBgProgress = 0.0;
           _displayBgStatusMessage = '';
         });
       }
     }
   }

   /// 应用显示区背景
   void _applyDisplayBackground() {
     if (_generatedDisplayBgUrl == null) return;

     print('🔧 应用显示区背景图，URL长度：${_generatedDisplayBgUrl!.length}');
     
     // 更新主题配置中的显示区背景图
     final updatedTheme = CalculatorTheme(
       name: widget.currentConfig.theme.name,
       backgroundColor: widget.currentConfig.theme.backgroundColor,
       backgroundGradient: widget.currentConfig.theme.backgroundGradient,
       backgroundImage: widget.currentConfig.theme.backgroundImage,
       displayBackgroundColor: widget.currentConfig.theme.displayBackgroundColor,
       displayBackgroundGradient: widget.currentConfig.theme.displayBackgroundGradient,
       displayBackgroundImage: _generatedDisplayBgUrl, // 🔧 设置显示区背景图
       displayTextColor: widget.currentConfig.theme.displayTextColor,
       displayWidth: widget.currentConfig.theme.displayWidth,
       displayHeight: widget.currentConfig.theme.displayHeight,
       displayHeightRatio: widget.currentConfig.theme.displayHeightRatio,
       displayBorderRadius: widget.currentConfig.theme.displayBorderRadius,
       primaryButtonColor: widget.currentConfig.theme.primaryButtonColor,
       primaryButtonGradient: widget.currentConfig.theme.primaryButtonGradient,
       primaryButtonTextColor: widget.currentConfig.theme.primaryButtonTextColor,
       secondaryButtonColor: widget.currentConfig.theme.secondaryButtonColor,
       secondaryButtonGradient: widget.currentConfig.theme.secondaryButtonGradient,
       secondaryButtonTextColor: widget.currentConfig.theme.secondaryButtonTextColor,
       operatorButtonColor: widget.currentConfig.theme.operatorButtonColor,
       operatorButtonGradient: widget.currentConfig.theme.operatorButtonGradient,
       operatorButtonTextColor: widget.currentConfig.theme.operatorButtonTextColor,
       fontSize: widget.currentConfig.theme.fontSize,
       buttonBorderRadius: widget.currentConfig.theme.buttonBorderRadius,
       hasGlowEffect: widget.currentConfig.theme.hasGlowEffect,
       shadowColor: widget.currentConfig.theme.shadowColor,
       buttonElevation: widget.currentConfig.theme.buttonElevation,
       buttonShadowColors: widget.currentConfig.theme.buttonShadowColors,
       buttonSpacing: widget.currentConfig.theme.buttonSpacing,
       adaptiveLayout: widget.currentConfig.theme.adaptiveLayout,
     );

     final updatedConfig = CalculatorConfig(
       id: widget.currentConfig.id,
       name: widget.currentConfig.name,
       description: widget.currentConfig.description,
       theme: updatedTheme,
       layout: widget.currentConfig.layout,
       appBackground: widget.currentConfig.appBackground,
       version: widget.currentConfig.version,
       createdAt: widget.currentConfig.createdAt,
       authorPrompt: widget.currentConfig.authorPrompt,
       thinkingProcess: widget.currentConfig.thinkingProcess,
       aiResponse: widget.currentConfig.aiResponse,
     );

     // 强制更新provider配置
     final provider = Provider.of<CalculatorProvider>(context, listen: false);
     provider.applyConfig(updatedConfig);
     
     // 同时更新父组件配置
     widget.onConfigUpdated(updatedConfig);
     
     // 保存配置到本地存储
     _saveConfigToStorage(updatedConfig);
     
     // 强制重建UI
     if (mounted) {
       setState(() {
         // 触发UI重建
       });
     }
     
     print('🔧 显示区背景图应用成功');
     
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
         content: Text('✅ 显示区背景已应用！'),
         backgroundColor: Colors.green,
       ),
     );
   }

   /// 显示显示区背景历史记录
   void _showDisplayBackgroundHistory() async {
     final historyList = await ConfigService.loadDisplayBackgroundHistory();
     
     if (historyList.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('暂无历史记录')),
       );
       return;
     }
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         title: const Row(
           children: [
             Icon(Icons.history, color: Colors.green),
             SizedBox(width: 8),
             Text('显示区背景历史记录'),
           ],
         ),
         content: SizedBox(
           width: double.maxFinite,
           height: 400,
           child: ListView.builder(
             itemCount: historyList.length,
             itemBuilder: (context, index) {
               final item = historyList[index];
               final prompt = item['prompt'] as String;
               final timestamp = item['timestamp'] as int;
               final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
               
               return Card(
                 margin: const EdgeInsets.symmetric(vertical: 4),
                 child: ListTile(
                   leading: const Icon(Icons.monitor, color: Colors.green),
                   title: Text(
                     prompt,
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                   subtitle: Text(
                     '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                     style: TextStyle(color: Colors.grey.shade600),
                   ),
                   onTap: () {
                     Navigator.of(context).pop();
                     _displayBgPromptController.text = prompt;
                   },
                   trailing: IconButton(
                     icon: const Icon(Icons.delete, color: Colors.red),
                     onPressed: () async {
                       await ConfigService.deleteDisplayBackgroundHistoryItem(item['id']);
                       Navigator.of(context).pop();
                       _showDisplayBackgroundHistory();
                     },
                   ),
                 ),
               );
             },
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('关闭'),
           ),
           TextButton(
             onPressed: () async {
               await ConfigService.clearDisplayBackgroundHistory();
               Navigator.of(context).pop();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('历史记录已清空')),
               );
             },
             child: const Text('清空全部', style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
     );
   }
 }  