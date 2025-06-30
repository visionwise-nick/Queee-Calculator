import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../services/ai_service.dart';
import '../providers/calculator_provider.dart';
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

  Set<String> _selectedButtonIds = {}; // 多选按键ID集合（按键文字）
  bool _selectAll = false;
  
  // 按键背景图相关状态
  Set<String> _selectedButtonBgIds = {}; // 多选按键ID集合（按键背景图）
  bool _selectAllBg = false;
  bool _isGeneratingButtonPattern = false;
  final TextEditingController _buttonPatternPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(
              icon: Icon(Icons.text_fields),
              text: '按键文字',
            ),
            Tab(
              icon: Icon(Icons.wallpaper),
              text: 'APP背景',
            ),
            Tab(
              icon: Icon(Icons.texture),
              text: '按键背景',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildButtonTextTab(),
          _buildAppBackgroundTab(),
          _buildButtonBackgroundTab(),
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
          // 自定义生成区域（移到上面）
          _buildCustomGenerationCard(),
          const SizedBox(height: 20),
          
          // 快速选择区域（移到下面）
          _buildQuickSelectionCard(),
          const SizedBox(height: 20),
          
          // 预览和应用区域
          if (_generatedAppBgUrl != null) _buildPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildButtonTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 多选按键选择
          _buildMultiButtonSelectionCard(),
          const SizedBox(height: 20),
          
          // 按键文字生成区域
          _buildButtonTextGenerationCard(),
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

  Widget _buildMultiButtonSelectionCard() {
    final buttons = widget.currentConfig.layout.buttons;
    
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
                  child: Icon(Icons.touch_app, color: Colors.purple.shade700),
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
                      value: _selectAll,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = value ?? false;
                          if (_selectAll) {
                            _selectedButtonIds = buttons.map((b) => b.id).toSet();
                          } else {
                            _selectedButtonIds.clear();
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
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                final button = buttons[index];
                final isSelected = _selectedButtonIds.contains(button.id);
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedButtonIds.remove(button.id);
                        } else {
                          _selectedButtonIds.add(button.id);
                        }
                        _selectAll = _selectedButtonIds.length == buttons.length;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
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
                              color: const Color(0xFF6366F1),
                              size: 16,
                            ),
                          Text(
                            button.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isSelected ? '已选择' : '点击选择',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected 
                                  ? const Color(0xFF6366F1)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            if (_selectedButtonIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '已选择 ${_selectedButtonIds.length} 个按键',
                  style: TextStyle(
                    color: Colors.blue.shade700,
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

  Widget _buildButtonTextGenerationCard() {
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
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.deepPurple.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '光影文字图片生成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '🎨 为按键生成带有光影效果的艺术文字图片',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 提示词输入
            TextField(
              controller: _buttonBgPromptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '描述你想要的光影文字效果...\n例如：金色金属质感，带有光晕和阴影的3D效果',
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
                '🌟 金色金属质感',
                '💎 水晶玻璃效果',
                '🔥 炫酷霓虹风格',
                '❄️ 冰雪透明质感',
                '🌈 彩虹渐变光影',
                '⚡ 雷电发光效果',
              ].map((example) => 
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    String prompt = '';
                    if (example.contains('金色金属')) prompt = '金色金属质感文字，带有光泽反射和深度阴影效果，类似苹果LOGO的高端质感';
                    else if (example.contains('水晶玻璃')) prompt = '透明水晶玻璃效果，清澈透明带有折射光线，精致高雅';
                    else if (example.contains('炫酷霓虹')) prompt = '霓虹灯发光效果，鲜艳色彩带有炫酷光晕，科技感十足';
                    else if (example.contains('冰雪透明')) prompt = '冰雪透明质感，清冷的蓝白色调，带有结冰纹理效果';
                    else if (example.contains('彩虹渐变')) prompt = '彩虹渐变光影效果，丰富色彩流动，梦幻绚烂';
                    else if (example.contains('雷电发光')) prompt = '雷电般的发光效果，电光闪烁，动感十足的视觉冲击';
                    _buttonBgPromptController.text = prompt;
                  },
                  backgroundColor: Colors.grey.shade100,
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateButtonText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGeneratingButtonBg
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '✨ 生成光影文字图片',
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

  Future<void> _generateAppBackground() async {
    if (_appBgPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入背景描述')),
      );
      return;
    }

    setState(() {
      _isGeneratingAppBg = true;
      _generatedAppBgUrl = null;
    });

    try {
      final result = await AIService.generateAppBackground(
        prompt: _appBgPromptController.text.trim(),
        style: 'modern',
        size: '1080x1920',
        quality: 'high',
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
          _isGeneratingAppBg = false;
        });
      }
    }
  }

  void _applyAppBackground() {
    if (_generatedAppBgUrl == null) return;

    final newAppBackground = AppBackgroundConfig(
      backgroundImageUrl: _generatedAppBgUrl,
      backgroundType: 'image',
      backgroundOpacity: 1.0,
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

    widget.onConfigUpdated(updatedConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 背景已应用！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generateButtonText() async {
    // 检查条件并给出提示
    if (_isGeneratingButtonBg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成中，请稍候...')),
      );
      return;
    }
    
    if (_buttonBgPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入文字风格描述')),
      );
      return;
    }
    
    if (_selectedButtonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要生成文字的按键')),
      );
      return;
    }

    setState(() {
      _isGeneratingButtonBg = true;
    });

    try {
      await _generateSelectedButtonTexts();
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
          _isGeneratingButtonBg = false;
        });
      }
    }
  }

  Future<void> _generateSelectedButtonTexts() async {
    final buttons = widget.currentConfig.layout.buttons;
    final selectedButtons = buttons.where((b) => _selectedButtonIds.contains(b.id)).toList();
    final basePrompt = _buttonBgPromptController.text.trim();
    
    int successCount = 0;
    
    for (int i = 0; i < selectedButtons.length; i++) {
      final button = selectedButtons[i];
      final enhancedPrompt = '$basePrompt，为文字"${button.label}"生成光影效果图片';
      
      try {
        // 根据按键类型选择不同的风格
        String style = 'modern';
        List<String> effects = ['glow', 'shadow', 'depth'];
        
        if (button.type == 'operator') {
          style = 'neon';
          effects = ['glow', 'shadow', 'emboss'];
        } else if (button.type == 'special') {
          style = 'silver';
          effects = ['metallic', 'reflection', 'shadow'];
        }
        
        final result = await AIService.generateTextImage(
          prompt: enhancedPrompt,
          text: button.label,
          style: style,
          size: '256x256',
          background: 'transparent',
          effects: effects,
        );

        if (result['success'] == true && result['image_url'] != null) {
          _updateButtonTextImage(button, result['image_url']);
          successCount++;
        }
      } catch (e) {
        print('生成按键${button.label}光影文字图片失败: $e');
      }
      
      // 添加短暂延迟避免API限制
      if (i < selectedButtons.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已为 $successCount 个按键生成光影文字图片！'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _updateButtonTextImage(CalculatorButton button, String imageUrl) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    final updatedButton = CalculatorButton(
      id: button.id,
      label: button.label, // 保持原有文字标签
      action: button.action,
      gridPosition: button.gridPosition,
      type: button.type,
      customColor: button.customColor,
      isWide: button.isWide,
      widthMultiplier: button.widthMultiplier,
      heightMultiplier: button.heightMultiplier,
      gradientColors: button.gradientColors,
      backgroundImage: imageUrl, // 设置生成的光影文字图片为背景
      fontSize: button.fontSize,
      borderRadius: button.borderRadius,
      elevation: button.elevation,
      width: button.width,
      height: button.height,
      backgroundColor: button.backgroundColor,
      textColor: '#00000000', // 隐藏原文字，显示图片
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
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
      appBackground: provider.config.appBackground,
    );

    provider.applyConfig(updatedConfig);
  }

  void _updateButtonText(CalculatorButton button, String newText) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    final updatedButton = CalculatorButton(
      id: button.id,
      label: newText, // 更新按键显示文字
      action: button.action,
      gridPosition: button.gridPosition,
      type: button.type,
      customColor: button.customColor,
      isWide: button.isWide,
      widthMultiplier: button.widthMultiplier,
      heightMultiplier: button.heightMultiplier,
      gradientColors: button.gradientColors,
      backgroundImage: button.backgroundImage, // 保持原有背景图
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
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
      appBackground: provider.config.appBackground,
    );

    provider.applyConfig(updatedConfig);
  }

  // 按键背景图Tab页面
  Widget _buildButtonBackgroundTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 多选按键选择
          _buildMultiButtonBgSelectionCard(),
          const SizedBox(height: 20),
          
          // 按键背景图生成区域
          _buildButtonPatternGenerationCard(),
        ],
      ),
    );
  }

  // 按键背景图多选卡片
  Widget _buildMultiButtonBgSelectionCard() {
    final buttons = widget.currentConfig.layout.buttons;
    
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
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                final button = buttons[index];
                final isSelected = _selectedButtonBgIds.contains(button.id);
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedButtonBgIds.remove(button.id);
                        } else {
                          _selectedButtonBgIds.add(button.id);
                        }
                        _selectAllBg = _selectedButtonBgIds.length == buttons.length;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
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
                              size: 16,
                            ),
                          Text(
                            button.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isSelected ? '已选择' : '点击选择',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected 
                                  ? Colors.orange
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
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

  // 按键背景图生成卡片
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
                    color: Colors.deepOrange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.deepOrange.shade700),
                ),
                const SizedBox(width: 12),
                const Text(
                  '背景图生成',
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
                '几何图案 🔸🔹⬜',
                '自然纹理 🌿🌊🍃',
                '科技线条 ⚡🔋💫',
                '抽象艺术 🎨🌈✨',
                '金属质感 ⚙️🔧⚡',
                '木纹材质 🌳🪵🍂',
              ].map((example) => 
                ActionChip(
                  label: Text(example, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    String prompt = '';
                    if (example.contains('几何图案')) prompt = '简洁的几何图案背景，适合按键使用的现代设计';
                    else if (example.contains('自然纹理')) prompt = '自然纹理背景，叶子或水波纹理，清新自然风格';
                    else if (example.contains('科技线条')) prompt = '科技感线条图案，未来主义设计风格';
                    else if (example.contains('抽象艺术')) prompt = '抽象艺术图案，色彩丰富的创意设计';
                    else if (example.contains('金属质感')) prompt = '金属质感纹理，工业风格的按键背景';
                    else if (example.contains('木纹材质')) prompt = '真实木纹纹理，自然温暖的木质感';
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
                hintText: '描述你想要的按键背景图案...\n例如：简洁的几何图案，适合计算器按键的现代设计',
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
                  backgroundColor: Colors.deepOrange.shade600,
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

  // 生成按键背景图案
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

  // 生成选中按键的背景图案
  Future<void> _generateSelectedButtonPatterns() async {
    final buttons = widget.currentConfig.layout.buttons;
    final selectedButtons = buttons.where((b) => _selectedButtonBgIds.contains(b.id)).toList();
    final basePrompt = _buttonPatternPromptController.text.trim();
    
    for (int i = 0; i < selectedButtons.length; i++) {
      final button = selectedButtons[i];
      final prompt = '$basePrompt - 为按键"${button.label}"生成背景图案';
      
      try {
        final result = await AIService.generatePattern(
          prompt: prompt,
          style: 'minimal',
          size: '128x128',
        );

        if (result['success'] == true && result['pattern_url'] != null) {
          _updateButtonPattern(button, result['pattern_url']);
        }
      } catch (e) {
        print('生成按键${button.label}背景图失败: $e');
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

  // 更新按键背景图案
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
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    provider.applyConfig(updatedConfig);
  }

  Uint8List _base64ToBytes(String base64String) {
    if (base64String.startsWith('data:')) {
      base64String = base64String.split(',')[1];
    }
    return base64Decode(base64String);
  }
} 