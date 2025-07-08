import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/config_service.dart';
import '../models/calculator_dsl.dart'; // 🔧 新增：导入AppBackgroundConfig

class ThemeSettingsScreen extends StatefulWidget { // 🔧 改为StatefulWidget支持状态管理
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  // 🔧 透明度控制变量
  double _buttonOpacity = 1.0;
  double _displayOpacity = 1.0;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        // 🔧 初始化透明度值
        if (!_isInitialized) {
          _buttonOpacity = provider.config.appBackground?.buttonOpacity ?? 1.0;
          _displayOpacity = provider.config.appBackground?.displayOpacity ?? 1.0;
          _isInitialized = true;
        }

        return Scaffold(
          backgroundColor: provider.getBackgroundColor(),
          appBar: AppBar(
            title: Text(
              '主题设置',
              style: TextStyle(color: provider.getDisplayTextColor()),
            ),
            backgroundColor: provider.getDisplayBackgroundColor(),
            iconTheme: IconThemeData(color: provider.getDisplayTextColor()),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔧 新增：透明度控制区域
                _buildOpacityControls(provider),
                const SizedBox(height: 24),
                
                // 预设主题列表
                Expanded(
                  child: _buildPresetThemesList(provider),
                ),
                
                // AI 定制按钮
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/ai-customize');
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI 智能定制'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: provider.getButtonBackgroundColor(
                        provider.config.layout.buttons.first,
                      ),
                      foregroundColor: provider.getButtonTextColor(
                        provider.config.layout.buttons.first,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔧 新增：构建透明度控制区域
  Widget _buildOpacityControls(CalculatorProvider provider) {
    return Card(
      color: provider.getDisplayBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '界面透明度控制',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: provider.getDisplayTextColor(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 显示区域透明度滑块
            Row(
              children: [
                Icon(Icons.monitor, color: provider.getDisplayTextColor().withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 8),
                Text('显示区域透明度', style: TextStyle(color: provider.getDisplayTextColor().withValues(alpha: 0.8))),
                const Spacer(),
                Text('${(_displayOpacity * 100).round()}%', 
                     style: TextStyle(color: provider.getDisplayTextColor(), fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: _displayOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: _parseColor(provider.config.theme.operatorButtonColor),
              inactiveColor: provider.getDisplayTextColor().withValues(alpha: 0.3),
              onChanged: (value) {
                setState(() {
                  _displayOpacity = value;
                });
              },
              onChangeEnd: (value) {
                _applyOpacityChanges(provider);
              },
            ),
            const SizedBox(height: 8),
            
            // 按键透明度滑块
            Row(
              children: [
                Icon(Icons.keyboard, color: provider.getDisplayTextColor().withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 8),
                Text('按键透明度', style: TextStyle(color: provider.getDisplayTextColor().withValues(alpha: 0.8))),
                const Spacer(),
                Text('${(_buttonOpacity * 100).round()}%', 
                     style: TextStyle(color: provider.getDisplayTextColor(), fontWeight: FontWeight.w600)),
              ],
            ),
            Slider(
              value: _buttonOpacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              activeColor: _parseColor(provider.config.theme.operatorButtonColor),
              inactiveColor: provider.getDisplayTextColor().withValues(alpha: 0.3),
              onChanged: (value) {
                setState(() {
                  _buttonOpacity = value;
                });
              },
              onChangeEnd: (value) {
                _applyOpacityChanges(provider);
              },
            ),
            
            // 说明文字
            const SizedBox(height: 8),
            Text(
              '调节透明度让背景图片透过来。需要先设置APP背景图才能看到效果。',
              style: TextStyle(
                fontSize: 12,
                color: provider.getDisplayTextColor().withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 新增：应用透明度变化
  void _applyOpacityChanges(CalculatorProvider provider) {
    final currentAppBackground = provider.config.appBackground;
    
    final newAppBackground = AppBackgroundConfig(
      backgroundImageUrl: currentAppBackground?.backgroundImageUrl,
      backgroundType: currentAppBackground?.backgroundType ?? 'color',
      backgroundColor: currentAppBackground?.backgroundColor,
      backgroundGradient: currentAppBackground?.backgroundGradient,
      backgroundPattern: currentAppBackground?.backgroundPattern,
      backgroundOpacity: currentAppBackground?.backgroundOpacity ?? 1.0,
      buttonOpacity: _buttonOpacity, // 🔧 更新按键透明度
      displayOpacity: _displayOpacity, // 🔧 更新显示区域透明度
      backgroundBlendMode: currentAppBackground?.backgroundBlendMode,
      parallaxEffect: currentAppBackground?.parallaxEffect,
      parallaxIntensity: currentAppBackground?.parallaxIntensity,
    );

    final updatedConfig = CalculatorConfig(
      id: provider.config.id,
      name: provider.config.name,
      description: provider.config.description,
      theme: provider.config.theme,
      layout: provider.config.layout,
      appBackground: newAppBackground,
      version: provider.config.version,
      createdAt: provider.config.createdAt,
      authorPrompt: provider.config.authorPrompt,
      thinkingProcess: provider.config.thinkingProcess,
      aiResponse: provider.config.aiResponse,
    );

    provider.applyConfig(updatedConfig);
    
    // 显示反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 透明度已更新！按键：${(_buttonOpacity * 100).round()}%，显示区域：${(_displayOpacity * 100).round()}%'),
        backgroundColor: _parseColor(provider.config.theme.operatorButtonColor),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildPresetThemesList(CalculatorProvider provider) {
    return FutureBuilder<List<String>>(
      future: ConfigService.getAvailablePresets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              '没有可用的预设主题',
              style: TextStyle(color: provider.getDisplayTextColor()),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final presetName = snapshot.data![index];
            return _buildPresetThemeCard(provider, presetName);
          },
        );
      },
    );
  }

  Widget _buildPresetThemeCard(CalculatorProvider provider, String presetName) {
    return FutureBuilder(
      future: ConfigService.loadPresetConfig(presetName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final config = snapshot.data!;
        final isSelected = provider.config.theme.name == config.theme.name;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: provider.getDisplayBackgroundColor(),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    _parseColor(config.theme.primaryButtonColor),
                    _parseColor(config.theme.operatorButtonColor),
                  ],
                ),
              ),
            ),
            title: Text(
              config.theme.name,
              style: TextStyle(
                color: provider.getDisplayTextColor(),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              config.description,
              style: TextStyle(
                color: provider.getDisplayTextColor().withValues(alpha: 0.7),
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: _parseColor(config.theme.operatorButtonColor),
                  )
                : null,
            onTap: () async {
              await provider.applyConfig(config);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已应用主题：${config.theme.name}'),
                    backgroundColor: _parseColor(config.theme.operatorButtonColor),
                  ),
                );
              }
            },
          ),
        );
      },
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