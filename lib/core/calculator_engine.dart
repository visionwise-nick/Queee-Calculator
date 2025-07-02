import 'dart:math' as math;
import 'dart:math' show Random;
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
  customFunction,     // 自定义复合功能
}

/// 计算器操作定义
class CalculatorAction {
  final CalculatorActionType type;
  final String? value;
  final String? expression; // 新增：数学表达式
  final Map<String, dynamic>? parameters; // 新增：自定义功能的预设参数

  const CalculatorAction({
    required this.type,
    this.value,
    this.expression,
    this.parameters,
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
      parameters: json['parameters'] as Map<String, dynamic>?,
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
      case 'customfunction':
        return CalculatorActionType.customFunction;
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
      if (parameters != null) 'parameters': parameters,
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
    
    // 构建参数列表，用0填充未输入的参数
    List<String> paramStrings = [];
    
    // 添加已输入完成的参数
    for (double param in functionParameters) {
      paramStrings.add(_formatParameter(param));
    }
    
    // 添加当前正在输入的参数
    paramStrings.add(display);
    
    // 根据函数类型确定总参数数量并用0填充剩余位置
    int totalParams = _getExpectedParamCount(currentFunction!);
    while (paramStrings.length < totalParams) {
      paramStrings.add('0');
    }
    
    return '$currentFunction(${paramStrings.join(',')})';
  }
  
  String _formatParameter(double param) {
    if (param == param.toInt()) {
      return param.toInt().toString();
    } else {
      return param.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }
  
  /// 获取函数期望的参数数量
  int _getExpectedParamCount(String functionName) {
    switch (functionName.toLowerCase()) {
      case 'pow':
      case 'log':
      case 'atan2':
      case 'hypot':
      case 'gcd':
      case 'lcm':
      case 'mod':
      case '汇率转换':
      case 'currency':
      case 'exchange':
      case 'exchangerate':
      case '投资回报':
      case 'roi':
      case 'investmentreturn':
        return 2;
      
      case '复利计算':
      case 'compound':
      case 'compoundinterest':
      case '贷款计算':
      case 'loan':
      case 'loanpayment':
      case '年金计算':
      case 'annuity':
      case '通胀调整':
      case 'inflation':
        return 3;
      
      case '抵押贷款':
      case 'mortgage':
      case '债券价格':
      case 'bond':
        return 4;
      
      case '期权价值':
      case 'option':
        return 5;
      
      default:
        return 3; // 默认3个参数
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
        case CalculatorActionType.customFunction:
          return _handleCustomFunction(action.value!, action.parameters);
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
    
    print('🔧 开始多参数函数：$functionName，不读取屏幕数字，从空参数开始');
    
    _state = _state.copyWith(
      currentFunction: functionName,
      functionParameters: [], // 空参数列表，不读取当前屏幕数字
      currentParameterIndex: 0, // 从第0个参数开始
      isInputtingFunction: true,
      display: '0', // 重置为0，让用户输入第一个参数
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

  /// 处理自定义复合功能
  CalculatorState _handleCustomFunction(String functionType, Map<String, dynamic>? parameters) {
    if (_state.isError) return _state;
    
    try {
      double inputValue = double.parse(_state.display);
      double result;
      String description;
      
      print('🚀 执行自定义功能：$functionType, 输入值：$inputValue, 参数：$parameters');
      
      // 根据功能类型执行相应的计算
      switch (functionType.toLowerCase()) {
        case 'mortgage_calculator':
          // 房贷计算：从parameters中获取利率和年限
          double annualRate = parameters?['annualRate']?.toDouble() ?? 3.5; // 年利率%
          int years = parameters?['years']?.toInt() ?? 30; // 贷款年限
          double loanAmount = inputValue; // 贷款金额
          
          double monthlyRate = annualRate / 100 / 12; // 月利率
          int totalMonths = years * 12; // 总月数
          
          // 月供计算公式：M = P * [r(1+r)^n] / [(1+r)^n - 1]
          double monthlyPayment = loanAmount * 
              (monthlyRate * math.pow(1 + monthlyRate, totalMonths)) / 
              (math.pow(1 + monthlyRate, totalMonths) - 1);
          
          result = monthlyPayment;
          description = '房贷计算：¥$loanAmount，利率${annualRate}%，${years}年，月供';
          break;
          
        case 'compound_calculator':
          // 复利计算：从parameters中获取利率和年限
          double rate = parameters?['rate']?.toDouble() ?? 4.0; // 年利率%
          int years = parameters?['years']?.toInt() ?? 10; // 投资年限
          double principal = inputValue; // 本金
          
          // 复利公式：A = P(1 + r)^t
          result = principal * math.pow(1 + rate / 100, years);
          description = '复利计算：本金¥$principal，利率${rate}%，${years}年后';
          break;
          
        case 'currency_converter':
          // 货币转换：从parameters中获取汇率和货币类型
          double rate = parameters?['rate']?.toDouble() ?? 7.2; // 汇率
          String fromCurrency = parameters?['fromCurrency']?.toString() ?? 'USD';
          String toCurrency = parameters?['toCurrency']?.toString() ?? 'CNY';
          result = inputValue * rate;
          description = '货币转换：$inputValue $fromCurrency → $toCurrency，汇率$rate';
          break;
          
        case 'discount_calculator':
          // 折扣计算：从parameters中获取折扣率和税率
          double discountRate = parameters?['discountRate']?.toDouble() ?? 25; // 折扣率%
          double taxRate = parameters?['taxRate']?.toDouble() ?? 13; // 税率%
          double discountedPrice = inputValue * (1 - discountRate / 100);
          result = discountedPrice * (1 + taxRate / 100);
          description = '折扣计算：原价¥$inputValue，${discountRate}%折扣，含${taxRate}%税';
          break;
          
        case 'bmi_calculator':
          // BMI计算：从parameters中获取身高
          double height = parameters?['height']?.toDouble() ?? 175; // 身高cm
          double weight = inputValue; // 体重kg
          result = weight / math.pow(height / 100, 2);
          description = 'BMI计算：体重${weight}kg，身高${height}cm';
          break;
          
        default:
          throw Exception('未知的自定义功能类型：$functionType');
      }
      
      // 记录计算历史
      _calculationHistory.add(CalculationStep(
        expression: '$functionType($inputValue)',
        description: description,
        input: inputValue,
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
      );
      
      return _state;
    } catch (e) {
      print('❌ 自定义功能执行错误：$e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  /// 科学计算表达式解析器
  double _evaluateScientificExpression(String expression, double x) {
    // 替换表达式中的x为实际值
    String evalExpression = expression.replaceAll('x', x.toString());
    print('🔢 替换后的表达式：$evalExpression');
    
    try {
      // 🔧 处理特殊的单参数函数
      switch (expression.toLowerCase().trim()) {
        // 三角函数（角度制）
        case 'sin(x)':
          return math.sin(x * math.pi / 180); // 转换为弧度
        case 'cos(x)':
          return math.cos(x * math.pi / 180);
        case 'tan(x)':
          return math.tan(x * math.pi / 180);
        case 'asin(x)':
          return math.asin(x) * 180 / math.pi; // 转换为角度
        case 'acos(x)':
          return math.acos(x) * 180 / math.pi;
        case 'atan(x)':
          return math.atan(x) * 180 / math.pi;
        
        // 双曲函数
        case 'sinh(x)':
          return (math.exp(x) - math.exp(-x)) / 2;
        case 'cosh(x)':
          return (math.exp(x) + math.exp(-x)) / 2;
        case 'tanh(x)':
          double expX = math.exp(x);
          double expNegX = math.exp(-x);
          return (expX - expNegX) / (expX + expNegX);
        
        // 对数函数
        case 'log(x)':
        case 'ln(x)':
          if (x <= 0) throw Exception('对数函数的参数必须大于0');
          return math.log(x);
        case 'log10(x)':
          if (x <= 0) throw Exception('对数函数的参数必须大于0');
          return math.log(x) / math.log(10);
        case 'log2(x)':
          if (x <= 0) throw Exception('对数函数的参数必须大于0');
          return math.log(x) / math.log(2);
        
        // 指数函数
        case 'exp(x)':
        case 'e^x':
          return math.exp(x);
        case 'pow(2,x)':
        case '2^x':
          return math.pow(2, x).toDouble();
        case 'pow(10,x)':
        case '10^x':
          return math.pow(10, x).toDouble();
        
        // 幂函数
        case 'x*x':
        case 'x^2':
          return x * x;
        case 'pow(x,3)':
        case 'x^3':
          return math.pow(x, 3).toDouble();
        case 'pow(x,4)':
        case 'x^4':
          return math.pow(x, 4).toDouble();
        case 'pow(x,5)':
        case 'x^5':
          return math.pow(x, 5).toDouble();
        
        // 根函数
        case 'sqrt(x)':
          if (x < 0) throw Exception('平方根的参数不能为负数');
          return math.sqrt(x);
        case 'pow(x,1/3)':
        case 'cbrt(x)':
          // 立方根，支持负数
          return x < 0 ? -math.pow(-x, 1/3).toDouble() : math.pow(x, 1/3).toDouble();
        
        // 其他函数
        case '1/x':
          if (x == 0) throw Exception('除数不能为零');
          return 1 / x;
        case 'abs(x)':
          return x.abs();
        case '1/sqrt(x)':
          if (x <= 0) throw Exception('平方根的参数必须大于0');
          return 1 / math.sqrt(x);
        case 'x!':
        case 'factorial(x)':
          return _factorial(x.toInt()).toDouble();
        
        // 🔧 新增：进制转换功能 - 使用数学方法
        case 'dec_to_bin(x)':  
          return _convertToBase(x.toInt(), 2); // 十进制转二进制（以十进制数值表示）
        case 'dec_to_oct(x)':
          return _convertToBase(x.toInt(), 8); // 十进制转八进制（以十进制数值表示）
        case 'dec_to_hex(x)':
          return _convertToBase(x.toInt(), 16); // 十进制转十六进制（以十进制数值表示）
        case 'bin_to_dec(x)':
          return _convertFromBase(x.toInt(), 2); // 二进制转十进制
        case 'oct_to_dec(x)':
          return _convertFromBase(x.toInt(), 8); // 八进制转十进制
        case 'hex_to_dec(x)':
          return _convertFromBase(x.toInt(), 16); // 十六进制转十进制
        
        // 🔧 增强单位转换功能
        // 温度转换
        case 'x*9/5+32':
          return x * 9 / 5 + 32; // 摄氏度→华氏度
        case '(x-32)*5/9':
          return (x - 32) * 5 / 9; // 华氏度→摄氏度
        case 'x+273.15':
          return x + 273.15; // 摄氏度→开尔文
        case 'x-273.15':
          return x - 273.15; // 开尔文→摄氏度
        
        // 长度转换
        case 'x*2.54':
          return x * 2.54; // 英寸→厘米
        case 'x/2.54':
          return x / 2.54; // 厘米→英寸
        case 'x*0.3048':
          return x * 0.3048; // 英尺→米
        case 'x/0.3048':
          return x / 0.3048; // 米→英尺
        case 'x*1.60934':
          return x * 1.60934; // 英里→公里
        case 'x/1.60934':
          return x / 1.60934; // 公里→英里
        case 'x*1000':
          return x * 1000; // 米→毫米
        case 'x/1000':
          return x / 1000; // 毫米→米
        
        // 重量转换
        case 'x*0.453592':
          return x * 0.453592; // 磅→公斤
        case 'x/0.453592':
          return x / 0.453592; // 公斤→磅
        case 'x*28.3495':
          return x * 28.3495; // 盎司→克
        case 'x/28.3495':
          return x / 28.3495; // 克→盎司
        case 'x*1000':
          return x * 1000; // 公斤→克（如果x本身是公斤）
        case 'x/1000':
          return x / 1000; // 克→公斤
        
        // 面积转换
        case 'x*10.764':
          return x * 10.764; // 平方米→平方英尺
        case 'x/10.764':
          return x / 10.764; // 平方英尺→平方米
        case 'x*2.59':
          return x * 2.59; // 平方英里→平方公里
        case 'x/2.59':
          return x / 2.59; // 平方公里→平方英里
        
        // 体积转换
        case 'x*3.78541':
          return x * 3.78541; // 加仑→升
        case 'x/3.78541':
          return x / 3.78541; // 升→加仑
        case 'x*29.5735':
          return x * 29.5735; // 盎司→毫升
        case 'x/29.5735':
          return x / 29.5735; // 毫升→盎司
        
        // 百分比和倍数运算
        case 'x*0.01':
          return x * 0.01; // 百分比转换
        case 'x*0.15':
          return x * 0.15; // 15%计算
        case 'x*0.18':
          return x * 0.18; // 18%计算
        case 'x*0.20':
          return x * 0.20; // 20%计算
        case 'x*0.085':
          return x * 0.085; // 8.5%计算
        case 'x*1.13':
          return x * 1.13; // 含税价格（13%）
        case 'x*1.15':
          return x * 1.15; // 含税价格（15%）
        case 'x*0.85':
          return x * 0.85; // 15%折扣
        case 'x*0.7':
          return x * 0.7; // 30%折扣
        case 'x*0.8':
          return x * 0.8; // 20%折扣
        case 'x*2':
          return x * 2; // 乘以2
        
        // 特殊函数
        case 'random()':
        case 'rand()':
          return math.Random().nextDouble(); // 0到1之间的随机数
        case 'pi':
        case 'π':
          return math.pi;
        case 'e':
          return math.e;
        
        default:
          // 对于复杂表达式，使用表达式解析器
          return _evaluateComplexExpression(expression, x);
      }
    } catch (e) {
      print('❌ 科学计算错误：$e');
      throw Exception('计算错误：$e');
    }
  }

  /// 🔧 新增：复杂表达式计算器
  double _evaluateComplexExpression(String expression, double x) {
    try {
      // 替换x为实际值
      String evalExpression = expression.replaceAll('x', x.toString());
      
      // 处理特殊的数学函数
      evalExpression = evalExpression
          .replaceAll('sin(', 'sin(')
          .replaceAll('cos(', 'cos(')
          .replaceAll('tan(', 'tan(')
          .replaceAll('sqrt(', 'sqrt(')
          .replaceAll('log(', 'ln(')
          .replaceAll('exp(', 'e^(')
          .replaceAll('π', math.pi.toString())
          .replaceAll('pi', math.pi.toString())
          .replaceAll('e', math.e.toString());

      // 使用math_expressions库解析
      Parser p = Parser();
      Expression exp = p.parse(evalExpression);
      ContextModel cm = ContextModel();
      
      double result = exp.evaluate(EvaluationType.REAL, cm);
      
      if (result.isNaN || result.isInfinite) {
        throw Exception('计算结果无效');
      }
      
      return result;
    } catch (e) {
      // 如果表达式解析失败，尝试简单计算
      return _evaluateSimpleExpression(expression.replaceAll('x', x.toString()));
    }
  }

  /// 简单表达式计算（回退方案）
  double _evaluateSimpleExpression(String expression) {
    // 处理基本的算术运算
    expression = expression.replaceAll(' ', '');
    
    try {
      // 尝试使用math_expressions库进行解析
      Parser parser = Parser();
      Expression exp = parser.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      
      // 检查无效结果
      if (result.isNaN || result.isInfinite) {
        throw Exception('Invalid calculation result');
      }
      
      return result;
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
      case 'x*0.01': return '百分比转换';
      case 'x*0.15': return '计算15%';
      case 'x*0.18': return '计算18%';
      case 'x*0.20': return '计算20%';
      case 'x*0.085': return '计算8.5%';
      case 'x*1.13': return '含税价格（13%）';
      case 'x*1.15': return '含税价格（15%）';
      case 'x*0.85': return '15%折扣';
      case 'x*0.7': return '30%折扣';
      case 'x*0.8': return '20%折扣';
      case 'x*2': return '乘以2';
      
      // 单位转换 - 温度
      case 'x*9/5+32': return '摄氏度→华氏度';
      case '(x-32)*5/9': return '华氏度→摄氏度';
      case 'x+273.15': return '摄氏度→开尔文';
      case 'x-273.15': return '开尔文→摄氏度';
      
      // 单位转换 - 长度
      case 'x*2.54': return '英寸→厘米';
      case 'x/2.54': return '厘米→英寸';
      case 'x*0.3048': return '英尺→米';
      case 'x/0.3048': return '米→英尺';
      case 'x*1.60934': return '英里→公里';
      case 'x/1.60934': return '公里→英里';
      
      // 单位转换 - 重量
      case 'x*0.453592': return '磅→公斤';
      case 'x/0.453592': return '公斤→磅';
      case 'x*28.3495': return '盎司→克';
      case 'x/28.3495': return '克→盎司';
      
      // 单位转换 - 面积
      case 'x*10.764': return '平方米→平方英尺';
      case 'x/10.764': return '平方英尺→平方米';
      
      // 单位转换 - 体积
      case 'x*3.78541': return '加仑→升';
      case 'x/3.78541': return '升→加仑';
      case 'x*29.5735': return '盎司→毫升';
      case 'x/29.5735': return '毫升→盎司';
      
      // 特殊函数
      case 'random()':
      case 'rand()': return '生成随机数';
      case 'x!':
      case 'factorial(x)': return '阶乘运算 x!';
      case 'pi':
      case 'π': return '圆周率 π';
      case 'e': return '自然常数 e';
      
      default:
        // 如果是复杂表达式，尝试简化描述
        if (expression.contains('*')) return '乘法运算';
        if (expression.contains('/')) return '除法运算';
        if (expression.contains('+')) return '加法运算';
        if (expression.contains('-')) return '减法运算';
        return '数学表达式计算';
    }
  }

  /// 🔧 增强：阶乘计算
  int _factorial(int n) {
    if (n < 0) throw Exception('阶乘的参数不能为负数');
    if (n > 20) throw Exception('阶乘参数过大（最大支持20）');
    if (n <= 1) return 1;
    
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  /// 🔧 新增：进制转换 - 十进制转任意进制
  double _convertToBase(int number, int base) {
    if (base < 2 || base > 36) throw Exception('进制必须在2-36之间');
    if (number < 0) throw Exception('暂不支持负数进制转换');
    
    if (number == 0) return 0;
    
    List<int> digits = [];
    int temp = number;
    
    while (temp > 0) {
      digits.add(temp % base);
      temp = temp ~/ base;
    }
    
    // 将结果组合成一个数值（适用于2-10进制）
    // 对于16进制以上，会用数字表示（例如：A=10, B=11等）
    if (base <= 10) {
      double result = 0;
      for (int i = digits.length - 1; i >= 0; i--) {
        result = result * 10 + digits[i];
      }
      return result;
    } else {
      // 对于16进制以上，使用特殊编码
      // 例如十六进制FF会被表示为特殊数值
      double result = 0;
      for (int i = digits.length - 1; i >= 0; i--) {
        result = result * 100 + digits[i]; // 用100进制来表示大于10的数字
      }
      return result;
    }
  }
  
  /// 🔧 新增：进制转换 - 任意进制转十进制
  double _convertFromBase(int number, int base) {
    if (base < 2 || base > 36) throw Exception('进制必须在2-36之间');
    if (number < 0) throw Exception('暂不支持负数进制转换');
    
    String numStr = number.toString();
    double result = 0;
    int power = 0;
    
    // 从右到左处理每一位
    for (int i = numStr.length - 1; i >= 0; i--) {
      int digit = int.parse(numStr[i]);
      if (digit >= base) throw Exception('数字 $digit 超出 $base 进制范围');
      result += digit * math.pow(base, power);
      power++;
    }
    
    return result;
  }

  /// 计算多参数函数
  double _evaluateMultiParamFunction(String functionName, List<double> params) {
    print('🔧 计算多参数函数：$functionName, 参数：$params');
    
    switch (functionName.toLowerCase()) {
      // 统计函数 - 中文名称映射
      case '平均值':
      case '平均数':
        if (params.isEmpty) throw Exception('平均值函数至少需要1个参数');
        return params.reduce((a, b) => a + b) / params.length;
      
      case '标准差':
        if (params.isEmpty) throw Exception('标准差函数至少需要1个参数');
        double mean = params.reduce((a, b) => a + b) / params.length;
        double variance = params.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / params.length;
        return math.sqrt(variance);
      
      case '方差':
        if (params.isEmpty) throw Exception('方差函数至少需要1个参数');
        double mean = params.reduce((a, b) => a + b) / params.length;
        return params.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / params.length;
      
      case '中位数':
        if (params.isEmpty) throw Exception('中位数函数至少需要1个参数');
        List<double> sortedParams = List.from(params)..sort();
        int n = sortedParams.length;
        if (n % 2 == 1) {
          return sortedParams[n ~/ 2];
        } else {
          return (sortedParams[n ~/ 2 - 1] + sortedParams[n ~/ 2]) / 2;
        }
      
      case '最大值':
        if (params.isEmpty) throw Exception('最大值函数至少需要1个参数');
        return params.reduce(math.max);
      
      case '最小值':
        if (params.isEmpty) throw Exception('最小值函数至少需要1个参数');
        return params.reduce(math.min);
      
      case '求和':
        if (params.isEmpty) throw Exception('求和函数至少需要1个参数');
        return params.reduce((a, b) => a + b);
      
      case '组合':
        if (params.length != 2) throw Exception('组合函数需要2个参数：n和r');
        int n = params[0].toInt();
        int r = params[1].toInt();
        if (r > n || r < 0) throw Exception('组合计算参数无效');
        return _factorial(n) / (_factorial(r) * _factorial(n - r));
      
      case '排列':
        if (params.length != 2) throw Exception('排列函数需要2个参数：n和r');
        int n = params[0].toInt();
        int r = params[1].toInt();
        if (r > n || r < 0) throw Exception('排列计算参数无效');
        return _factorial(n) / _factorial(n - r);
      
      case '阶乘':
        if (params.length != 1) throw Exception('阶乘函数需要1个参数');
        int n = params[0].toInt();
        if (n < 0) throw Exception('阶乘不能计算负数');
        return _factorial(n).toDouble();
      
      case '随机数':
        if (params.length == 0) {
          return Random().nextDouble(); // 0-1之间的随机数
        } else if (params.length == 1) {
          return Random().nextInt(params[0].toInt()).toDouble();
        } else if (params.length == 2) {
          int min = params[0].toInt();
          int max = params[1].toInt();
          return (Random().nextInt(max - min + 1) + min).toDouble();
        }
        throw Exception('随机数函数需要0-2个参数');
      
      case '百分位数':
        if (params.length < 2) throw Exception('百分位数函数至少需要2个参数：百分位数和数据');
        double percentile = params[0];
        List<double> data = params.sublist(1);
        data.sort();
        double index = (percentile / 100) * (data.length - 1);
        int lowerIndex = index.floor();
        int upperIndex = index.ceil();
        if (lowerIndex == upperIndex) {
          return data[lowerIndex];
        } else {
          double weight = index - lowerIndex;
          return data[lowerIndex] * (1 - weight) + data[upperIndex] * weight;
        }
      
      case '线性回归':
        if (params.length < 4 || params.length % 2 != 0) {
          throw Exception('线性回归函数需要偶数个参数：x1,y1,x2,y2,...');
        }
        List<double> xValues = [];
        List<double> yValues = [];
        for (int i = 0; i < params.length; i += 2) {
          xValues.add(params[i]);
          yValues.add(params[i + 1]);
        }
        int n = xValues.length;
        double sumX = xValues.reduce((a, b) => a + b);
        double sumY = yValues.reduce((a, b) => a + b);
        double sumXY = 0;
        double sumX2 = 0;
        for (int i = 0; i < n; i++) {
          sumXY += xValues[i] * yValues[i];
          sumX2 += xValues[i] * xValues[i];
        }
        double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        return slope; // 返回斜率，可以扩展返回截距
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
      
      // 🔧 新增：进制转换多参数函数
      case '进制转换':
      case 'baseconvert':
      case 'base_convert':
        if (params.length == 2) {
          // 默认从10进制转换到目标进制
          int number = params[0].toInt();
          int targetBase = params[1].toInt();
          return _convertToBase(number, targetBase);
        } else if (params.length == 3) {
          // 从源进制转换到目标进制
          int number = params[0].toInt();
          int sourceBase = params[1].toInt();
          int targetBase = params[2].toInt();
          // 先转为十进制，再转为目标进制
          double decimalValue = _convertFromBase(number, sourceBase);
          return _convertToBase(decimalValue.toInt(), targetBase);
        }
        throw Exception('进制转换需要2个参数（数值,目标进制）或3个参数（数值,源进制,目标进制）');
      
      case '十进制转二进制':
      case 'dec_to_bin':
        if (params.length != 1) throw Exception('十进制转二进制需要1个参数');
        return _convertToBase(params[0].toInt(), 2);
      
      case '十进制转八进制':
      case 'dec_to_oct':
        if (params.length != 1) throw Exception('十进制转八进制需要1个参数');
        return _convertToBase(params[0].toInt(), 8);
      
      case '十进制转十六进制':
      case 'dec_to_hex':
        if (params.length != 1) throw Exception('十进制转十六进制需要1个参数');
        return _convertToBase(params[0].toInt(), 16);
      
      case '二进制转十进制':
      case 'bin_to_dec':
        if (params.length != 1) throw Exception('二进制转十进制需要1个参数');
        return _convertFromBase(params[0].toInt(), 2);
      
      case '八进制转十进制':
      case 'oct_to_dec':
        if (params.length != 1) throw Exception('八进制转十进制需要1个参数');
        return _convertFromBase(params[0].toInt(), 8);
      
      case '十六进制转十进制':
      case 'hex_to_dec':
        if (params.length != 1) throw Exception('十六进制转十进制需要1个参数');
        return _convertFromBase(params[0].toInt(), 16);
      
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
      case 'investmentreturn':
        if (params.length == 2) {
          // 投资收益、投资成本
          double profit = params[0];
          double cost = params[1];
          if (cost == 0) throw Exception('投资成本不能为0');
          return (profit / cost) * 100; // 返回百分比
        }
        throw Exception('投资回报率需要2个参数：投资收益、投资成本');
      
      // 新增金融计算功能
      case '抵押贷款':
      case 'mortgage':
        if (params.length == 4) {
          // 房价、首付比例、贷款年数、年利率
          double housePrice = params[0];
          double downPaymentRate = params[1] / 100; // 转换为小数
          double years = params[2];
          double annualRate = params[3] / 100; // 转换为小数
          
          double downPayment = housePrice * downPaymentRate;
          double loanAmount = housePrice - downPayment;
          double monthlyRate = annualRate / 12;
          double months = years * 12;
          
          if (monthlyRate == 0) {
            return loanAmount / months; // 无利息情况
          }
          
          // 等额本息月供计算公式
          return loanAmount * (monthlyRate * math.pow(1 + monthlyRate, months)) / 
                 (math.pow(1 + monthlyRate, months) - 1);
        }
        throw Exception('抵押贷款计算需要4个参数：房价、首付比例(%)、贷款年数、年利率(%)');
      
      case '年金计算':
      case 'annuity':
        if (params.length == 3) {
          // 每期支付、年利率、期数
          double payment = params[0];
          double annualRate = params[1] / 100; // 转换为小数
          double periods = params[2];
          
          if (annualRate == 0) {
            return payment * periods; // 无利息情况
          }
          
          // 年金现值计算公式
          return payment * ((1 - math.pow(1 + annualRate, -periods)) / annualRate);
        }
        throw Exception('年金计算需要3个参数：每期支付、年利率(%)、期数');
      
      case '通胀调整':
      case 'inflation':
        if (params.length == 3) {
          // 当前金额、通胀率、年数
          double currentAmount = params[0];
          double inflationRate = params[1] / 100; // 转换为小数
          double years = params[2];
          
          // 通胀调整后的金额 = 当前金额 * (1 + 通胀率)^年数
          return currentAmount * math.pow(1 + inflationRate, years);
        }
        throw Exception('通胀调整需要3个参数：当前金额、通胀率(%)、年数');
      
      case '净现值':
      case 'npv':
        if (params.length >= 2) {
          // 第一个参数是折现率，后续参数是现金流
          double discountRate = params[0] / 100; // 转换为小数
          double npv = 0;
          
          for (int i = 1; i < params.length; i++) {
            npv += params[i] / math.pow(1 + discountRate, i).toDouble();
          }
          
          return npv;
        }
        throw Exception('净现值计算至少需要2个参数：折现率(%)、现金流...');
      
      case '内部收益率':
      case 'irr':
        if (params.length >= 2) {
          // 使用牛顿迭代法计算IRR（简化版本）
          double initialGuess = 0.1; // 初始猜测值10%
          double tolerance = 0.0001;
          int maxIterations = 100;
          
          for (int iter = 0; iter < maxIterations; iter++) {
            double npv = 0;
            double derivative = 0;
            
            for (int i = 0; i < params.length; i++) {
              double factor = math.pow(1 + initialGuess, i).toDouble();
              npv += params[i] / factor;
              if (i > 0) {
                derivative -= i * params[i] / (factor * (1 + initialGuess));
              }
            }
            
            if (npv.abs() < tolerance) {
              return initialGuess * 100; // 返回百分比
            }
            
            if (derivative.abs() < tolerance) {
              break; // 避免除零
            }
            
            initialGuess = initialGuess - npv / derivative;
          }
          
          return initialGuess * 100; // 返回百分比
        }
        throw Exception('内部收益率计算至少需要2个现金流参数');
      
      case '债券价格':
      case 'bond':
        if (params.length == 4) {
          // 面值、票面利率、市场利率、年数
          double faceValue = params[0];
          double couponRate = params[1] / 100; // 转换为小数
          double marketRate = params[2] / 100; // 转换为小数
          double years = params[3];
          
          double couponPayment = faceValue * couponRate;
          double presentValueOfCoupons = 0;
          
          // 计算票息的现值
          for (int i = 1; i <= years; i++) {
            presentValueOfCoupons += couponPayment / math.pow(1 + marketRate, i).toDouble();
          }
          
          // 计算面值的现值
          double presentValueOfFace = faceValue / math.pow(1 + marketRate, years).toDouble();
          
          return presentValueOfCoupons + presentValueOfFace;
        }
        throw Exception('债券价格计算需要4个参数：面值、票面利率(%)、市场利率(%)、年数');
      
      case '期权价值':
      case 'option':
        if (params.length == 5) {
          // 使用简化的Black-Scholes公式
          // 标的价格、执行价格、无风险利率、波动率、到期时间
          double stockPrice = params[0];
          double strikePrice = params[1];
          double riskFreeRate = params[2] / 100; // 转换为小数
          double volatility = params[3] / 100; // 转换为小数
          double timeToExpiry = params[4];
          
          // 简化计算（实际Black-Scholes需要正态分布函数）
          double d1 = (math.log(stockPrice / strikePrice) + 
                      (riskFreeRate + 0.5 * volatility * volatility) * timeToExpiry) /
                     (volatility * math.sqrt(timeToExpiry));
          
          // 近似计算看涨期权价值
          double callValue = stockPrice - strikePrice * math.exp(-riskFreeRate * timeToExpiry);
          return math.max(0, callValue).toDouble();
        }
        throw Exception('期权价值计算需要5个参数：标的价格、执行价格、无风险利率(%)、波动率(%)、到期时间');
      
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
      // 中文函数名描述
      case '平均值':
      case '平均数':
        return '平均值 ${params.join(', ')}';
      case '标准差':
        return '标准差 ${params.join(', ')}';
      case '方差':
        return '方差 ${params.join(', ')}';
      case '中位数':
        return '中位数 ${params.join(', ')}';
      case '最大值':
        return '最大值 ${params.join(', ')}';
      case '最小值':
        return '最小值 ${params.join(', ')}';
      case '求和':
        return '求和 ${params.join(', ')}';
      case '组合':
        return '组合 C(${params[0].toInt()}, ${params[1].toInt()})';
      case '排列':
        return '排列 P(${params[0].toInt()}, ${params[1].toInt()})';
      case '阶乘':
        return '阶乘 ${params[0].toInt()}!';
      case '随机数':
        if (params.isEmpty) {
          return '随机数 [0,1)';
        } else if (params.length == 1) {
          return '随机数 [0,${params[0].toInt()})';
        } else {
          return '随机数 [${params[0].toInt()},${params[1].toInt()}]';
        }
      case '百分位数':
        return '百分位数 ${params[0]}% of ${params.sublist(1).join(', ')}';
      case '线性回归':
        return '线性回归 ${params.length ~/ 2}个数据点，斜率';
      
      // 英文函数名描述
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
      
      case '抵押贷款':
      case 'mortgage':
        return '抵押贷款 房价${params[0]}，首付比例${params[1]}%，贷款年数${params[2]}，年利率${params[3]}%';
      
      case '年金计算':
      case 'annuity':
        return '年金计算 每期支付${params[0]}，年利率${params[1]}%，期数${params[2]}';
      
      case '通胀调整':
      case 'inflation':
        return '通胀调整 当前金额${params[0]}，通胀率${params[1]}%，年数${params[2]}';
      
      case '净现值':
      case 'npv':
        return '净现值计算 折现率${params[0]}%，现金流...';
      
      case '内部收益率':
      case 'irr':
        return '内部收益率计算 现金流...';
      
      case '债券价格':
      case 'bond':
        return '债券价格计算 面值${params[0]}，票面利率${params[1]}%，市场利率${params[2]}%，年数${params[3]}';
      
      case '期权价值':
      case 'option':
        return '期权价值计算 标的价格${params[0]}，执行价格${params[1]}，无风险利率${params[2]}%，波动率${params[3]}%，到期时间${params[4]}';
      
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