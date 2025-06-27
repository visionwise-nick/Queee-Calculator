import 'dart:math' as math;

/// 计算器操作类型 - 简化版本
enum CalculatorActionType {
  input,      // 输入数字
  operator,   // 运算符 (+, -, *, /)
  equals,     // 等号
  clear,      // 清除
  clearAll,   // 全部清除
  backspace,  // 退格
  decimal,    // 小数点
  negate,     // 正负号
  expression, // 表达式计算 - 新的通用类型
}

/// 计算器操作定义
class CalculatorAction {
  final CalculatorActionType type;
  final String? value;
  final String? expression; // 新增：数学表达式

  const CalculatorAction({
    required this.type,
    this.value,
    this.expression,
  });

  factory CalculatorAction.fromJson(Map<String, dynamic> json) {
    return CalculatorAction(
      type: CalculatorActionType.values.firstWhere(
        (e) => e.toString() == 'CalculatorActionType.${json['type']}',
        orElse: () => CalculatorActionType.input,
      ),
      value: json['value']?.toString(),
      expression: json['expression']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      if (value != null) 'value': value,
      if (expression != null) 'expression': expression,
    };
  }
}

/// 计算器状态
class CalculatorState {
  final String display;
  final String? previousValue;
  final String? operator;
  final bool waitingForOperand;
  final double memory;
  final bool isError;

  const CalculatorState({
    this.display = '0',
    this.previousValue,
    this.operator,
    this.waitingForOperand = false,
    this.memory = 0,
    this.isError = false,
  });

  CalculatorState copyWith({
    String? display,
    String? previousValue,
    String? operator,
    bool? waitingForOperand,
    double? memory,
    bool? isError,
    bool clearPreviousValue = false,
    bool clearOperator = false,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      previousValue: clearPreviousValue ? null : (previousValue ?? this.previousValue),
      operator: clearOperator ? null : (operator ?? this.operator),
      waitingForOperand: waitingForOperand ?? this.waitingForOperand,
      memory: memory ?? this.memory,
      isError: isError ?? this.isError,
    );
  }
}

/// 增强的科学计算器引擎
class CalculatorEngine {
  CalculatorState _state = const CalculatorState();

  CalculatorState get state => _state;

