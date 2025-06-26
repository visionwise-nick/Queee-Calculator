import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/config_service.dart';
import '../models/calculator_dsl.dart';
import 'ai_customize_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  List<String> _presetThemes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPresetThemes();
  }

  Future<void> _loadPresetThemes() async {
    final presets = await ConfigService.getAvailablePresets();
    setState(() {
      _presetThemes = presets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: provider.getBackgroundColor(),
          appBar: AppBar(
            title: const Text(
              '主题设置',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: provider.getBackgroundColor(),
            foregroundColor: provider.getDisplayTextColor(),
            elevation: 0,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 当前主题信息
                    _buildCurrentThemeCard(provider),
                    
                    const SizedBox(height: 24),
                    
                    // 预设主题
                    Text(
                      '预设主题',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: provider.getDisplayTextColor(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._presetThemes.map((preset) => _buildThemeCard(preset, provider)),
                    
                    const SizedBox(height: 24),
                    
                    // AI 定制按钮
                    _buildAICustomizeButton(context, provider),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCurrentThemeCard(CalculatorProvider provider) {
    final config = provider.config;
    return Card(
      color: provider.getDisplayBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: provider.getDisplayTextColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  '当前主题',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: provider.getDisplayTextColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              config.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: provider.getDisplayTextColor(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              config.description ?? '',
              style: TextStyle(
                fontSize: 14,
                color: provider.getDisplayTextColor().withValues(alpha: 0.7),
              ),
            ),
            if (config.authorPrompt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: provider.getButtonColor(provider.config.layout.buttons.first).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '原始需求：${config.authorPrompt}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: provider.getDisplayTextColor().withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(String presetName, CalculatorProvider provider) {
    return FutureBuilder<CalculatorConfig>(
      future: ConfigService.loadPresetConfig(presetName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final config = snapshot.data!;
        final isCurrentTheme = provider.config.id == config.id;
        
        return Card(
          color: provider.getDisplayBackgroundColor(),
          child: InkWell(
            onTap: isCurrentTheme ? null : () => _selectTheme(config, provider),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 主题预览色块
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _parseColor(config.theme.backgroundColor),
                      border: Border.all(
                        color: provider.getDisplayTextColor().withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _parseColor(config.theme.displayBackgroundColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 16,
                                margin: const EdgeInsets.fromLTRB(2, 0, 1, 2),
                                decoration: BoxDecoration(
                                  color: _parseColor(config.theme.primaryButtonColor),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 16,
                                margin: const EdgeInsets.fromLTRB(1, 0, 2, 2),
                                decoration: BoxDecoration(
                                  color: _parseColor(config.theme.operatorButtonColor),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 主题信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: provider.getDisplayTextColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.description ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: provider.getDisplayTextColor().withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 选中状态指示器
                  if (isCurrentTheme)
                    Icon(
                      Icons.check_circle,
                      color: _parseColor(config.theme.operatorButtonColor),
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      color: provider.getDisplayTextColor().withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAICustomizeButton(BuildContext context, CalculatorProvider provider) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _parseColor(provider.config.theme.operatorButtonColor).withOpacity(0.5), 
          width: 2
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AICustomizeScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _parseColor(provider.config.theme.operatorButtonColor),
                      _parseColor(provider.config.theme.secondaryButtonColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome, 
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 定制计算器',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.getDisplayTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '用自然语言描述你想要的计算器',
                      style: TextStyle(
                        fontSize: 14,
                        color: provider.getDisplayTextColor().withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: provider.getDisplayTextColor().withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTheme(CalculatorConfig config, CalculatorProvider provider) {
    provider.updateConfig(config);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换到「${config.name}」主题'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AI 定制计算器'),
          content: const Text('即将推出：用自然语言定制你的专属计算器！'),
          actions: <Widget>[
            TextButton(
              child: const Text('期待中'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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