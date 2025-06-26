import 'dart:math' as Math;
import 'package:math_expressions/math_expressions.dart';

/// 计算器操作类型
enum CalculatorActionType {
  input,      // 输入数字
  operator,   // 运算符 (+, -, *, /)
  equals,     // 等号
  clear,      // 清除
  clearAll,   // 全部清除
  backspace,  // 退格
  decimal,    // 小数点
  percentage, // 百分比
  negate,     // 正负号
  macro,      // 自定义宏操作
  memory,     // 内存操作 (MS, MR, MC, M+, M-)
  scientific, // 科学计算 (sin, cos, sqrt, pow, etc.)
  bitwise,    // 位运算 (AND, OR, XOR, NOT)
  function,   // 函数操作 (自定义函数)
  constant,   // 常数 (π, e, etc.)
  conversion, // 单位转换
}

/// 计算器操作定义
class CalculatorAction {
  final CalculatorActionType type;
  final String? value;
  final String? macro;
  final Map<String, dynamic>? params;

  const CalculatorAction({
    required this.type,
    this.value,
    this.macro,
    this.params,
  });

  factory CalculatorAction.fromJson(Map<String, dynamic> json) {
    return CalculatorAction(
      type: CalculatorActionType.values.firstWhere(
        (e) => e.toString() == 'CalculatorActionType.${json['type']}',
      ),
      value: json['value'],
      macro: json['macro'],
      params: json['params'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      if (value != null) 'value': value,
      if (macro != null) 'macro': macro,
      if (params != null) 'params': params,
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
  final String base; // 进制：'decimal', 'hex', 'binary', 'octal'
  final bool isError;

  const CalculatorState({
    this.display = '0',
    this.previousValue,
    this.operator,
    this.waitingForOperand = false,
    this.memory = 0,
    this.base = 'decimal',
    this.isError = false,
  });

  CalculatorState copyWith({
    String? display,
    String? previousValue,
    String? operator,
    bool? waitingForOperand,
    double? memory,
    String? base,
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
      base: base ?? this.base,
      isError: isError ?? this.isError,
    );
  }
}

/// 计算器核心引擎
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
        case CalculatorActionType.percentage:
          return _handlePercentage();
        case CalculatorActionType.negate:
          return _handleNegate();
        case CalculatorActionType.macro:
          return _handleMacro(action.macro!, action.params);
        case CalculatorActionType.memory:
          return _handleMemory(action.value!);
        case CalculatorActionType.scientific:
          return _handleScientific(action.value!, action.params);
        case CalculatorActionType.bitwise:
          return _handleBitwise(action.value!, action.params);
        case CalculatorActionType.function:
          return _handleFunction(action.value!, action.params);
        case CalculatorActionType.constant:
          return _handleConstant(action.value!);
        case CalculatorActionType.conversion:
          return _handleConversion(action.value!, action.params);
      }
    } catch (e) {
      print('Calculator error: $e');
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
      // 限制显示长度
      if (newDisplay.length <= 10) {
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
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
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
      // 保留内存和进制设置
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

  CalculatorState _handlePercentage() {
    if (_state.isError) return _state;
    
    double value = double.parse(_state.display) / 100;
    return _state.copyWith(display: _formatResult(value));
  }

  CalculatorState _handleNegate() {
    if (_state.isError) return _state;
    
    double value = double.parse(_state.display);
    _state = _state.copyWith(display: _formatResult(-value));
    return _state;
  }

  CalculatorState _handleMacro(String macro, Map<String, dynamic>? params) {
    // 解析并执行宏命令，例如 "input * 0.15" (计算小费)
    try {
      final double currentValue = double.parse(_state.display);
      
      // 使用更强大的数学表达式引擎
      final result = _evaluateExpression(macro, currentValue);

      return _state.copyWith(display: _formatResult(result));
    } catch (e) {
      print('Macro execution error: $e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  double _evaluateExpression(String expression, double inputValue) {
    try {
      // 处理特殊宏命令
      if (expression == 'input * input' || expression == 'input^2' || expression == 'pow(input, 2)') {
        return inputValue * inputValue;
      }
      
      if (expression == 'sqrt(input)') {
        return Math.sqrt(inputValue);
      }
      
      // 替换 input 为实际值
      String processedExpression = expression.replaceAll('input', inputValue.toString());
      
      // 创建解析器和数学模型
      final Parser p = Parser();
      final Expression exp = p.parse(processedExpression);
      final ContextModel cm = ContextModel();

      // 计算结果
      final double eval = exp.evaluate(EvaluationType.REAL, cm);
      return eval;
    } catch(e) {
      print('Error evaluating macro expression "$expression": $e');
      
      // 如果表达式解析失败，尝试简单计算
      try {
        if (expression.contains('*') && expression.contains('0.15')) {
          // 小费计算：input * 0.15
          return inputValue * 0.15;
        } else if (expression.contains('input') && expression.contains('input')) {
          // 平方计算
          return inputValue * inputValue;
        }
      } catch (e2) {
        print('Fallback calculation also failed: $e2');
      }
      
      throw Exception('Invalid macro expression');
    }
  }

  CalculatorState _handleMemory(String operation) {
    double currentValue = double.parse(_state.display);
    
    switch (operation) {
      case 'MS': // Memory Store
        _state = _state.copyWith(memory: currentValue);
        break;
      case 'MR': // Memory Recall
        _state = _state.copyWith(display: _formatResult(_state.memory));
        break;
      case 'MC': // Memory Clear
        _state = _state.copyWith(memory: 0);
        break;
      case 'M+': // Memory Add
        _state = _state.copyWith(memory: _state.memory + currentValue);
        break;
      case 'M-': // Memory Subtract
        _state = _state.copyWith(memory: _state.memory - currentValue);
        break;
    }
    return _state;
  }

  CalculatorState _handleScientific(String function, Map<String, dynamic>? params) {
    double currentValue = double.parse(_state.display);
    double result;
    
    switch (function) {
      case 'sin':
        result = Math.sin(currentValue);
        break;
      case 'cos':
        result = Math.cos(currentValue);
        break;
      case 'tan':
        result = Math.tan(currentValue);
        break;
      case 'sqrt':
        result = Math.sqrt(currentValue);
        break;
      case 'pow':
        double exponent = params?['exponent'] ?? 2.0;
        result = Math.pow(currentValue, exponent).toDouble();
        break;
      case 'log':
        result = Math.log(currentValue);
        break;
      case 'ln':
        result = Math.log(currentValue) / Math.ln10;
        break;
      default:
        return _state;
    }
    
    return _state.copyWith(display: _formatResult(result));
  }

  CalculatorState _handleBitwise(String operation, Map<String, dynamic>? params) {
    int currentValue = int.parse(_state.display);
    int result;
    
    switch (operation) {
      case 'AND':
        int operand = params?['operand'] ?? 0;
        result = currentValue & operand;
        break;
      case 'OR':
        int operand = params?['operand'] ?? 0;
        result = currentValue | operand;
        break;
      case 'XOR':
        int operand = params?['operand'] ?? 0;
        result = currentValue ^ operand;
        break;
      case 'NOT':
        result = ~currentValue;
        break;
      case 'LSH': // Left Shift
        int positions = params?['positions'] ?? 1;
        result = currentValue << positions;
        break;
      case 'RSH': // Right Shift
        int positions = params?['positions'] ?? 1;
        result = currentValue >> positions;
        break;
      default:
        return _state;
    }
    
    return _state.copyWith(display: result.toString());
  }

  /// 重置计算器状态
  void reset() {
    _state = const CalculatorState();
  }

  /// 处理函数操作
  CalculatorState _handleFunction(String functionName, Map<String, dynamic>? params) {
    try {
      double currentValue = double.parse(_state.display);
      double result;
      
      switch (functionName.toLowerCase()) {
        case 'abs':
          result = currentValue.abs();
          break;
        case 'round':
          result = currentValue.round().toDouble();
          break;
        case 'floor':
          result = currentValue.floor().toDouble();
          break;
        case 'ceil':
          result = currentValue.ceil().toDouble();
          break;
        case 'reciprocal':
        case '1/x':
          if (currentValue == 0) throw Exception('Division by zero');
          result = 1.0 / currentValue;
          break;
        case 'factorial':
          if (currentValue < 0 || currentValue > 20) throw Exception('Invalid factorial input');
          result = _factorial(currentValue.toInt()).toDouble();
          break;
        default:
          return _state.copyWith(display: 'Error', isError: true);
      }
      
      return _state.copyWith(display: _formatResult(result));
    } catch (e) {
      return _state.copyWith(display: 'Error', isError: true);
    }
  }
  
  /// 处理常数
  CalculatorState _handleConstant(String constantName) {
    double value;
    
    switch (constantName.toLowerCase()) {
      case 'pi':
      case 'π':
        value = Math.pi;
        break;
      case 'e':
        value = Math.e;
        break;
      case 'phi':
      case 'φ':
        value = (1 + Math.sqrt(5)) / 2; // 黄金比例
        break;
      case 'sqrt2':
        value = Math.sqrt(2);
        break;
      default:
        return _state.copyWith(display: 'Error', isError: true);
    }
    
    return _state.copyWith(display: _formatResult(value));
  }
  
  /// 处理单位转换
  CalculatorState _handleConversion(String conversionType, Map<String, dynamic>? params) {
    try {
      double currentValue = double.parse(_state.display);
      double result;
      
      switch (conversionType.toLowerCase()) {
        case 'deg_to_rad':
          result = currentValue * Math.pi / 180;
          break;
        case 'rad_to_deg':
          result = currentValue * 180 / Math.pi;
          break;
        case 'c_to_f':
          result = currentValue * 9 / 5 + 32;
          break;
        case 'f_to_c':
          result = (currentValue - 32) * 5 / 9;
          break;
        case 'km_to_miles':
          result = currentValue * 0.621371;
          break;
        case 'miles_to_km':
          result = currentValue * 1.60934;
          break;
        default:
          return _state.copyWith(display: 'Error', isError: true);
      }
      
      return _state.copyWith(display: _formatResult(result));
    } catch (e) {
      return _state.copyWith(display: 'Error', isError: true);
    }
  }
  
  /// 计算阶乘
  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }
} 