  /// 执行计算器操作
  CalculatorState execute(CalculatorAction action) {
    try {
      switch (action.type) {
        case CalculatorActionType.input:
          return _handleInput(action.value!);
        case CalculatorActionType.operator:
          return _handleOperator(action.value!);
        case CalculatorActionType.equals:
          return _handleEquals();
        case CalculatorActionType.clear:
          return _handleClear();
        case CalculatorActionType.clearAll:
          return _handleClearAll();
        case CalculatorActionType.backspace:
          return _handleBackspace();
        case CalculatorActionType.decimal:
          return _handleDecimal();
        case CalculatorActionType.negate:
          return _handleNegate();
        case CalculatorActionType.expression:
          return _handleExpression(action.expression!);
      }
    } catch (e) {
      print('❌ 计算器错误：$e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  CalculatorState _handleInput(String digit) {
    if (_state.isError) {
      _state = const CalculatorState();
    }

    if (_state.waitingForOperand) {
      _state = _state.copyWith(
        display: digit,
        waitingForOperand: false,
      );
    } else {
      String newDisplay = _state.display == '0' ? digit : _state.display + digit;
      if (newDisplay.length <= 15) { // 增加显示位数
        _state = _state.copyWith(display: newDisplay);
      }
    }
    return _state;
  }

  CalculatorState _handleOperator(String operator) {
    if (_state.isError) return _state;

    if (_state.previousValue == null) {
      _state = _state.copyWith(
        previousValue: _state.display,
        operator: operator,
        waitingForOperand: true,
      );
    } else if (!_state.waitingForOperand) {
      String? result = _calculate();
      if (result != null) {
        _state = _state.copyWith(
          display: result,
          previousValue: result,
          operator: operator,
          waitingForOperand: true,
        );
      }
    } else {
      _state = _state.copyWith(operator: operator);
    }
    return _state;
  }

  CalculatorState _handleEquals() {
    if (_state.isError || _state.previousValue == null || _state.operator == null) {
      return _state;
    }

    String? result = _calculate();
    if (result != null) {
      _state = _state.copyWith(
        display: result,
        waitingForOperand: true,
        clearPreviousValue: true,
        clearOperator: true,
      );
    }
    return _state;
  }

  String? _calculate() {
    if (_state.previousValue == null || _state.operator == null) return null;

    double prev = double.parse(_state.previousValue!);
    double current = double.parse(_state.display);
    double result;

    switch (_state.operator) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '*':
        result = prev * current;
        break;
      case '/':
        if (current == 0) throw Exception('Division by zero');
        result = prev / current;
        break;
      default:
        return null;
    }

    return _formatResult(result);
  }

  String _formatResult(double result) {
    // 处理特殊值
    if (result.isNaN) return 'Error';
    if (result.isInfinite) return result.isNegative ? '-∞' : '∞';
    
    // 处理极大或极小的数字
    if (result.abs() > 1e10 || (result.abs() < 1e-6 && result != 0)) {
      return result.toStringAsExponential(6);
    }
    
    // 普通数字格式化
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      String formatted = result.toStringAsFixed(10);
      // 移除尾部的0
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }

  CalculatorState _handleClear() {
    return _state.copyWith(display: '0');
  }

  CalculatorState _handleClearAll() {
    _state = _state.copyWith(
      display: '0',
      waitingForOperand: false,
      isError: false,
      clearPreviousValue: true,
      clearOperator: true,
    );
    return _state;
  }

  CalculatorState _handleBackspace() {
    if (_state.isError || _state.waitingForOperand) return _state;

    String newDisplay = _state.display.length > 1 
      ? _state.display.substring(0, _state.display.length - 1)
      : '0';
    
    _state = _state.copyWith(display: newDisplay);
    return _state;
  }

  CalculatorState _handleDecimal() {
    if (_state.isError) {
      _state = const CalculatorState();
    }

    if (_state.waitingForOperand) {
      _state = _state.copyWith(
        display: '0.',
        waitingForOperand: false,
      );
    } else if (!_state.display.contains('.')) {
      _state = _state.copyWith(display: _state.display + '.');
    }
    return _state;
  }

  CalculatorState _handleNegate() {
    if (_state.isError) return _state;
    
    double value = double.parse(_state.display);
    _state = _state.copyWith(display: _formatResult(-value));
    return _state;
  }

  /// 增强的表达式处理器 - 支持完整的科学计算
  CalculatorState _handleExpression(String expression) {
    if (_state.isError) return _state;
    
    try {
      double currentValue = double.parse(_state.display);
      print('🔢 表达式计算：当前值=$currentValue, 表达式=$expression');
      
      // 计算表达式结果
      double result = _evaluateScientificExpression(expression, currentValue);
      print('🔢 计算结果：$result');
      
      _state = _state.copyWith(
        display: _formatResult(result),
        waitingForOperand: true,
      );
      return _state;
    } catch (e) {
      print('❌ 表达式计算错误：$e');
      _state = _state.copyWith(display: 'Error', isError: true);
      return _state;
    }
  }

  /// 科学计算表达式解析器
  double _evaluateScientificExpression(String expression, double x) {
    // 替换变量
    String processed = expression
        .replaceAll('x', x.toString())
        .replaceAll('input', x.toString())
        .replaceAll('value', x.toString());

    print('🔧 处理后的表达式：$processed');
    
    // 直接使用数学函数
    switch (expression.toLowerCase()) {
      // 三角函数 (弧度)
      case 'sin(x)':
        return math.sin(x);
      case 'cos(x)':
        return math.cos(x);
      case 'tan(x)':
        return math.tan(x);
      case 'asin(x)':
        return math.asin(x);
      case 'acos(x)':
        return math.acos(x);
      case 'atan(x)':
        return math.atan(x);
      
      // 双曲函数
      case 'sinh(x)':
        return (math.exp(x) - math.exp(-x)) / 2;
      case 'cosh(x)':
        return (math.exp(x) + math.exp(-x)) / 2;
      case 'tanh(x)':
        return (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x));
      
      // 对数函数
      case 'log(x)':
      case 'ln(x)':
        return math.log(x);
      case 'log10(x)':
        return math.log(x) / math.ln10;
      case 'log2(x)':
        return math.log(x) / math.log(2);
      
      // 指数函数
      case 'exp(x)':
      case 'e^x':
        return math.exp(x);
      
      // 幂函数
      case 'x*x':
      case 'x^2':
        return x * x;
      case 'pow(x,3)':
      case 'x^3':
        return x * x * x;
      case 'pow(x,4)':
      case 'x^4':
        return math.pow(x, 4).toDouble();
      case 'pow(x,5)':
      case 'x^5':
        return math.pow(x, 5).toDouble();
      case 'pow(2,x)':
      case '2^x':
        return math.pow(2, x).toDouble();
      case 'pow(10,x)':
      case '10^x':
        return math.pow(10, x).toDouble();
      
      // 根号函数
      case 'sqrt(x)':
        return math.sqrt(x);
      case 'pow(x,1/3)':
      case 'cbrt(x)':
        return math.pow(x, 1/3).toDouble();
      
      // 其他函数
      case '1/x':
        if (x == 0) throw Exception('Division by zero');
        return 1 / x;
      case 'abs(x)':
        return x.abs();
      case '1/sqrt(x)':
        if (x <= 0) throw Exception('Invalid input for 1/sqrt(x)');
        return 1 / math.sqrt(x);
      
      // 金融/百分比计算
      case 'x*0.15':
        return x * 0.15;
      case 'x*0.20':
        return x * 0.20;
      case 'x*0.085':
        return x * 0.085;
      case 'x*1.13':
        return x * 1.13;
      case 'x*0.7':
        return x * 0.7;
      case 'x*2':
        return x * 2;
      
      // 单位转换
      case 'x*9/5+32':
        return x * 9 / 5 + 32; // 摄氏度转华氏度
      case '(x-32)*5/9':
        return (x - 32) * 5 / 9; // 华氏度转摄氏度
      case 'x*2.54':
        return x * 2.54; // 英寸转厘米
      case 'x/2.54':
        return x / 2.54; // 厘米转英寸
      case 'x*10.764':
        return x * 10.764; // 平方米转平方英尺
      case 'x/10.764':
        return x / 10.764; // 平方英尺转平方米
      
      // 随机数生成
      case 'random()':
      case 'rand()':
        return math.Random().nextDouble() * x;
      
      // 阶乘 (简化版本，只支持小整数)
      case 'x!':
      case 'factorial(x)':
        if (x < 0 || x != x.toInt() || x > 20) {
          throw Exception('Factorial only supports integers 0-20');
        }
        return _factorial(x.toInt()).toDouble();
    }
    
    // 如果没有匹配的函数，尝试解析为一般表达式
    return _parseGeneralExpression(processed);
  }

