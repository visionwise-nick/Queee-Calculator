import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/config_service.dart';
import '../models/calculator_dsl.dart';

class AICustomizeScreen extends StatefulWidget {
  const AICustomizeScreen({super.key});

  @override
  State<AICustomizeScreen> createState() => _AICustomizeScreenState();
}

class _AICustomizeScreenState extends State<AICustomizeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AIService _aiService = AIService();
  bool _isLoading = false;
  String? _error;

  final List<String> _examplePrompts = [
    '我想要一个赛博朋克风格的计算器，黑底配霓虹蓝的按键',
    '给我一个基础的计算器，但把百分比按钮换成一个"算小费"的按钮，税率是15%',
    '我是个程序员，我需要一个能进行与、或、非、异或运算的十六进制计算器',
    '我要一个猫咪主题的计算器，粉色可爱风格',
    '简洁的白色主题计算器，极简风格',
    '复古风格的棕色计算器，像老式收音机一样',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<CalculatorProvider>(context).config.theme;
    final backgroundColor = _parseColor(theme.backgroundColor, fallback: Colors.white);
    final textColor = _parseColor(theme.displayTextColor, fallback: Colors.black);
    final primaryColor = _parseColor(theme.primaryButtonColor, fallback: Colors.grey);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'AI 定制计算器',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '用一句话描述你想要的计算器：',
                style: TextStyle(fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '例如："一个赛博朋克风格的计算器"',
                  hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _generateConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('立即生成', style: TextStyle(fontSize: 18)),
                    ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                '💡 试试这些创意：\n- 深邃海洋主题，带气泡音效\n- 程序员专用，能算十六进制\n- 小费计算器，税率15%\n- 复古木质纹理计算器',
                style: TextStyle(color: textColor.withOpacity(0.7), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(CalculatorProvider provider) {
    return Card(
      color: provider.getDisplayBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '用自然语言描述你想要的计算器',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: provider.getDisplayTextColor(),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'AI 将根据你的描述生成独一无二的计算器配置，包括主题颜色、按钮布局和特殊功能。',
              style: TextStyle(
                fontSize: 14,
                color: provider.getDisplayTextColor().withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(CalculatorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '描述你的计算器',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: provider.getDisplayTextColor(),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Card(
          color: provider.getDisplayBackgroundColor(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  maxLines: 4,
                  style: TextStyle(
                    color: provider.getDisplayTextColor(),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '例如：我想要一个赛博朋克风格的计算器，黑底配霓虹蓝的按键...',
                    hintStyle: TextStyle(
                      color: provider.getDisplayTextColor().withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamplePrompts(CalculatorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '示例想法 💡',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: provider.getDisplayTextColor(),
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...List.generate(_examplePrompts.length, (index) {
          if (index >= 3) return const SizedBox.shrink(); // 只显示前3个示例
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: provider.getDisplayBackgroundColor(),
              child: InkWell(
                onTap: () => _setExamplePrompt(_examplePrompts[index]),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: provider.getDisplayTextColor().withValues(alpha: 0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _examplePrompts[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: provider.getDisplayTextColor().withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        
        if (_examplePrompts.length > 3)
          TextButton(
            onPressed: _showAllExamples,
            child: Text(
              '查看更多示例 (${_examplePrompts.length - 3}+)',
              style: TextStyle(
                color: _parseColor(provider.config.theme.operatorButtonColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenerateButton(CalculatorProvider provider) {
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateConfig,
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseColor(provider.config.theme.operatorButtonColor),
          foregroundColor: _parseColor(provider.config.theme.operatorButtonTextColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _parseColor(provider.config.theme.operatorButtonTextColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI 正在生成中...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                '🎨 生成我的计算器',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _setExamplePrompt(String prompt) {
    _promptController.text = prompt;
    setState(() {
      _error = null;
    });
  }

  void _showAllExamples() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Consumer<CalculatorProvider>(
        builder: (context, provider, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: provider.getBackgroundColor(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '示例描述',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: provider.getDisplayTextColor(),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _examplePrompts.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          color: provider.getDisplayBackgroundColor(),
                          child: InkWell(
                            onTap: () {
                              _setExamplePrompt(_examplePrompts[index]);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _examplePrompts[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: provider.getDisplayTextColor(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateConfig() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _error = '请输入您的设计想法！';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final CalculatorConfig? newConfig = await _aiService.generateConfig(_promptController.text);
      
      if (mounted) {
        if (newConfig != null) {
          Provider.of<CalculatorProvider>(context, listen: false).updateConfig(newConfig);
          // 成功后返回上一页
          Navigator.of(context).pop();
        } else {
          setState(() {
            _error = '生成失败: AI 服务返回空配置';
          });
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '生成失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String colorString, {Color fallback = Colors.grey}) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) | 0xFF000000);
      }
    } catch (e) {
      // 发生错误时返回后备颜色
    }
    return fallback;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}

extension on CalculatorProvider {
  Color getBackgroundColor() {
    return _parseColor(config.theme.backgroundColor);
  }
  
  Color getDisplayBackgroundColor() {
    return _parseColor(config.theme.displayBackgroundColor);
  }
  
  Color getDisplayTextColor() {
    return _parseColor(config.theme.displayTextColor);
  }
  
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) | 0xFF000000);
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }
} 