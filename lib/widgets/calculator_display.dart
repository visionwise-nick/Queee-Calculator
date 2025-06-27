import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';

class CalculatorDisplay extends StatelessWidget {
  final CalculatorState state;
  final CalculatorTheme theme;

  const CalculatorDisplay({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _parseColor(theme.displayBackgroundColor),
        borderRadius: BorderRadius.circular(theme.buttonBorderRadius),
        boxShadow: [
          if (theme.hasGlowEffect)
            BoxShadow(
              color: _parseColor(theme.shadowColor ?? theme.displayTextColor).withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 主显示屏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              state.display,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: state.isError
                    ? Colors.red
                    : _parseColor(theme.displayTextColor),
                // fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 状态信息（简化版）
          if (state.memory != 0 || state.previousValue != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 内存指示器
                  if (state.memory != 0)
                    Text(
                      'M',
                      style: TextStyle(
                        fontSize: 14,
                        color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
                      ),
                    ),
                  
                  // 操作指示器
                  if (state.previousValue != null && state.operator != null)
                    Text(
                      '${state.previousValue} ${state.operator}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _parseColor(theme.displayTextColor).withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
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
      return Colors.white;
    }
  }
} 