  /// 计算阶乘
  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  /// 解析一般数学表达式 (简化版)
  double _parseGeneralExpression(String expression) {
    try {
      // 简单表达式计算
      return _evaluateSimpleExpression(expression);
    } catch (e) {
      print('⚠️ 表达式解析失败：$e');
      throw Exception('无法计算表达式');
    }
  }

  /// 简单表达式计算（回退方案）
  double _evaluateSimpleExpression(String expression) {
    // 处理基本的算术运算
    expression = expression.replaceAll(' ', '');
    
    // 乘法
    if (expression.contains('*')) {
      var parts = expression.split('*');
      if (parts.length == 2) {
        return double.parse(parts[0]) * double.parse(parts[1]);
      }
    }
    
    // 除法
    if (expression.contains('/')) {
      var parts = expression.split('/');
      if (parts.length == 2) {
        double divisor = double.parse(parts[1]);
        if (divisor == 0) throw Exception('Division by zero');
        return double.parse(parts[0]) / divisor;
      }
    }
    
    // 加法
    if (expression.contains('+')) {
      var parts = expression.split('+');
      if (parts.length == 2) {
        return double.parse(parts[0]) + double.parse(parts[1]);
      }
    }
    
    // 减法
    if (expression.contains('-') && !expression.startsWith('-')) {
      var parts = expression.split('-');
      if (parts.length == 2) {
        return double.parse(parts[0]) - double.parse(parts[1]);
      }
    }
    
    // 直接解析数字
    return double.parse(expression);
  }

  /// 重置计算器状态
  void reset() {
    _state = const CalculatorState();
  }
} 