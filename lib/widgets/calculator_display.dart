import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import '../widgets/calculation_history_dialog.dart';
import 'dart:convert';
import 'dart:typed_data';

class CalculatorDisplay extends StatelessWidget {
  final CalculatorState state;
  final CalculatorTheme theme;
  final List<CalculationStep>? calculationHistory;

  const CalculatorDisplay({
    super.key,
    required this.state,
    required this.theme,
    this.calculationHistory,
  });

  @override
  Widget build(BuildContext context) {
    // 使用主题指定的显示区圆角或默认值
    final borderRadius = theme.displayBorderRadius ?? theme.buttonBorderRadius;
    
    return Container(
      width: theme.displayWidth != null 
          ? MediaQuery.of(context).size.width * theme.displayWidth!
          : double.infinity,
      padding: const EdgeInsets.all(16),
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
        image: _buildBackgroundImage(theme.backgroundImage),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用高度动态调整布局
          final availableHeight = constraints.maxHeight;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _buildEnhancedDisplayElements(availableHeight),
            ),
          );
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

  /// 构建增强的显示元素列表
  List<Widget> _buildEnhancedDisplayElements(double availableHeight) {
    List<Widget> elements = [];

    // 1. 顶部状态栏 - 显示内存状态、错误状态等
    elements.add(_buildStatusBar());

    // 2. 运算历史预览（最近一次计算）
    if (calculationHistory != null && calculationHistory!.isNotEmpty) {
      elements.add(_buildHistoryPreview());
    }

    // 3. 当前运算上下文显示
    if ((state.operator?.isNotEmpty ?? false) || (state.previousValue?.isNotEmpty ?? false)) {
      elements.add(_buildOperationContext());
    }

    // 4. 主显示屏
    elements.add(_buildMainDisplay());

    // 5. 多参数函数操作提示
    if (state.isInputtingFunction && state.currentFunction != null) {
      elements.add(_buildFunctionHint());
    }

    // 6. 底部辅助信息
    elements.add(_buildAuxiliaryInfo());

    return elements;
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：内存状态
          Row(
            children: [
              if (state.memory != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'M: ${_formatNumber(state.memory)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _parseColor(theme.displayTextColor).withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // 右侧：状态指示器
          Row(
            children: [
              if (state.isError)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ERR',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (state.isInputtingFunction)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'FN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建运算历史预览
  Widget _buildHistoryPreview() {
    final lastStep = calculationHistory!.last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _parseColor(theme.displayTextColor).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${lastStep.description}',
            style: TextStyle(
              fontSize: 9,
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${_formatNumber(lastStep.input)} → ${_formatNumber(lastStep.result)}',
            style: TextStyle(
              fontSize: 11,
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建运算上下文
  Widget _buildOperationContext() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        '${state.previousValue ?? ''} ${state.operator ?? ''} ${state.waitingForOperand ? '' : state.display}',
        style: TextStyle(
          fontSize: 14,
          color: _parseColor(theme.displayTextColor).withValues(alpha: 0.8),
          fontFamily: 'monospace',
          fontWeight: FontWeight.w300,
        ),
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建主显示屏
  Widget _buildMainDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        state.isInputtingFunction ? state.getFunctionDisplayText() : state.display,
        style: TextStyle(
          fontSize: state.isInputtingFunction ? 24 : 32,
          fontWeight: FontWeight.w300,
          color: _parseColor(theme.displayTextColor),
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.right,
        maxLines: state.isInputtingFunction ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建函数提示
  Widget _buildFunctionHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 12,
            color: Colors.blue,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _getFunctionHint(state.currentFunction!, state.functionParameters.length),
              style: TextStyle(
                fontSize: 10,
                color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建辅助信息
  Widget _buildAuxiliaryInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧：当前时间
          Text(
            _getCurrentTime(),
            style: TextStyle(
              fontSize: 9,
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.5),
            ),
          ),
          // 右侧：计算精度提示
          if (state.display.contains('.') && state.display.length > 10)
            Text(
              '高精度',
              style: TextStyle(
                fontSize: 9,
                color: _parseColor(theme.displayTextColor).withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  /// 格式化数字显示
  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    } else {
      String formatted = number.toStringAsFixed(6);
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }

  /// 获取当前时间
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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

  /// 构建背景图像
  DecorationImage? _buildBackgroundImage(String? backgroundImage) {
    if (backgroundImage == null) {
      return null;
    }

    // 过滤掉明显无效的URL格式
    if (backgroundImage.startsWith('url(') && backgroundImage.endsWith(')')) {
      // 这是CSS格式的URL，提取实际URL
      final url = backgroundImage.substring(4, backgroundImage.length - 1);
      if (url.startsWith('data:image/')) {
        try {
          final base64String = url.split(',')[1];
          final imageBytes = base64Decode(base64String);
          return DecorationImage(
            image: MemoryImage(imageBytes),
            fit: BoxFit.cover,
            opacity: 0.3,
          );
        } catch (e) {
          return null;
        }
      }
    }

    // 处理base64格式的图片
    if (backgroundImage.startsWith('data:image/')) {
      try {
        final base64String = backgroundImage.split(',')[1];
        final imageBytes = base64Decode(base64String);
        return DecorationImage(
          image: MemoryImage(imageBytes),
          fit: BoxFit.cover,
          opacity: 0.3,
        );
      } catch (e) {
        return null;
      }
    }

    return null;
  }
} 