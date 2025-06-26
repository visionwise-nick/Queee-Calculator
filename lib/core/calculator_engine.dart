import 'dart:math' as Math;

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
  tip,        // 小费计算
  macro,      // 自定义宏操作
  memory,     // 内存操作 (MS, MR, MC, M+, M-)
  scientific, // 科学计算 (sin, cos, sqrt, pow, etc.)
  bitwise,    // 位运算 (AND, OR, XOR, NOT)
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
        orElse: () => CalculatorActionType.input,
      ),
      value: json['value']?.toString(),
      macro: json['macro']?.toString(),
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
        case CalculatorActionType.tip:
          return _handleTip(action.value!);
        case CalculatorActionType.macro:
          return _handleMacro(action.macro!, action.params);
        case CalculatorActionType.memory:
          return _handleMemory(action.value!);
        case CalculatorActionType.scientific:
          return _handleScientific(action.value!, action.params);
        case CalculatorActionType.bitwise:
          return _handleBitwise(action.value!, action.params);
      }
    } catch (e) {
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

  CalculatorState _handleTip(String percentage) {
    if (_state.isError) return _state;
    
    try {
      double value = double.parse(_state.display);
      double tipRate = double.parse(percentage);
      double tipAmount = value * tipRate;
      return _state.copyWith(display: _formatResult(tipAmount));
    } catch (e) {
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  CalculatorState _handleMacro(String macro, Map<String, dynamic>? params) {
    // 解析并执行宏命令，例如 "input * 0.15" (计算小费)
    try {
      double currentValue = double.parse(_state.display);
      String expression = macro.replaceAll('input', currentValue.toString());
      
      // 简单的表达式计算器
      double result = _evaluateExpression(expression);
      return _state.copyWith(display: _formatResult(result));
    } catch (e) {
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  double _evaluateExpression(String expression) {
    // 这里可以实现更复杂的表达式解析
    // 简单示例：支持基本的算术运算
    expression = expression.replaceAll(' ', '');
    
    if (expression.contains('*')) {
      var parts = expression.split('*');
      return double.parse(parts[0]) * double.parse(parts[1]);
    } else if (expression.contains('/')) {
      var parts = expression.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    } else if (expression.contains('+')) {
      var parts = expression.split('+');
      return double.parse(parts[0]) + double.parse(parts[1]);
    } else if (expression.contains('-')) {
      var parts = expression.split('-');
      return double.parse(parts[0]) - double.parse(parts[1]);
    }
    
    return double.parse(expression);
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
} 