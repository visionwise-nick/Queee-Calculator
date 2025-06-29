import 'package:flutter/material.dart';
import '../models/calculator_dsl.dart';
import '../services/ai_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class AppBackgroundScreen extends StatefulWidget {
  final CalculatorConfig currentConfig;
  final Function(CalculatorConfig) onConfigUpdated;

  const AppBackgroundScreen({
    Key? key,
    required this.currentConfig,
    required this.onConfigUpdated,
  }) : super(key: key);

  @override
  State<AppBackgroundScreen> createState() => _AppBackgroundScreenState();
}

class _AppBackgroundScreenState extends State<AppBackgroundScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedImageUrl;
  String _selectedStyle = 'modern';
  String _selectedSize = '1080x1920';
  String _selectedQuality = 'high';
  String _selectedTheme = 'calculator';
  Map<String, dynamic>? _backgroundPresets;

  final List<String> _styles = [
    'modern',
    'minimalist', 
    'cyberpunk',
    'nature',
    'abstract',
    'geometric',
    'gradient',
    'professional',
    'artistic',
    'retro'
  ];

  final List<String> _sizes = [
    '1080x1920',
    '1440x2560', 
    '1242x2688',
    '828x1792',
  ];

  final List<String> _qualities = ['standard', 'high'];
  final List<String> _themes = ['calculator', 'scientific', 'business', 'gaming'];

  @override
  void initState() {
    super.initState();
    _loadBackgroundPresets();
  }

  Future<void> _loadBackgroundPresets() async {
    try {
      final presets = await AIService.getBackgroundPresets();
      setState(() {
        _backgroundPresets = presets;
      });
    } catch (e) {
      print('加载背景预设失败: $e');
    }
  }

  Future<void> _generateBackground() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入背景描述')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedImageUrl = null;
    });

    try {
      final result = await AIService.generateAppBackground(
        prompt: _promptController.text.trim(),
        style: _selectedStyle,
        size: _selectedSize,
        quality: _selectedQuality,
        theme: _selectedTheme,
      );

      if (result['success'] == true && result['background_url'] != null) {
        setState(() {
          _generatedImageUrl = result['background_url'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 背景图生成成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message'] ?? '生成失败');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _applyBackground() {
    if (_generatedImageUrl == null) return;

    // 创建新的APP背景配置
    final newAppBackground = AppBackgroundConfig(
      backgroundImageUrl: _generatedImageUrl,
      backgroundType: 'image',
      backgroundOpacity: 1.0,
    );

    // 更新计算器配置
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

  void _removeBackground() {
    // 移除APP背景配置
    final updatedConfig = CalculatorConfig(
      id: widget.currentConfig.id,
      name: widget.currentConfig.name,
      description: widget.currentConfig.description,
      theme: widget.currentConfig.theme,
      layout: widget.currentConfig.layout,
      appBackground: null, // 移除背景
      version: widget.currentConfig.version,
      createdAt: widget.currentConfig.createdAt,
      authorPrompt: widget.currentConfig.authorPrompt,
      thinkingProcess: widget.currentConfig.thinkingProcess,
      aiResponse: widget.currentConfig.aiResponse,
    );

    widget.onConfigUpdated(updatedConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 背景已移除！'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildPresetButtons() {
    final samplePrompts = AIService.getBackgroundSamplePrompts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速选择',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: samplePrompts.map((prompt) => 
            ActionChip(
              label: Text(
                prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                _promptController.text = prompt;
              },
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrentBackground() {
    final currentBackground = widget.currentConfig.appBackground;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '当前背景',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentBackground?.backgroundImageUrl != null)
                  TextButton.icon(
                    onPressed: _removeBackground,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('移除', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (currentBackground?.backgroundImageUrl != null)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(_base64ToBytes(currentBackground!.backgroundImageUrl!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: const Center(
                  child: Text(
                    '暂无背景图',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Uint8List _base64ToBytes(String base64String) {
    // 移除data:image/jpeg;base64,前缀
    if (base64String.startsWith('data:')) {
      base64String = base64String.split(',')[1];
    }
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APP背景设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前背景显示
            _buildCurrentBackground(),
            const SizedBox(height: 24),

            // 背景生成区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI生成新背景',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 预设按钮
                    _buildPresetButtons(),
                    const SizedBox(height: 16),

                    // 提示词输入
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '描述您想要的背景',
                        hintText: '例如：优雅的现代几何背景，深蓝色调，适合计算器应用...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 参数设置
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStyle,
                            decoration: const InputDecoration(
                              labelText: '风格',
                              border: OutlineInputBorder(),
                            ),
                            items: _styles.map((style) => DropdownMenuItem(
                              value: style,
                              child: Text(style),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStyle = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedQuality,
                            decoration: const InputDecoration(
                              labelText: '质量',
                              border: OutlineInputBorder(),
                            ),
                            items: _qualities.map((quality) => DropdownMenuItem(
                              value: quality,
                              child: Text(quality),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedQuality = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 生成按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateBackground,
                        icon: _isGenerating 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                        label: Text(_isGenerating ? '生成中...' : '生成背景'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 生成结果预览
            if (_generatedImageUrl != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '生成结果预览',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(_base64ToBytes(_generatedImageUrl!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _applyBackground,
                              icon: const Icon(Icons.check),
                              label: const Text('应用此背景'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generateBackground,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重新生成'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
} 