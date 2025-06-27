import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button_grid.dart';
import 'theme_settings_screen.dart';
import 'ai_customize_screen.dart';
import 'conversation_history_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: provider.getBackgroundColor(),
          body: SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queee Calculator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: provider.getDisplayTextColor(),
                        ),
                      ),
                      Row(
                        children: [
                          // 对话历史按钮
                          IconButton(
                            icon: Icon(
                              Icons.history,
                              color: provider.getDisplayTextColor(),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConversationHistoryScreen(),
                                ),
                              );
                            },
                            tooltip: '对话历史',
                          ),
                          // AI 定制按钮
                          IconButton(
                            icon: Icon(
                              Icons.auto_awesome,
                              color: provider.getDisplayTextColor(),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AICustomizeScreen(),
                                ),
                              );
                            },
                            tooltip: 'AI 定制',
                          ),
                          // 设置按钮
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: provider.getDisplayTextColor(),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ThemeSettingsScreen(),
                                ),
                              );
                            },
                            tooltip: '主题设置',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 计算器显示屏
                Expanded(
                  flex: 2,
                  child: CalculatorDisplay(
                    state: provider.state,
                    theme: provider.config.theme,
                  ),
                ),
                
                // 按钮网格
                Expanded(
                  flex: 4,
                  child: CalculatorButtonGrid(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

 