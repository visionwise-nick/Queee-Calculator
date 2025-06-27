import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/config_service.dart';

class AICustomizeScreen extends StatefulWidget {
  const AICustomizeScreen({super.key});

  @override
  State<AICustomizeScreen> createState() => _AICustomizeScreenState();
}

class _AICustomizeScreenState extends State<AICustomizeScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  List<String> get _examplePrompts => AIService.getSamplePrompts();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: provider.getBackgroundColor(),
          appBar: AppBar(
            title: const Text(
              'AI 定制计算器',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: provider.getBackgroundColor(),
            foregroundColor: provider.getDisplayTextColor(),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 介绍卡片
                _buildIntroCard(provider),
                
                const SizedBox(height: 24),
                
                // 输入区域
                _buildInputSection(provider),
                
                const SizedBox(height: 24),
                
                // 示例提示
                _buildExamplePrompts(provider),
                
                  const SizedBox(height: 24),
                
                // 生成按钮
                _buildGenerateButton(provider),
                  
                  // 底部安全间距
                  const SizedBox(height: 32),
              ],
              ),
            ),
          ),
        );
      },
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
                
                if (_errorMessage != null) ...[
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
                            _errorMessage!,
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
        onPressed: _isGenerating ? null : _generateCalculator,
        style: ElevatedButton.styleFrom(
          backgroundColor: _parseColor(provider.config.theme.operatorButtonColor),
          foregroundColor: _parseColor(provider.config.theme.operatorButtonTextColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isGenerating
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
      _errorMessage = null;
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

  Future<void> _generateCalculator() async {
    final prompt = _promptController.text.trim();
    
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage = '请输入你想要的计算器描述';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final generatedConfig = await AIService.generateCalculatorFromPrompt(prompt);
      
      if (generatedConfig != null) {
        // 保存自定义配置
        await ConfigService.saveCustomConfig(generatedConfig);
        
        // 应用新配置
        if (mounted) {
          context.read<CalculatorProvider>().applyConfig(generatedConfig);
          
          // 显示成功消息并返回
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 「${generatedConfig.name}」已生成并应用！'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'AI 生成失败，请尝试重新描述您的需求';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '生成过程中出现错误：$e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
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