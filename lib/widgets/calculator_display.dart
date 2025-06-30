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
          // 函数标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              paramConfig['title'] ?? functionName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _parseColor(theme.displayTextColor),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
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

  /// 获取参数配置
  Map<String, dynamic> _getParameterConfig(String functionName) {
    switch (functionName.toLowerCase()) {
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

  /// 计算预览结果
  String _calculatePreview(String functionName, List<double> params) {
    try {
      switch (functionName.toLowerCase()) {
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