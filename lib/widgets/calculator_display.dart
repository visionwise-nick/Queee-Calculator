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
    // 使用主题指定的显示区圆角或默认值
    final borderRadius = theme.displayBorderRadius ?? theme.buttonBorderRadius;
    
    return Container(
      width: theme.displayWidth != null 
          ? MediaQuery.of(context).size.width * theme.displayWidth!
          : double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.displayBackgroundGradient == null && theme.backgroundImage == null 
            ? _parseColor(theme.displayBackgroundColor) 
            : null,
        gradient: theme.displayBackgroundGradient != null 
            ? _buildGradient(theme.displayBackgroundGradient!) 
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (theme.hasGlowEffect)
            BoxShadow(
              color: _parseColor(theme.shadowColor ?? theme.displayTextColor).withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
        image: theme.backgroundImage != null ? DecorationImage(
          image: NetworkImage(theme.backgroundImage!),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3),
            BlendMode.darken,
          ),
          onError: (exception, stackTrace) {
            print('Failed to load display background image: ${theme.backgroundImage}');
          },
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主显示屏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              state.isInputtingFunction ? state.getFunctionDisplayText() : state.display,
              style: TextStyle(
                fontSize: state.isInputtingFunction ? 24 : 30,
                fontWeight: FontWeight.w300,
                color: _parseColor(theme.displayTextColor),
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
              maxLines: state.isInputtingFunction ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 状态显示
          if ((state.operator?.isNotEmpty ?? false) || (state.previousValue?.isNotEmpty ?? false))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '${state.previousValue ?? ''} ${state.operator ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
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