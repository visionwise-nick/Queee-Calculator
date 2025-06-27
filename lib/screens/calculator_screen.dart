import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button_grid.dart';
import '../widgets/calculation_history_dialog.dart';
import 'ai_customize_screen.dart';

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
                          // 运算历史按钮
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierColor: Colors.black.withValues(alpha: 0.7),
                                builder: (context) => CalculationHistoryDialog(
                                  steps: provider.calculationHistory,
                                ),
                              );
                            },
                            tooltip: '运算历史',
                          ),
                          const SizedBox(width: 8),
                          // AI助手按钮
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AICustomizeScreen(),
                                ),
                              );
                            },
                            tooltip: 'AI 助手',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 计算器显示屏
                Consumer<CalculatorProvider>(
                  builder: (context, provider, child) {
                    final layout = provider.config.layout;
                    // 根据行数动态调整显示屏高度
                    int displayFlex = layout.rows > 6 ? 1 : 2;
                    
                    return Expanded(
                      flex: displayFlex,
                      child: CalculatorDisplay(
                        state: provider.state,
                        theme: provider.config.theme,
                      ),
                    );
                  },
                ),
                
                // 按钮网格
                Consumer<CalculatorProvider>(
                  builder: (context, provider, child) {
                    final layout = provider.config.layout;
                    // 根据行数动态调整按钮区域大小
                    int buttonFlex = layout.rows > 6 ? 6 : 4;
                    
                    return Expanded(
                      flex: buttonFlex,
                      child: CalculatorButtonGrid(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

 