import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../widgets/calculator_button.dart';
import '../widgets/thinking_process_dialog.dart';

class SoundGenerationScreen extends StatefulWidget {
  final CalculatorConfig currentConfig;
  final Function(CalculatorConfig) onConfigUpdated;

  const SoundGenerationScreen({
    super.key,
    required this.currentConfig,
    required this.onConfigUpdated,
  });

  @override
  State<SoundGenerationScreen> createState() => _SoundGenerationScreenState();
}

class _SoundGenerationScreenState extends State<SoundGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isGenerating = false;
  String _selectedButtonId = '';
  String _selectedStyle = 'modern';
  String _selectedPitch = 'medium';
  String _selectedVolume = 'medium';
  double _duration = 0.1;
  
  final List<String> _soundStyles = [
    'modern', 'retro', 'nature', 'sci-fi', 'minimal', 'mechanical'
  ];
  
  final List<String> _pitchOptions = ['low', 'medium', 'high'];
  final List<String> _volumeOptions = ['low', 'medium', 'high'];

  // 快速示例音效
  final List<Map<String, String>> _quickExamples = [
    {
      'name': '机械键盘',
      'prompt': '机械键盘按键声，清脆有力',
      'style': 'mechanical',
      'icon': 'keyboard',
    },
    {
      'name': '水滴音效',
      'prompt': '清脆的水滴声，自然清新',
      'style': 'nature',
      'icon': 'water_drop',
    },
    {
      'name': '科技音效',
      'prompt': '未来科技感按键声，电子合成',
      'style': 'sci-fi',
      'icon': 'psychology',
    },
    {
      'name': '极简音效',
      'prompt': '简洁纯净的点击声',
      'style': 'minimal',
      'icon': 'radio_button_checked',
    },
    {
      'name': '复古音效',
      'prompt': '温暖的模拟按键声',
      'style': 'retro',
      'icon': 'vintage_and_more',
    },
    {
      'name': '现代音效',
      'prompt': '现代数字设备按键声',
      'style': 'modern',
      'icon': 'touch_app',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音效生成工坊'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllSounds,
            tooltip: '恢复默认音效',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择按键部分
            _buildButtonSelectionSection(),
            const SizedBox(height: 24),
            
            // 快速示例部分
            _buildQuickExamplesSection(),
            const SizedBox(height: 24),
            
            // 自定义生成部分
            _buildCustomGenerationSection(),
            const SizedBox(height: 24),
            
            // 音效参数配置
            _buildSoundParametersSection(),
            const SizedBox(height: 24),
            
            // 生成按钮
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSelectionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 选择按键',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请选择要设置音效的按键：',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildButtonGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final buttons = widget.currentConfig.layout.buttons;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: buttons.length,
          itemBuilder: (context, index) {
            final button = buttons[index];
            final isSelected = _selectedButtonId == button.id;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedButtonId = button.id;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    button.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickExamplesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ 快速示例',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '点击下方示例快速生成音效：',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickExamples.map((example) {
                return _buildExampleChip(example);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(Map<String, String> example) {
    return ActionChip(
      avatar: Icon(
        _getIconData(example['icon'] ?? 'touch_app'),
        size: 16,
      ),
      label: Text(example['name'] ?? ''),
      onPressed: () {
        setState(() {
          _promptController.text = example['prompt'] ?? '';
          _selectedStyle = example['style'] ?? 'modern';
        });
      },
      backgroundColor: Colors.orange.withOpacity(0.1),
      side: BorderSide(color: Colors.orange.withOpacity(0.3)),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'keyboard':
        return Icons.keyboard;
      case 'water_drop':
        return Icons.water_drop;
      case 'psychology':
        return Icons.psychology;
      case 'radio_button_checked':
        return Icons.radio_button_checked;
      case 'vintage_and_more':
        return Icons.history;
      case 'touch_app':
        return Icons.touch_app;
      default:
        return Icons.music_note;
    }
  }

  Widget _buildCustomGenerationSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎨 自定义生成',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '描述您想要的音效：',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '例如：清脆的机械键盘按键声，有金属质感',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundParametersSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎛️ 音效参数',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            
            // 风格选择
            _buildParameterSection('风格', _soundStyles, _selectedStyle, (value) {
              setState(() {
                _selectedStyle = value;
              });
            }),
            
            // 音调选择
            _buildParameterSection('音调', _pitchOptions, _selectedPitch, (value) {
              setState(() {
                _selectedPitch = value;
              });
            }),
            
            // 音量选择
            _buildParameterSection('音量', _volumeOptions, _selectedVolume, (value) {
              setState(() {
                _selectedVolume = value;
              });
            }),
            
            // 持续时间
            const SizedBox(height: 16),
            Text(
              '持续时间: ${_duration.toStringAsFixed(2)}秒',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _duration,
              min: 0.05,
              max: 0.5,
              divisions: 45,
              onChanged: (value) {
                setState(() {
                  _duration = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterSection(String title, List<String> options, String selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              backgroundColor: Colors.grey.withOpacity(0.1),
              selectedColor: Colors.green.withOpacity(0.2),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating || _selectedButtonId.isEmpty || _promptController.text.isEmpty
            ? null
            : _generateSound,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('正在生成音效...'),
                ],
              )
            : const Text(
                '🎵 生成音效',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _generateSound() async {
    if (_selectedButtonId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个按键')),
      );
      return;
    }
    
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入音效描述')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // 获取选中的按键
      final selectedButton = widget.currentConfig.layout.buttons.firstWhere(
        (button) => button.id == _selectedButtonId,
      );

      // 调用AI服务生成音效
      final result = await AIService.generateSound(
        prompt: _promptController.text,
        buttonType: selectedButton.type,
        style: _selectedStyle,
        duration: _duration,
        pitch: _selectedPitch,
        volume: _selectedVolume,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '音效生成成功')),
        );
        
        // 这里可以添加音效应用逻辑
        // 由于当前Gemini不支持音效生成，这里只是显示成功消息
        
      } else {
        // 显示错误信息或建议的音效
        _showSoundSuggestions(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('音效生成失败: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showSoundSuggestions(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音效生成功能'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? '音效生成功能暂未实现'),
            const SizedBox(height: 16),
            if (result['suggested_sounds'] != null) ...[
              const Text('建议使用以下预设音效：'),
              const SizedBox(height: 8),
              ...((result['suggested_sounds'] as List).map((sound) => 
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.music_note),
                  title: Text(sound['name']),
                  subtitle: Text(sound['description']),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    // 这里可以播放预设音效
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('播放 ${sound['name']}')),
                    );
                  },
                )
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _resetAllSounds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认音效'),
        content: const Text('确定要恢复所有按键的默认音效吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复默认音效')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 