import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import '../widgets/image_upload_widget.dart';

class AdvancedThemeSettingsScreen extends StatefulWidget {
  const AdvancedThemeSettingsScreen({super.key});

  @override
  State<AdvancedThemeSettingsScreen> createState() => _AdvancedThemeSettingsScreenState();
}

class _AdvancedThemeSettingsScreenState extends State<AdvancedThemeSettingsScreen> {
  late CalculatorTheme _workingTheme;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    _workingTheme = CalculatorTheme(
      name: provider.config.theme.name,
      backgroundColor: provider.config.theme.backgroundColor,
      backgroundGradient: provider.config.theme.backgroundGradient,
      backgroundImage: provider.config.theme.backgroundImage,
      displayBackgroundColor: provider.config.theme.displayBackgroundColor,
      displayBackgroundGradient: provider.config.theme.displayBackgroundGradient,
      displayTextColor: provider.config.theme.displayTextColor,
      displayWidth: provider.config.theme.displayWidth,
      displayHeight: provider.config.theme.displayHeight,
      displayBorderRadius: provider.config.theme.displayBorderRadius,
      primaryButtonColor: provider.config.theme.primaryButtonColor,
      primaryButtonGradient: provider.config.theme.primaryButtonGradient,
      primaryButtonTextColor: provider.config.theme.primaryButtonTextColor,
      secondaryButtonColor: provider.config.theme.secondaryButtonColor,
      secondaryButtonGradient: provider.config.theme.secondaryButtonGradient,
      secondaryButtonTextColor: provider.config.theme.secondaryButtonTextColor,
      operatorButtonColor: provider.config.theme.operatorButtonColor,
      operatorButtonGradient: provider.config.theme.operatorButtonGradient,
      operatorButtonTextColor: provider.config.theme.operatorButtonTextColor,
      fontSize: provider.config.theme.fontSize,
      buttonBorderRadius: provider.config.theme.buttonBorderRadius,
      hasGlowEffect: provider.config.theme.hasGlowEffect,
      shadowColor: provider.config.theme.shadowColor,
      buttonElevation: provider.config.theme.buttonElevation,
      buttonShadowColors: provider.config.theme.buttonShadowColors,
      buttonSpacing: provider.config.theme.buttonSpacing,
      adaptiveLayout: provider.config.theme.adaptiveLayout,
    );
  }

  void _updateTheme(VoidCallback update) {
    setState(() {
      update();
      _hasChanges = true;
    });
  }

  Future<void> _applyChanges() async {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    
    // 创建新的配置
    final newConfig = CalculatorConfig(
      id: provider.config.id,
      name: provider.config.name,
      description: provider.config.description,
      theme: _workingTheme,
      layout: provider.config.layout,
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    await provider.applyConfig(newConfig);
    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('主题设置已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: _parseColor(_workingTheme.backgroundColor),
          appBar: AppBar(
            title: const Text('高级主题设置'),
            backgroundColor: _parseColor(_workingTheme.displayBackgroundColor),
            foregroundColor: _parseColor(_workingTheme.displayTextColor),
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _applyChanges,
                  child: Text(
                    '保存',
                    style: TextStyle(
                      color: _parseColor(_workingTheme.displayTextColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 背景设置
              _buildBackgroundSection(),
              const SizedBox(height: 24),
              
              // 显示区设置
              _buildDisplaySection(),
              const SizedBox(height: 24),
              
              // 按钮设置
              _buildButtonSection(),
              const SizedBox(height: 24),
              
              // 效果设置
              _buildEffectsSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundSection() {
    return Card(
      color: _parseColor(_workingTheme.displayBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '背景设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _parseColor(_workingTheme.displayTextColor),
              ),
            ),
            const SizedBox(height: 16),
            
            // 背景图片上传
            ImageUploadWidget(
              title: '背景图片',
              currentImageUrl: _workingTheme.backgroundImage,
              showAIGeneration: true,
              onImageSelected: (imageUrl) {
                _updateTheme(() {
                  _workingTheme = _workingTheme.copyWith(
                    backgroundImage: imageUrl.isEmpty ? null : imageUrl,
                  );
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 背景颜色
            _buildColorPicker(
              '背景颜色',
              _workingTheme.backgroundColor,
              (color) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(backgroundColor: color);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      color: _parseColor(_workingTheme.displayBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '显示区设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _parseColor(_workingTheme.displayTextColor),
              ),
            ),
            const SizedBox(height: 16),
            
            // 显示区背景颜色
            _buildColorPicker(
              '显示区背景颜色',
              _workingTheme.displayBackgroundColor,
              (color) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(displayBackgroundColor: color);
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 显示区文字颜色
            _buildColorPicker(
              '显示区文字颜色',
              _workingTheme.displayTextColor,
              (color) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(displayTextColor: color);
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 显示区圆角
            _buildSlider(
              '显示区圆角',
              _workingTheme.displayBorderRadius ?? 8.0,
              0.0,
              24.0,
              (value) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(displayBorderRadius: value);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection() {
    return Card(
      color: _parseColor(_workingTheme.displayBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '按钮设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _parseColor(_workingTheme.displayTextColor),
              ),
            ),
            const SizedBox(height: 16),
            
            // 主按钮颜色
            _buildColorPicker(
              '主按钮颜色',
              _workingTheme.primaryButtonColor,
              (color) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(primaryButtonColor: color);
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 运算符按钮颜色
            _buildColorPicker(
              '运算符按钮颜色',
              _workingTheme.operatorButtonColor,
              (color) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(operatorButtonColor: color);
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 按钮圆角
            _buildSlider(
              '按钮圆角',
              _workingTheme.buttonBorderRadius,
              0.0,
              24.0,
              (value) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(buttonBorderRadius: value);
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 字体大小
            _buildSlider(
              '字体大小',
              _workingTheme.fontSize,
              12.0,
              32.0,
              (value) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(fontSize: value);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectsSection() {
    return Card(
      color: _parseColor(_workingTheme.displayBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '效果设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _parseColor(_workingTheme.displayTextColor),
              ),
            ),
            const SizedBox(height: 16),
            
            // 发光效果
            SwitchListTile(
              title: Text(
                '发光效果',
                style: TextStyle(color: _parseColor(_workingTheme.displayTextColor)),
              ),
              value: _workingTheme.hasGlowEffect,
              onChanged: (value) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(hasGlowEffect: value);
              }),
              activeColor: _parseColor(_workingTheme.operatorButtonColor),
            ),
            
            // 按钮阴影高度
            _buildSlider(
              '按钮阴影高度',
              _workingTheme.buttonElevation ?? 2.0,
              0.0,
              8.0,
              (value) => _updateTheme(() {
                _workingTheme = _workingTheme.copyWith(buttonElevation: value);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String title, String currentColor, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: _parseColor(_workingTheme.displayTextColor)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(currentColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                style: TextStyle(color: _parseColor(_workingTheme.displayTextColor)),
                decoration: InputDecoration(
                  hintText: '#RRGGBB',
                  hintStyle: TextStyle(color: _parseColor(_workingTheme.displayTextColor).withValues(alpha: 0.5)),
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(text: currentColor),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: _parseColor(_workingTheme.displayTextColor)),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: _parseColor(_workingTheme.displayTextColor)),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: _parseColor(_workingTheme.operatorButtonColor),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hexString = colorString;
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
      }
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
} 