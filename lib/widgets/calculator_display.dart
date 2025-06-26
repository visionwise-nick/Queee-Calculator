import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';

class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final theme = provider.config.theme;
        final state = provider.state;
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _parseColor(theme.displayBackgroundColor),
            borderRadius: BorderRadius.circular(theme.buttonBorderRadius * 2),
            boxShadow: theme.hasGlowEffect
                ? [
                    BoxShadow(
                      color: _parseColor(theme.shadowColor ?? '#ffffff').withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 操作历史显示
              if (state.previousValue != null && state.operator != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${state.previousValue} ${_formatOperator(state.operator!)}',
                    style: TextStyle(
                      fontSize: 20,
                                             color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
                      fontFamily: theme.fontFamily,
                    ),
                  ),
                ),
              
              // 主显示区域
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  state.display,
                  style: TextStyle(
                    fontSize: _calculateFontSize(state.display),
                    fontWeight: FontWeight.w300,
                    color: state.isError
                        ? Colors.red
                        : _parseColor(theme.displayTextColor),
                    fontFamily: theme.fontFamily,
                  ),
                ),
              ),
              
              // 状态指示器
              if (state.memory != 0 || state.base != 'decimal')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (state.memory != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                                                         color: _parseColor(theme.operatorButtonColor).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'M',
                            style: TextStyle(
                              fontSize: 12,
                              color: _parseColor(theme.displayTextColor),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      if (state.base != 'decimal')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                                                         color: _parseColor(theme.secondaryButtonColor).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.base.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _parseColor(theme.displayTextColor),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 解析颜色字符串
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

  /// 格式化运算符显示
  String _formatOperator(String operator) {
    switch (operator) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return operator;
    }
  }

  /// 计算字体大小（根据内容长度动态调整）
  double _calculateFontSize(String text) {
    if (text.length <= 6) {
      return 56;
    } else if (text.length <= 8) {
      return 48;
    } else if (text.length <= 10) {
      return 40;
    } else {
      return 32;
    }
  }
} 