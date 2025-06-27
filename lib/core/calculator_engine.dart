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

/// 简化的计算器核心引擎
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

  /// 新的通用表达式处理器 - 支持任意数学表达式
  CalculatorState _handleExpression(String expression) {
    if (_state.isError) return _state;
    
    try {
      double currentValue = double.parse(_state.display);
      print('🔢 表达式计算：当前值=$currentValue, 表达式=$expression');
      
      // 替换表达式中的占位符
      String processedExpression = expression
          .replaceAll('x', currentValue.toString())
          .replaceAll('input', currentValue.toString())
          .replaceAll('value', currentValue.toString());
      
      print('🔢 处理后表达式：$processedExpression');
      
      // 计算表达式结果
      double result = _evaluateExpression(processedExpression);
      print('🔢 计算结果：$result');
      
      return _state.copyWith(display: _formatResult(result));
    } catch (e) {
      print('❌ 表达式计算错误：$e');
      return _state.copyWith(display: 'Error', isError: true);
    }
  }

  /// 强化的表达式计算器 - 支持数学函数
  double _evaluateExpression(String expression) {
    // 移除空格
    expression = expression.replaceAll(' ', '');
    
    // 支持的数学函数
    expression = expression.replaceAllMapped(RegExp(r'sqrt\(([^)]+)\)'), (match) {
      double value = _evaluateExpression(match.group(1)!);
      return math.sqrt(value).toString();
    });
    
    expression = expression.replaceAllMapped(RegExp(r'pow\(([^,]+),([^)]+)\)'), (match) {
      double base = _evaluateExpression(match.group(1)!);
      double exponent = _evaluateExpression(match.group(2)!);
      return math.pow(base, exponent).toString();
    });
    
    // 处理基本算术运算
    return _evaluateBasicExpression(expression);
  }

  double _evaluateBasicExpression(String expression) {
    // 简单的算术表达式计算器
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

  /// 重置计算器状态
  void reset() {
    _state = const CalculatorState();
  }
} 