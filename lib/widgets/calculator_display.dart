import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

class CalculatorDisplay extends StatelessWidget {
  final CalculatorState state;
  final CalculatorTheme theme;
  final Function(String)? onParameterInput;

  const CalculatorDisplay({
    super.key,
    required this.state,
    required this.theme,
    this.onParameterInput,
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
        image: _buildBackgroundImage(theme.backgroundImage),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用高度动态调整布局
          final availableHeight = constraints.maxHeight;
          final hasMultipleElements = (state.isInputtingFunction && state.currentFunction != null) ||
                                     ((state.operator?.isNotEmpty ?? false) || (state.previousValue?.isNotEmpty ?? false));
          
          // 如果正在输入多参数函数，显示多参数输入界面
          if (state.isInputtingFunction && state.currentFunction != null) {
            return _buildMultiParameterDisplay(context, constraints);
          }
          
          // 增强滚动支持，确保长表达式能正确显示
          if (availableHeight < 80 || hasMultipleElements) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: _buildDisplayElements(),
              ),
            );
          } else {
            // 使用Flexible确保不溢出，同时提供滚动能力
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: _buildDisplayElements(),
              ),
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
        if (paramCount == 0) return '第1步：输入底数（如输入2）';
        if (paramCount == 1) return '第2步：按","然后输入指数（如输入3）';
        return '第3步：按"="计算 2³ = 8';
      case 'log':
        if (paramCount == 0) return '第1步：输入真数（如输入100）';
        if (paramCount == 1) return '第2步：按","然后输入底数（如输入10）';
        return '第3步：按"="计算 log₁₀(100) = 2';
      case 'max':
      case '最大值':
        if (paramCount == 0) return '第1步：输入第1个数（如输入5）';
        if (paramCount == 1) return '第2步：按","输入第2个数（如输入3）';
        return '继续按","添加更多数，或按"="找最大值';
      case 'min':
      case '最小值':
        if (paramCount == 0) return '第1步：输入第1个数（如输入5）';
        if (paramCount == 1) return '第2步：按","输入第2个数（如输入3）';
        return '继续按","添加更多数，或按"="找最小值';
      case 'avg':
      case '平均值':
      case '平均数':
        if (paramCount == 0) return '第1步：输入第1个数（如输入10）';
        if (paramCount == 1) return '第2步：按","输入第2个数（如输入20）';
        return '继续按","添加更多数，或按"="计算平均值';
      case '标准差':
        if (paramCount == 0) return '第1步：输入第1个数据（如输入10）';
        if (paramCount == 1) return '第2步：按","输入第2个数据（如输入12）';
        return '继续按","添加更多数据，或按"="计算标准差';
      case '方差':
        if (paramCount == 0) return '第1步：输入第1个数据（如输入10）';
        if (paramCount == 1) return '第2步：按","输入第2个数据（如输入12）';
        return '继续按","添加更多数据，或按"="计算方差';
      case '汇率转换':
      case 'exchangerate':
        if (paramCount == 0) return '第1步：输入金额（如输入100）';
        if (paramCount == 1) return '第2步：按","输入汇率（如输入7.2）';
        return '第3步：按"="计算 100×7.2 = 720';
      case '复利计算':
      case 'compoundinterest':
        if (paramCount == 0) return '第1步：输入本金（如输入10000）';
        if (paramCount == 1) return '第2步：按","输入年利率%（如输入5）';
        if (paramCount == 2) return '第3步：按","输入年数（如输入10）';
        return '第4步：按"="计算复利结果';
      case '贷款计算':
      case 'loanpayment':
        if (paramCount == 0) return '第1步：输入贷款金额（如输入500000）';
        if (paramCount == 1) return '第2步：按","输入年利率%（如输入4.5）';
        if (paramCount == 2) return '第3步：按","输入贷款年数（如输入30）';
        return '第4步：按"="计算月供';
      case '投资回报':
      case 'investmentreturn':
        if (paramCount == 0) return '第1步：输入投资收益（如输入15000）';
        if (paramCount == 1) return '第2步：按","输入投资成本（如输入10000）';
        return '第3步：按"="计算回报率';
      default:
        if (paramCount == 0) return '第1步：输入第一个参数';
        if (paramCount == 1) return '第2步：按","输入下一个参数';
        return '继续输入参数，最后按"="执行计算';
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

  /// 构建背景图像
  DecorationImage? _buildBackgroundImage(String? backgroundImage) {
    if (backgroundImage == null) {
      return null;
    }

    // 过滤掉明显无效的URL格式
    if (backgroundImage.startsWith('url(') && backgroundImage.endsWith(')')) {
      // 这是CSS样式的url()格式，不是有效的图片URL
      print('跳过无效的CSS格式背景图片: $backgroundImage');
      return null;
    }

    if (backgroundImage.startsWith('data:image/')) {
      // 处理base64格式
      try {
        final base64Data = backgroundImage.split(',').last;
        final bytes = base64Decode(base64Data);
        return DecorationImage(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3),
            BlendMode.darken,
          ),
        );
      } catch (e) {
        print('Failed to decode base64 background image: $e');
        return null;
      }
    } else if (Uri.tryParse(backgroundImage)?.isAbsolute == true) {
      // 处理有效的URL格式
      return DecorationImage(
        image: NetworkImage(backgroundImage),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.3),
          BlendMode.darken,
        ),
        onError: (exception, stackTrace) {
          print('Failed to load display background image: $backgroundImage');
        },
      );
    } else {
      // 跳过无效格式
      print('跳过无效格式的背景图片: $backgroundImage');
      return null;
    }
  }

  /// 构建多参数输入显示界面
  Widget _buildMultiParameterDisplay(BuildContext context, BoxConstraints constraints) {
    final functionName = state.currentFunction!;
    final params = state.functionParameters;
    final currentInput = state.display;
    
    // 获取函数的参数配置
    final paramConfig = _getParameterConfig(functionName);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 函数标题和进度
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _parseColor(theme.displayTextColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  paramConfig['title'] ?? functionName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _parseColor(theme.displayTextColor),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  '参数 ${params.length + 1}/${paramConfig['paramNames'].length} ${_getStepIndicator(params.length, paramConfig['paramNames'].length)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 参数输入区域
          ...List.generate(paramConfig['paramNames'].length, (index) {
            final paramName = paramConfig['paramNames'][index];
            final paramUnit = paramConfig['paramUnits']?[index] ?? '';
            final isCurrentParam = index == params.length;
            final paramValue = index < params.length 
                ? _formatParameterValue(params[index])
                : (isCurrentParam ? currentInput : '');
            
            return GestureDetector(
              onTap: () {
                if (onParameterInput != null) {
                  onParameterInput!('param_$index');
                }
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentParam 
                      ? _parseColor(theme.displayTextColor).withValues(alpha: 0.1)
                      : _parseColor(theme.displayTextColor).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentParam 
                      ? Border.all(
                          color: _parseColor(theme.displayTextColor).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // 参数名称
                    Expanded(
                      flex: 2,
                      child: Text(
                        paramName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    
                    // 参数值
                    Expanded(
                      flex: 3,
                      child: Text(
                        paramValue.isEmpty ? '点击输入' : paramValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrentParam ? FontWeight.bold : FontWeight.normal,
                          color: paramValue.isEmpty 
                              ? _parseColor(theme.displayTextColor).withValues(alpha: 0.4)
                              : _parseColor(theme.displayTextColor),
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    
                    // 单位
                    if (paramUnit.isNotEmpty)
                      Container(
                        width: 30,
                        alignment: Alignment.centerRight,
                        child: Text(
                          paramUnit,
                          style: TextStyle(
                            fontSize: 10,
                            color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          
          // 计算结果预览（如果有足够参数）
          if (params.length >= (paramConfig['minParams'] ?? paramConfig['paramNames'].length))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _parseColor(theme.displayTextColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _parseColor(theme.displayTextColor).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '预览结果',
                      style: TextStyle(
                        fontSize: 12,
                        color: _parseColor(theme.displayTextColor).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Text(
                    _calculatePreview(functionName, params),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _parseColor(theme.displayTextColor),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          
          // 操作提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _getFunctionHint(functionName, params.length),
              style: TextStyle(
                fontSize: 10,
                color: _parseColor(theme.displayTextColor).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取步骤指示器
  String _getStepIndicator(int current, int total) {
    List<String> indicators = [];
    for (int i = 0; i < total; i++) {
      if (i < current) {
        indicators.add('●'); // 已完成
      } else if (i == current) {
        indicators.add('◐'); // 当前进行中
      } else {
        indicators.add('○'); // 未完成
      }
    }
    return indicators.join(' ');
  }

  /// 获取参数配置
  Map<String, dynamic> _getParameterConfig(String functionName) {
    switch (functionName.toLowerCase()) {
      // 基础数学函数
      case 'pow':
        return {
          'title': '幂运算 (X^Y)',
          'paramNames': ['底数', '指数'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case 'log':
        return {
          'title': '对数运算',
          'paramNames': ['真数', '底数'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case 'max':
      case '最大值':
        return {
          'title': '最大值',
          'paramNames': ['数值1', '数值2', '数值3', '数值4', '数值5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case 'min':
      case '最小值':
        return {
          'title': '最小值',
          'paramNames': ['数值1', '数值2', '数值3', '数值4', '数值5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case 'avg':
      case 'mean':
      case '平均值':
      case '平均数':
        return {
          'title': '平均值',
          'paramNames': ['数值1', '数值2', '数值3', '数值4', '数值5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case '标准差':
        return {
          'title': '标准差',
          'paramNames': ['数据1', '数据2', '数据3', '数据4', '数据5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case '方差':
        return {
          'title': '方差',
          'paramNames': ['数据1', '数据2', '数据3', '数据4', '数据5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case 'sum':
      case '求和':
        return {
          'title': '求和',
          'paramNames': ['数值1', '数值2', '数值3', '数值4', '数值5'],
          'paramUnits': ['', '', '', '', ''],
          'minParams': 2,
        };
        
      case 'gcd':
      case '最大公约数':
        return {
          'title': '最大公约数',
          'paramNames': ['整数1', '整数2'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case 'lcm':
      case '最小公倍数':
        return {
          'title': '最小公倍数',
          'paramNames': ['整数1', '整数2'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case '组合':
        return {
          'title': '组合数 C(n,r)',
          'paramNames': ['总数n', '选择数r'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case '排列':
        return {
          'title': '排列数 P(n,r)',
          'paramNames': ['总数n', '选择数r'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      // 金融计算函数  
      case '复利计算':
      case 'compound':
      case 'compoundinterest':
        return {
          'title': '复利计算',
          'paramNames': ['本金', '年利率', '投资年数'],
          'paramUnits': ['元', '%', '年'],
          'minParams': 3,
        };
        
      case '贷款计算':
      case 'loan':
      case 'loanpayment':
        return {
          'title': '贷款月供计算',
          'paramNames': ['贷款金额', '年利率', '贷款年数'],
          'paramUnits': ['元', '%', '年'],
          'minParams': 3,
        };
        
      case '投资回报':
      case 'roi':
      case 'investmentreturn':
        return {
          'title': '投资回报率',
          'paramNames': ['投资收益', '投资成本'],
          'paramUnits': ['元', '元'],
          'minParams': 2,
        };
        
      case '汇率转换':
      case 'currency':
      case 'exchange':
      case 'exchangerate':
        return {
          'title': '汇率转换',
          'paramNames': ['金额', '汇率'],
          'paramUnits': ['', ''],
          'minParams': 2,
        };
        
      case '抵押贷款':
      case 'mortgage':
        return {
          'title': '抵押贷款计算',
          'paramNames': ['房价', '首付比例', '贷款年数', '年利率'],
          'paramUnits': ['元', '%', '年', '%'],
          'minParams': 4,
        };
        
      case '年金计算':
      case 'annuity':
        return {
          'title': '年金计算',
          'paramNames': ['每期支付', '年利率', '期数'],
          'paramUnits': ['元', '%', '期'],
          'minParams': 3,
        };
        
              case '通胀调整':
        case 'inflation':
          return {
            'title': '通胀调整',
            'paramNames': ['当前金额', '通胀率', '年数'],
            'paramUnits': ['元', '%', '年'],
            'minParams': 3,
          };
          
        case '净现值':
        case 'npv':
          return {
            'title': '净现值计算',
            'paramNames': ['折现率', '第1期现金流', '第2期现金流', '第3期现金流'],
            'paramUnits': ['%', '元', '元', '元'],
            'minParams': 2,
          };
          
        case '内部收益率':
        case 'irr':
          return {
            'title': '内部收益率',
            'paramNames': ['初始投资', '第1期现金流', '第2期现金流', '第3期现金流'],
            'paramUnits': ['元', '元', '元', '元'],
            'minParams': 2,
          };
          
        case '债券价格':
        case 'bond':
          return {
            'title': '债券价格计算',
            'paramNames': ['面值', '票面利率', '市场利率', '年数'],
            'paramUnits': ['元', '%', '%', '年'],
            'minParams': 4,
          };
          
        case '期权价值':
        case 'option':
          return {
            'title': '期权价值计算',
            'paramNames': ['标的价格', '执行价格', '无风险利率', '波动率', '到期时间'],
            'paramUnits': ['元', '元', '%', '%', '年'],
            'minParams': 5,
          };
          
        default:
        return {
          'title': functionName,
          'paramNames': ['参数1', '参数2', '参数3'],
          'paramUnits': ['', '', ''],
          'minParams': 2,
        };
    }
  }

  /// 格式化参数值显示
  String _formatParameterValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  /// 格式化结果显示
  String _formatResult(double value) {
    if (value.isInfinite) return '∞';
    if (value.isNaN) return 'NaN';
    
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  /// 计算最大公约数
  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// 计算阶乘
  int _factorial(int n) {
    if (n < 0) return 0;
    if (n == 0 || n == 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  /// 计算预览结果
  String _calculatePreview(String functionName, List<double> params) {
    try {
      switch (functionName.toLowerCase()) {
        // 基础数学函数预览
        case 'pow':
          if (params.length >= 2) {
            double result = math.pow(params[0], params[1]).toDouble();
            return '${params[0]}^${params[1]} = ${_formatResult(result)}';
          }
          break;
          
        case 'log':
          if (params.length >= 2) {
            double result = math.log(params[0]) / math.log(params[1]);
            return 'log${params[1]}(${params[0]}) = ${_formatResult(result)}';
          }
          break;
          
        case 'max':
        case '最大值':
          if (params.length >= 2) {
            double result = params.reduce(math.max);
            return '最大值 = ${_formatResult(result)}';
          }
          break;
          
        case 'min':
        case '最小值':
          if (params.length >= 2) {
            double result = params.reduce(math.min);
            return '最小值 = ${_formatResult(result)}';
          }
          break;
          
        case 'avg':
        case 'mean':
        case '平均值':
        case '平均数':
          if (params.length >= 2) {
            double result = params.reduce((a, b) => a + b) / params.length;
            return '平均值 = ${_formatResult(result)}';
          }
          break;
          
        case '标准差':
          if (params.length >= 2) {
            double mean = params.reduce((a, b) => a + b) / params.length;
            double variance = params.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / params.length;
            double result = math.sqrt(variance);
            return '标准差 = ${_formatResult(result)}';
          }
          break;
          
        case '方差':
          if (params.length >= 2) {
            double mean = params.reduce((a, b) => a + b) / params.length;
            double result = params.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / params.length;
            return '方差 = ${_formatResult(result)}';
          }
          break;
          
        case 'sum':
        case '求和':
          if (params.length >= 2) {
            double result = params.reduce((a, b) => a + b);
            return '求和 = ${_formatResult(result)}';
          }
          break;
          
        case 'gcd':
        case '最大公约数':
          if (params.length >= 2) {
            int result = _gcd(params[0].toInt(), params[1].toInt());
            return 'GCD = $result';
          }
          break;
          
        case 'lcm':
        case '最小公倍数':
          if (params.length >= 2) {
            int a = params[0].toInt();
            int b = params[1].toInt();
            int result = (a * b / _gcd(a, b)).toInt();
            return 'LCM = $result';
          }
          break;
          
        case '组合':
          if (params.length >= 2) {
            int n = params[0].toInt();
            int r = params[1].toInt();
            if (r <= n && r >= 0) {
              int result = (_factorial(n) / (_factorial(r) * _factorial(n - r))).toInt();
              return 'C($n,$r) = $result';
            }
          }
          break;
          
        case '排列':
          if (params.length >= 2) {
            int n = params[0].toInt();
            int r = params[1].toInt();
            if (r <= n && r >= 0) {
              int result = (_factorial(n) / _factorial(n - r)).toInt();
              return 'P($n,$r) = $result';
            }
          }
          break;
          
        // 金融计算函数预览
        case '复利计算':
        case 'compound':
        case 'compoundinterest':
          if (params.length >= 3) {
            double principal = params[0];
            double rate = params[1] / 100;
            double years = params[2];
            double result = principal * math.pow(1 + rate, years);
            return '${result.toStringAsFixed(2)}元';
          }
          break;
          
        case '贷款计算':
        case 'loan':
        case 'loanpayment':
          if (params.length >= 3) {
            double principal = params[0];
            double annualRate = params[1] / 100;
            double years = params[2];
            double monthlyRate = annualRate / 12;
            double months = years * 12;
            
            if (monthlyRate == 0) {
              return '${(principal / months).toStringAsFixed(2)}元/月';
            }
            
            double result = principal * (monthlyRate * math.pow(1 + monthlyRate, months)) / 
                           (math.pow(1 + monthlyRate, months) - 1);
            return '${result.toStringAsFixed(2)}元/月';
          }
          break;
          
        case '投资回报':
        case 'roi':
        case 'investmentreturn':
          if (params.length >= 2) {
            double profit = params[0];
            double cost = params[1];
            if (cost != 0) {
              double result = (profit / cost) * 100;
              return '${result.toStringAsFixed(2)}%';
            }
          }
          break;
          
        case '汇率转换':
        case 'currency':
        case 'exchange':
        case 'exchangerate':
          if (params.length >= 2) {
            double result = params[0] * params[1];
            return result.toStringAsFixed(2);
          }
          break;
          
        case '抵押贷款':
        case 'mortgage':
          if (params.length >= 4) {
            double housePrice = params[0];
            double downPaymentRate = params[1] / 100;
            double years = params[2];
            double annualRate = params[3] / 100;
            
            double loanAmount = housePrice * (1 - downPaymentRate);
            double monthlyRate = annualRate / 12;
            double months = years * 12;
            
            if (monthlyRate == 0) {
              return '${(loanAmount / months).toStringAsFixed(2)}元/月';
            }
            
            double result = loanAmount * (monthlyRate * math.pow(1 + monthlyRate, months)) / 
                           (math.pow(1 + monthlyRate, months) - 1);
            return '${result.toStringAsFixed(2)}元/月';
          }
          break;
          
        case '年金计算':
        case 'annuity':
          if (params.length >= 3) {
            double payment = params[0];
            double annualRate = params[1] / 100;
            double periods = params[2];
            
            if (annualRate == 0) {
              return '${(payment * periods).toStringAsFixed(2)}元';
            }
            
            double result = payment * ((1 - math.pow(1 + annualRate, -periods)) / annualRate);
            return '${result.toStringAsFixed(2)}元';
          }
          break;
          
        case '通胀调整':
        case 'inflation':
          if (params.length >= 3) {
            double currentAmount = params[0];
            double inflationRate = params[1] / 100;
            double years = params[2];
            
            double result = currentAmount * math.pow(1 + inflationRate, years);
            return '${result.toStringAsFixed(2)}元';
          }
          break;
          
        case '净现值':
        case 'npv':
          if (params.length >= 2) {
            double discountRate = params[0] / 100;
            double npv = 0;
            
            for (int i = 1; i < params.length; i++) {
              npv += params[i] / math.pow(1 + discountRate, i);
            }
            
            return '${npv.toStringAsFixed(2)}元';
          }
          break;
          
        case '债券价格':
        case 'bond':
          if (params.length >= 4) {
            double faceValue = params[0];
            double couponRate = params[1] / 100;
            double marketRate = params[2] / 100;
            double years = params[3];
            
            double couponPayment = faceValue * couponRate;
            double presentValueOfCoupons = 0;
            
            for (int i = 1; i <= years; i++) {
              presentValueOfCoupons += couponPayment / math.pow(1 + marketRate, i);
            }
            
            double presentValueOfFace = faceValue / math.pow(1 + marketRate, years);
            double result = presentValueOfCoupons + presentValueOfFace;
            
            return '${result.toStringAsFixed(2)}元';
          }
          break;
      }
      return '计算中...';
    } catch (e) {
      return '错误';
    }
  }
} 