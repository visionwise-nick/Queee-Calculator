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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用高度动态调整布局
          final availableHeight = constraints.maxHeight;
          final hasMultipleElements = (state.isInputtingFunction && state.currentFunction != null) ||
                                     ((state.operator?.isNotEmpty ?? false) || (state.previousValue?.isNotEmpty ?? false));
          
          // 如果空间不足，使用滚动视图
          if (availableHeight < 60 && hasMultipleElements) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: _buildDisplayElements(),
              ),
            );
          } else {
            // 使用Flexible确保不溢出
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _buildDisplayElements().map((child) => 
                child is Container ? Flexible(child: child) : child
              ).toList(),
            );
          }
        },
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

  /// 获取多参数函数的操作提示
  String _getFunctionHint(String functionName, int paramCount) {
    switch (functionName.toLowerCase()) {
      case 'pow':
        return paramCount == 1 ? '输入指数，然后按"="执行' : '按"="计算幂运算';
      case 'log':
        return paramCount == 1 ? '输入底数，然后按"="执行' : '按"="计算对数';
      case 'max':
      case 'min':
        return paramCount == 1 ? '输入更多数值，用","分隔' : '继续输入或按"="完成';
      case 'avg':
      case 'sum':
        return paramCount == 1 ? '输入更多数值，用","分隔' : '继续输入或按"="完成';
      case '汇率转换':
      case 'exchangerate':
        return paramCount == 1 ? '输入汇率，然后按"="执行' : '按"="计算转换结果';
      case '复利计算':
      case 'compoundinterest':
        if (paramCount == 1) return '输入年利率(%)，按","继续';
        if (paramCount == 2) return '输入年数，然后按"="执行';
        return '按"="计算复利';
      case '贷款计算':
      case 'loanpayment':
        if (paramCount == 1) return '输入年利率(%)，按","继续';
        if (paramCount == 2) return '输入贷款年数，然后按"="执行';
        return '按"="计算月供';
      case '投资回报':
      case 'investmentreturn':
        return paramCount == 1 ? '输入投资成本，然后按"="执行' : '按"="计算回报率';
      default:
        return paramCount == 1 ? '输入参数，用","分隔或按"="执行' : '继续输入或按"="完成';
    }
  }

  /// 构建显示元素列表
  List<Widget> _buildDisplayElements() {
    return [
      // 主显示屏
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 减少垂直padding
        child: Text(
          state.isInputtingFunction ? state.getFunctionDisplayText() : state.display,
          style: TextStyle(
            fontSize: state.isInputtingFunction ? 20 : 24, // 减小字体大小
            fontWeight: FontWeight.w300,
            color: _parseColor(theme.displayTextColor),
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.right,
          maxLines: state.isInputtingFunction ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      
      // 多参数函数操作提示
      if (state.isInputtingFunction && state.currentFunction != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), // 减少垂直padding
          child: Text(
            _getFunctionHint(state.currentFunction!, state.functionParameters.length),
            style: TextStyle(
              fontSize: 10, // 减小字体大小
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.right,
            maxLines: 1, // 限制为1行
            overflow: TextOverflow.ellipsis,
          ),
        ),
      
      // 状态显示
      if ((state.operator?.isNotEmpty ?? false) || (state.previousValue?.isNotEmpty ?? false))
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), // 减少垂直padding
          child: Text(
            '${state.previousValue ?? ''} ${state.operator ?? ''}',
            style: TextStyle(
              fontSize: 10, // 减小字体大小
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];
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