import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button_grid.dart';
import '../widgets/calculation_history_dialog.dart';
import 'ai_customize_screen.dart';
import 'dart:math' as math;

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final theme = provider.config.theme;
        
        return Scaffold(
          body: Container(
            decoration: _buildBackgroundDecoration(theme),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildAdaptiveLayout(context, provider, constraints);
                },
              ),
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
    final displayHeight = _calculateOptimalDisplayHeight(context, layout, screenHeight);
    final titleBarHeight = 80.0;
    final availableHeight = screenHeight - titleBarHeight;
    
    // 确保按钮区域有足够空间，至少占60%的可用高度
    final minButtonAreaHeight = availableHeight * 0.6;
    final adjustedDisplayHeight = math.min(displayHeight, availableHeight - minButtonAreaHeight);
    final buttonAreaHeight = availableHeight - adjustedDisplayHeight;
    
    return Column(
      children: [
        // 顶部标题栏 - 固定高度
        _buildTitleBar(context, provider),
        
        // 计算器显示屏 - 动态高度
        Container(
          height: adjustedDisplayHeight,
          child: CalculatorDisplay(
            state: provider.state,
            theme: provider.config.theme,
          ),
        ),
        
        // 按钮网格 - 剩余空间，使用Expanded确保不溢出
        Expanded(
          child: Container(
            height: buttonAreaHeight,
            padding: const EdgeInsets.all(8.0),
            child: CalculatorButtonGrid(),
          ),
        ),
      ],
    );
  }

  /// 计算最优显示屏高度
  double _calculateOptimalDisplayHeight(BuildContext context, CalculatorLayout layout, double screenHeight) {
    final theme = layout.buttons.isNotEmpty ? 
        Provider.of<CalculatorProvider>(context, listen: false).config.theme : null;
    
    // 如果主题指定了显示区高度比例，使用它
    if (theme?.displayHeight != null) {
      return screenHeight * theme!.displayHeight!;
    }
    
    // 基础显示高度
    double baseHeight = 80.0;
    
    // 根据布局复杂度调整，但限制最大高度
    final buttonCount = layout.buttons.length;
    final totalCells = layout.rows * layout.columns;
    final density = totalCells > 0 ? buttonCount / totalCells : 0.5;
    
    // 按钮越多，显示区域相对越小，但不能太小
    if (density > 0.8 || buttonCount > 25) {
      baseHeight = screenHeight * 0.12; // 高密度：12%
    } else if (density > 0.6 || buttonCount > 20) {
      baseHeight = screenHeight * 0.15;  // 中密度：15%
    } else {
      baseHeight = screenHeight * 0.2; // 低密度：20%
    }
    
    // 确保最小和最大值，为按钮区域预留更多空间
    return baseHeight.clamp(60.0, screenHeight * 0.25);
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

  /// 构建背景装饰
  BoxDecoration _buildBackgroundDecoration(CalculatorTheme theme) {
    return BoxDecoration(
      color: theme.backgroundGradient == null && theme.backgroundImage == null 
          ? _parseColor(theme.backgroundColor) 
          : null,
      gradient: theme.backgroundGradient != null 
          ? _buildGradient(theme.backgroundGradient!) 
          : null,
      image: theme.backgroundImage != null ? DecorationImage(
        image: NetworkImage(theme.backgroundImage!),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.3),
          BlendMode.darken,
        ),
      ) : null,
    );
  }

  /// 构建渐变色
  LinearGradient _buildGradient(List<String> gradientColors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors.map((color) => _parseColor(color)).toList(),
    );
  }

  /// 解析颜色字符串
  Color _parseColor(String colorString) {
    final cleanColor = colorString.replaceAll('#', '');
    
    if (cleanColor.length == 6) {
      return Color(int.parse('FF$cleanColor', radix: 16));
    } else if (cleanColor.length == 8) {
      return Color(int.parse(cleanColor, radix: 16));
    } else {
      return Colors.grey;
    }
  }
}

 