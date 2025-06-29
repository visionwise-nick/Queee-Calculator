import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/config_service.dart';
import '../models/calculator_dsl.dart';
import '../widgets/image_upload_widget.dart';
import 'advanced_theme_settings_screen.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
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
              children: [
                // 预设主题列表
                Expanded(
                  child: _buildPresetThemesList(provider),
                ),
                
                // 高级主题设置按钮
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdvancedThemeSettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('高级主题设置'),
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
                
                // AI 定制按钮
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
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