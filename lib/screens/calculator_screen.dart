import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildAdaptiveLayout(context, provider, constraints);
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建自适应布局
  Widget _buildAdaptiveLayout(BuildContext context, CalculatorProvider provider, BoxConstraints constraints) {
    final layout = provider.config.layout;
    final screenHeight = constraints.maxHeight;
    
    // 计算最优的显示区域高度
    final displayHeight = _calculateOptimalDisplayHeight(layout, screenHeight);
    final buttonAreaHeight = screenHeight - displayHeight - 80; // 预留标题栏空间
    
    return Column(
      children: [
        // 顶部标题栏 - 固定高度
        _buildTitleBar(context, provider),
        
        // 计算器显示屏 - 动态高度
        SizedBox(
          height: displayHeight,
          child: CalculatorDisplay(
            state: provider.state,
            theme: provider.config.theme,
          ),
        ),
        
        // 按钮网格 - 剩余空间
        SizedBox(
          height: buttonAreaHeight,
          child: CalculatorButtonGrid(),
        ),
      ],
    );
  }

  /// 计算最优显示屏高度
  double _calculateOptimalDisplayHeight(CalculatorLayout layout, double screenHeight) {
    // 基础显示高度
    double baseHeight = 80.0;
    
    // 根据布局复杂度调整
    final buttonCount = layout.buttons.length;
    final totalCells = layout.rows * layout.columns;
    final density = buttonCount / totalCells;
    
    // 按钮越多，显示区域相对越小
    if (density > 0.8) {
      baseHeight = screenHeight * 0.15; // 高密度：15%
    } else if (density > 0.6) {
      baseHeight = screenHeight * 0.2;  // 中密度：20%
    } else {
      baseHeight = screenHeight * 0.25; // 低密度：25%
    }
    
    // 确保最小和最大值
    return baseHeight.clamp(60.0, screenHeight * 0.3);
  }

  /// 构建标题栏
  Widget _buildTitleBar(BuildContext context, CalculatorProvider provider) {
    return Container(
      height: 80,
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
    );
  }
}

 