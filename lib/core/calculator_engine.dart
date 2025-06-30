import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';
import '../widgets/calculation_history_dialog.dart';

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
  multiParamFunction, // 多参数函数
  parameterSeparator, // 参数分隔符 (逗号)
  functionExecute,    // 执行函数
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
    final actionType = _parseActionType(json['type']?.toString());
    String? expression = json['expression']?.toString();
    
    // 为特殊类型自动设置表达式
    if (expression == null) {
      final typeString = json['type']?.toString().toLowerCase();
      if (typeString == 'percentage' || typeString == 'percent') {
        expression = 'x*0.01';
      }
    }
    
    return CalculatorAction(
      type: actionType,
      value: json['value']?.toString(),
      expression: expression,
    );
  }

  static CalculatorActionType _parseActionType(String? typeString) {
    if (typeString == null) return CalculatorActionType.input;
    
    // 处理不同的类型字符串格式
    final cleanType = typeString.toLowerCase().replaceAll('calculatoractiontype.', '');
    print('🔍 解析action类型: $typeString -> $cleanType');
    
    switch (cleanType) {
      case 'input':
        return CalculatorActionType.input;
      case 'operator':
        return CalculatorActionType.operator;
      case 'equals':
        return CalculatorActionType.equals;
      case 'clear':
        return CalculatorActionType.clear;
      case 'clearall':
        return CalculatorActionType.clearAll;
      case 'backspace':
        return CalculatorActionType.backspace;
      case 'decimal':
        return CalculatorActionType.decimal;
      case 'negate':
        return CalculatorActionType.negate;
      case 'expression':
        return CalculatorActionType.expression;
      case 'multiparamfunction':
        return CalculatorActionType.multiParamFunction;
      case 'parameterseparator':
        return CalculatorActionType.parameterSeparator;
      case 'functionexecute':
        return CalculatorActionType.functionExecute;
      // 处理特殊的类型别名
      case 'percentage':
      case 'percent':
        // 百分比按钮应该是表达式类型，表达式为 x*0.01
        return CalculatorActionType.expression;
      case 'memory':
      case 'memoryrecall':
      case 'memoryclear':
      case 'memorystore':
        // 内存相关功能暂时当作表达式处理
        return CalculatorActionType.expression;
      default:
        print('⚠️ 未知的action类型: $typeString，使用默认input类型');
        return CalculatorActionType.input;
    }
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
  
  // 新增：多参数函数支持
  final String? currentFunction; // 当前正在输入的函数名
  final List<double> functionParameters; // 函数参数列表
  final int currentParameterIndex; // 当前参数索引
  final bool isInputtingFunction; // 是否正在输入函数参数

  const CalculatorState({
    this.display = '0',
    this.previousValue,
    this.operator,
    this.waitingForOperand = false,
    this.memory = 0,
    this.isError = false,
    this.currentFunction,
    this.functionParameters = const [],
    this.currentParameterIndex = 0,
    this.isInputtingFunction = false,
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
    String? currentFunction,
    List<double>? functionParameters,
    int? currentParameterIndex,
    bool? isInputtingFunction,
    bool clearFunction = false,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      previousValue: clearPreviousValue ? null : (previousValue ?? this.previousValue),
      operator: clearOperator ? null : (operator ?? this.operator),
      waitingForOperand: waitingForOperand ?? this.waitingForOperand,
      memory: memory ?? this.memory,
      isError: isError ?? this.isError,
      currentFunction: clearFunction ? null : (currentFunction ?? this.currentFunction),
      functionParameters: functionParameters ?? this.functionParameters,
      currentParameterIndex: currentParameterIndex ?? this.currentParameterIndex,
      isInputtingFunction: isInputtingFunction ?? this.isInputtingFunction,
    );
  }
  
  /// 获取当前函数的显示文本
  String getFunctionDisplayText() {
    if (currentFunction == null || !isInputtingFunction) return display;
    
    String params = functionParameters.map((p) => _formatParameter(p)).join(', ');
    if (functionParameters.length < currentParameterIndex + 1) {
      params += params.isEmpty ? display : ', $display';
    }
    
    return '$currentFunction($params)';
  }
  
  String _formatParameter(double param) {
    if (param == param.toInt()) {
      return param.toInt().toString();
    } else {
      return param.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }
}

/// 增强的科学计算器引擎
class CalculatorEngine {
  CalculatorState _state = const CalculatorState();
  final List<CalculationStep> _calculationHistory = [];

  CalculatorState get state => _state;
  List<CalculationStep> get calculationHistory => List.unmodifiable(_calculationHistory);

  /// 执行计算器操作
  CalculatorState execute(CalculatorAction action) {
    print('🔍 执行计算器操作: type=${action.type}, value=${action.value}, expression=${action.expression}');
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
        case CalculatorActionType.multiParamFunction:
          return _handleMultiParamFunction(action.value!);
        case CalculatorActionType.parameterSeparator:
          return _handleParameterSeparator();
        case CalculatorActionType.functionExecute:
          return _handleFunctionExecute();
      }
    } catch (e) {
      print('❌ 计算器错误：$e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  CalculatorState _handleInput(String digit) {
    print('🔍 处理输入: $digit, 当前状态: 错误=${_state.isError}, 等待操作数=${_state.waitingForOperand}, 多参数函数=${_state.isInputtingFunction}');
    
    if (_state.isError) {
      print('🔧 从错误状态恢复');
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
    
    print('🔍 输入处理后显示: ${_state.display}');
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
        if (current == 0) {
          _state = _state.copyWith(display: 'Error', isError: true);
          return 'Error';
        }
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
    // 如果正在输入多参数函数，清除函数状态
    if (_state.isInputtingFunction) {
      _state = _state.copyWith(
        display: '0',
        waitingForOperand: false,
        clearFunction: true,
        functionParameters: [],
        currentParameterIndex: 0,
        isInputtingFunction: false,
      );
    } else {
      _state = _state.copyWith(display: '0');
    }
    return _state;
  }

  CalculatorState _handleClearAll() {
    print('🔧 执行完全清除：重置所有状态');
    _state = const CalculatorState(); // 完全重置为初始状态
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
      
      // 记录计算步骤到历史
      String description = _getDescriptionFromExpression(expression);
      _calculationHistory.add(CalculationStep(
        expression: expression,
        description: description,
        input: currentValue,
        result: result,
        timestamp: DateTime.now(),
      ));
      
      // 限制历史记录数量，保留最近100条
      if (_calculationHistory.length > 100) {
        _calculationHistory.removeAt(0);
      }
      
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

  /// 处理多参数函数开始
  CalculatorState _handleMultiParamFunction(String functionName) {
    if (_state.isError) {
      _state = const CalculatorState();
    }
    
    // 获取当前显示的数值作为第一个参数
    double firstParam = double.parse(_state.display);
    
    print('🔧 开始多参数函数：$functionName, 第一个参数：$firstParam');
    
    _state = _state.copyWith(
      currentFunction: functionName,
      functionParameters: [firstParam],
      currentParameterIndex: 1,
      isInputtingFunction: true,
      display: '0',
      waitingForOperand: false,
    );
    
    return _state;
  }

  /// 处理参数分隔符（逗号）
  CalculatorState _handleParameterSeparator() {
    if (_state.isError || !_state.isInputtingFunction) return _state;
    
    try {
      // 将当前显示的值添加到参数列表
      double currentParam = double.parse(_state.display);
      List<double> updatedParams = List.from(_state.functionParameters)..add(currentParam);
      
      print('🔧 添加参数：$currentParam, 当前参数列表：$updatedParams');
      
      _state = _state.copyWith(
        functionParameters: updatedParams,
        currentParameterIndex: _state.currentParameterIndex + 1,
        display: '0',
        waitingForOperand: false,
      );
      
      return _state;
    } catch (e) {
      print('❌ 参数分隔符处理错误：$e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  /// 执行多参数函数
  CalculatorState _handleFunctionExecute() {
    if (_state.isError || !_state.isInputtingFunction || _state.currentFunction == null) {
      return _state;
    }
    
    try {
      // 添加最后一个参数
      double lastParam = double.parse(_state.display);
      List<double> allParams = List.from(_state.functionParameters)..add(lastParam);
      
      print('🔧 执行函数：${_state.currentFunction}, 参数：$allParams');
      
      // 计算多参数函数结果
      double result = _evaluateMultiParamFunction(_state.currentFunction!, allParams);
      
      // 记录计算历史
      String description = _getDescriptionFromMultiParamFunction(_state.currentFunction!, allParams);
      _calculationHistory.add(CalculationStep(
        expression: '${_state.currentFunction}(${allParams.join(', ')})',
        description: description,
        input: allParams.first,
        result: result,
        timestamp: DateTime.now(),
      ));
      
      // 限制历史记录数量
      if (_calculationHistory.length > 100) {
        _calculationHistory.removeAt(0);
      }
      
      _state = _state.copyWith(
        display: _formatResult(result),
        waitingForOperand: true,
        clearFunction: true,
        functionParameters: [],
        currentParameterIndex: 0,
        isInputtingFunction: false,
      );
      
      return _state;
    } catch (e) {
      print('❌ 多参数函数执行错误：$e');
      return _state.copyWith(
        display: 'Error', 
        isError: true,
        clearFunction: true,
        functionParameters: [],
        currentParameterIndex: 0,
        isInputtingFunction: false,
      );
    }
  }

  /// 科学计算表达式解析器
  double _evaluateScientificExpression(String expression, double x) {
    print('🔧 计算表达式：$expression, 当前值：$x');
    
    // 直接匹配表达式模式（不需要替换变量）
    switch (expression.toLowerCase().trim()) {
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
    
    // 如果没有匹配的函数，尝试动态计算表达式
    return _evaluateByReplacement(expression, x);
  }

  /// 计算阶乘
  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  /// 动态替换变量并计算表达式
  double _evaluateByReplacement(String expression, double x) {
    try {
      // 替换变量
      String processed = expression
          .replaceAll('x', x.toString())
          .replaceAll('input', x.toString())
          .replaceAll('value', x.toString());

      print('🔧 处理后的表达式：$processed');
      
      // 简单表达式计算
      return _evaluateSimpleExpression(processed);
    } catch (e) {
      print('⚠️ 表达式解析失败：$e');
      throw Exception('无法计算表达式');
    }
  }

  /// 简单表达式计算（回退方案）
  double _evaluateSimpleExpression(String expression) {
    // 处理基本的算术运算
    expression = expression.replaceAll(' ', '');
    
    try {
      // 尝试使用math_expressions库进行解析
      Parser parser = ShuntingYardParser();
      Expression exp = parser.parse(expression);
      ContextModel cm = ContextModel();
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      print('⚠️ math_expressions解析失败，使用简单解析器：$e');
      return _evaluateSimpleArithmetic(expression);
    }
  }

  /// 简单算术表达式计算
  double _evaluateSimpleArithmetic(String expression) {
    // 处理乘法（支持多个操作数）
    if (expression.contains('*')) {
      var parts = expression.split('*');
      if (parts.length >= 2) {
        double result = double.parse(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          result *= double.parse(parts[i]);
        }
        return result;
      }
    }
    
    // 处理除法（支持多个操作数）
    if (expression.contains('/')) {
      var parts = expression.split('/');
      if (parts.length >= 2) {
        double result = double.parse(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          double divisor = double.parse(parts[i]);
          if (divisor == 0) throw Exception('Division by zero');
          result /= divisor;
        }
        return result;
      }
    }
    
    // 处理加法（支持多个操作数）
    if (expression.contains('+')) {
      var parts = expression.split('+');
      if (parts.length >= 2) {
        double result = 0;
        for (String part in parts) {
          result += double.parse(part);
        }
        return result;
      }
    }
    
    // 处理减法（注意负数）
    if (expression.contains('-') && !expression.startsWith('-')) {
      var parts = expression.split('-');
      if (parts.length >= 2) {
        double result = double.parse(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          result -= double.parse(parts[i]);
        }
        return result;
      }
    }
    
    // 直接解析数字
    return double.parse(expression);
  }

  /// 根据表达式生成人类可读的描述
  String _getDescriptionFromExpression(String expression) {
    switch (expression.toLowerCase().trim()) {
      // 三角函数
      case 'sin(x)': return '正弦函数 sin(x)';
      case 'cos(x)': return '余弦函数 cos(x)';
      case 'tan(x)': return '正切函数 tan(x)';
      case 'asin(x)': return '反正弦函数 arcsin(x)';
      case 'acos(x)': return '反余弦函数 arccos(x)';
      case 'atan(x)': return '反正切函数 arctan(x)';
      
      // 双曲函数
      case 'sinh(x)': return '双曲正弦函数 sinh(x)';
      case 'cosh(x)': return '双曲余弦函数 cosh(x)';
      case 'tanh(x)': return '双曲正切函数 tanh(x)';
      
      // 对数函数
      case 'log(x)':
      case 'ln(x)': return '自然对数 ln(x)';
      case 'log10(x)': return '常用对数 log₁₀(x)';
      case 'log2(x)': return '二进制对数 log₂(x)';
      
      // 指数函数
      case 'exp(x)':
      case 'e^x': return '自然指数函数 eˣ';
      case 'pow(2,x)':
      case '2^x': return '二次幂 2ˣ';
      case 'pow(10,x)':
      case '10^x': return '十次幂 10ˣ';
      
      // 幂函数
      case 'x*x':
      case 'x^2': return '平方运算 x²';
      case 'pow(x,3)':
      case 'x^3': return '立方运算 x³';
      case 'pow(x,4)':
      case 'x^4': return '四次方运算 x⁴';
      case 'pow(x,5)':
      case 'x^5': return '五次方运算 x⁵';
      
      // 根号函数
      case 'sqrt(x)': return '平方根 √x';
      case 'pow(x,1/3)':
      case 'cbrt(x)': return '立方根 ∛x';
      
      // 其他函数
      case '1/x': return '倒数运算 1/x';
      case 'abs(x)': return '绝对值 |x|';
      case '1/sqrt(x)': return '平方根倒数 1/√x';
      
      // 百分比和倍数
      case 'x*0.15': return '计算15%';
      case 'x*0.20': return '计算20%';
      case 'x*0.085': return '计算8.5%';
      case 'x*1.13': return '增加13%';
      case 'x*0.7': return '减少30%';
      case 'x*2': return '乘以2';
      
      // 单位转换
      case 'x*9/5+32': return '摄氏度转华氏度';
      case '(x-32)*5/9': return '华氏度转摄氏度';
      case 'x*2.54': return '英寸转厘米';
      case 'x/2.54': return '厘米转英寸';
      case 'x*10.764': return '平方米转平方英尺';
      case 'x/10.764': return '平方英尺转平方米';
      
      // 特殊函数
      case 'random()':
      case 'rand()': return '生成随机数';
      case 'x!':
      case 'factorial(x)': return '阶乘运算 x!';
      
      default:
        // 如果是复杂表达式，尝试简化描述
        if (expression.contains('*')) return '乘法运算';
        if (expression.contains('/')) return '除法运算';
        if (expression.contains('+')) return '加法运算';
        if (expression.contains('-')) return '减法运算';
        return '数学表达式计算';
    }
  }

  /// 计算多参数函数
  double _evaluateMultiParamFunction(String functionName, List<double> params) {
    print('🔧 计算多参数函数：$functionName, 参数：$params');
    
    switch (functionName.toLowerCase()) {
      case 'pow':
        if (params.length != 2) throw Exception('pow函数需要2个参数');
        return math.pow(params[0], params[1]).toDouble();
      
      case 'log':
        if (params.length == 1) {
          return math.log(params[0]); // 自然对数
        } else if (params.length == 2) {
          // log(x, base) = ln(x) / ln(base)
          return math.log(params[0]) / math.log(params[1]);
        }
        throw Exception('log函数需要1或2个参数');
      
      case 'atan2':
        if (params.length != 2) throw Exception('atan2函数需要2个参数');
        return math.atan2(params[0], params[1]);
      
      case 'hypot':
        if (params.length != 2) throw Exception('hypot函数需要2个参数');
        return math.sqrt(params[0] * params[0] + params[1] * params[1]);
      
      case 'max':
        if (params.isEmpty) throw Exception('max函数至少需要1个参数');
        return params.reduce(math.max);
      
      case 'min':
        if (params.isEmpty) throw Exception('min函数至少需要1个参数');
        return params.reduce(math.min);
      
      case 'avg':
      case 'mean':
        if (params.isEmpty) throw Exception('avg函数至少需要1个参数');
        return params.reduce((a, b) => a + b) / params.length;
      
      case 'sum':
        if (params.isEmpty) throw Exception('sum函数至少需要1个参数');
        return params.reduce((a, b) => a + b);
      
      case 'product':
        if (params.isEmpty) throw Exception('product函数至少需要1个参数');
        return params.reduce((a, b) => a * b);
      
      case 'gcd':
        if (params.length != 2) throw Exception('gcd函数需要2个参数');
        return _gcd(params[0].toInt(), params[1].toInt()).toDouble();
      
      case 'lcm':
        if (params.length != 2) throw Exception('lcm函数需要2个参数');
        int a = params[0].toInt();
        int b = params[1].toInt();
        return (a * b / _gcd(a, b)).toDouble();
      
      case 'mod':
        if (params.length != 2) throw Exception('mod函数需要2个参数');
        return params[0] % params[1];
      
      case 'round':
        if (params.length == 1) {
          return params[0].round().toDouble();
        } else if (params.length == 2) {
          double factor = math.pow(10, params[1].toInt()).toDouble();
          return (params[0] * factor).round() / factor;
        }
        throw Exception('round函数需要1或2个参数');
      
      // 金融和货币转换函数
      case '汇率转换':
      case 'currency':
      case 'exchange':
      case 'exchangerate': // AI生成的英文名称
        if (params.length != 2) throw Exception('汇率转换函数需要2个参数：金额和汇率');
        return params[0] * params[1]; // 金额 × 汇率
      
      case '复利计算':
      case 'compound':
      case 'compoundinterest': // AI生成的英文名称
        if (params.length == 3) {
          // 本金、年利率、年数
          double principal = params[0];
          double rate = params[1] / 100; // 转换为小数
          double years = params[2];
          return principal * math.pow(1 + rate, years);
        }
        throw Exception('复利计算需要3个参数：本金、年利率(%)、年数');
      
      case '贷款计算':
      case 'loan':
      case 'loanpayment': // AI生成的英文名称
        if (params.length == 3) {
          // 贷款金额、年利率、年数
          double principal = params[0];
          double annualRate = params[1] / 100; // 转换为小数
          double years = params[2];
          double monthlyRate = annualRate / 12;
          double months = years * 12;
          
          if (monthlyRate == 0) {
            return principal / months; // 无利息情况
          }
          
          // 等额本息月供计算公式
          return principal * (monthlyRate * math.pow(1 + monthlyRate, months)) / 
                 (math.pow(1 + monthlyRate, months) - 1);
        }
        throw Exception('贷款计算需要3个参数：贷款金额、年利率(%)、年数');
      
      case '投资回报':
      case 'roi':
      case 'investmentreturn': // AI生成的英文名称
        if (params.length == 2) {
          // 投资收益、投资成本
          double profit = params[0];
          double cost = params[1];
          if (cost == 0) throw Exception('投资成本不能为0');
          return (profit / cost) * 100; // 返回百分比
        }
        throw Exception('投资回报率需要2个参数：投资收益、投资成本');
      
      default:
        throw Exception('未知的多参数函数：$functionName');
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

  /// 生成多参数函数的描述
  String _getDescriptionFromMultiParamFunction(String functionName, List<double> params) {
    switch (functionName.toLowerCase()) {
      case 'pow':
        return '幂运算 ${params[0]}^${params[1]}';
      case 'log':
        if (params.length == 1) {
          return '自然对数 ln(${params[0]})';
        } else {
          return '对数运算 log${params[1]}(${params[0]})';
        }
      case 'atan2':
        return '二参数反正切 atan2(${params[0]}, ${params[1]})';
      case 'hypot':
        return '直角三角形斜边长 √(${params[0]}² + ${params[1]}²)';
      case 'max':
        return '最大值 max(${params.join(', ')})';
      case 'min':
        return '最小值 min(${params.join(', ')})';
      case 'avg':
      case 'mean':
        return '平均值 avg(${params.join(', ')})';
      case 'sum':
        return '求和 sum(${params.join(', ')})';
      case 'product':
        return '乘积 product(${params.join(', ')})';
      case 'gcd':
        return '最大公约数 gcd(${params[0].toInt()}, ${params[1].toInt()})';
      case 'lcm':
        return '最小公倍数 lcm(${params[0].toInt()}, ${params[1].toInt()})';
      case 'mod':
        return '取模运算 ${params[0]} mod ${params[1]}';
      case 'round':
        if (params.length == 1) {
          return '四舍五入 round(${params[0]})';
        } else {
          return '精确四舍五入 round(${params[0]}, ${params[1].toInt()}位小数)';
        }
      
      // 金融函数描述
      case '汇率转换':
      case 'currency':
      case 'exchange':
      case 'exchangerate':
        return '汇率转换 ${params[0]} × ${params[1]}';
      
      case '复利计算':
      case 'compound':
      case 'compoundinterest':
        return '复利计算 本金${params[0]}，年利率${params[1]}%，${params[2]}年';
      
      case '贷款计算':
      case 'loan':
      case 'loanpayment':
        return '贷款月供 本金${params[0]}，年利率${params[1]}%，${params[2]}年';
      
      case '投资回报':
      case 'roi':
      case 'investmentreturn':
        return '投资回报率 收益${params[0]}，成本${params[1]}';
      
      default:
        return '多参数函数 $functionName(${params.join(', ')})';
    }
  }

  /// 重置计算器状态
  void reset() {
    print('🔧 重置计算器引擎：完全清除所有状态');
    _state = const CalculatorState();
  }

  /// 清空计算历史
  void clearHistory() {
    _calculationHistory.clear();
  }
} 