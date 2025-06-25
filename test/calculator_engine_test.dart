import 'package:flutter_test/flutter_test.dart';
import 'package:queee_calculator/core/calculator_engine.dart';

void main() {
  group('计算器引擎测试', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('基本输入测试', () {
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '5'));
      expect(state.display, '5');
      
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      expect(state.display, '53');
    });

    test('基本加法运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '5'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, '8');
    });

    test('基本减法运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '10'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '-'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, '7');
    });

    test('基本乘法运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '6'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '*'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '7'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, '42');
    });

    test('基本除法运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '15'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '/'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, '5');
    });

    test('除零错误处理', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '10'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '/'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '0'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, 'Error');
      expect(state.isError, true);
    });

    test('小数点操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.decimal));
      expect(state.display, '3.');
      
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '14'));
      expect(state.display, '3.14');
    });

    test('百分比操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '50'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.percentage));
      expect(state.display, '0.5');
    });

    test('正负号切换', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '42'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.negate));
      expect(state.display, '-42');
      
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.negate));
      expect(state.display, '42');
    });

    test('清除操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '123'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.clear));
      expect(state.display, '0');
    });

    test('全部清除操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '5'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      expect(state.display, '0');
      expect(state.previousValue, null);
      expect(state.operator, null);
    });

    test('退格操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '123'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(state.display, '12');
      
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(state.display, '1');
      
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(state.display, '0');
    });

    test('连续运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '2'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '*'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '4'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(state.display, '20'); // (2+3)*4 = 20
    });

    test('内存操作', () {
      // 存储到内存
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '42'));
      var state = engine.execute(const CalculatorAction(type: CalculatorActionType.memory, value: 'MS'));
      expect(state.memory, 42.0);
      
      // 从内存读取
      engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '0'));
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.memory, value: 'MR'));
      expect(state.display, '42');
      
      // 内存加
      engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '8'));
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.memory, value: 'M+'));
      expect(state.memory, 50.0);
      
      // 内存减
      engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '10'));
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.memory, value: 'M-'));
      expect(state.memory, 40.0);
      
      // 清除内存
      state = engine.execute(const CalculatorAction(type: CalculatorActionType.memory, value: 'MC'));
      expect(state.memory, 0.0);
    });

    test('宏操作 - 小费计算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '100'));
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.macro, 
        macro: 'input * 0.15'
      ));
      expect(state.display, '15'); // 100的15%小费
    });

    test('科学计算 - 平方根', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '16'));
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.scientific, 
        value: 'sqrt'
      ));
      expect(state.display, '4');
    });

    test('科学计算 - 幂运算', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '2'));
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.scientific, 
        value: 'pow',
        params: {'exponent': 3.0}
      ));
      expect(state.display, '8'); // 2^3 = 8
    });

    test('位运算 - AND操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '12'));
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.bitwise, 
        value: 'AND',
        params: {'operand': 10}
      ));
      expect(state.display, '8'); // 12 & 10 = 8
    });

    test('位运算 - OR操作', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '12'));
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.bitwise, 
        value: 'OR',
        params: {'operand': 10}
      ));
      expect(state.display, '14'); // 12 | 10 = 14
    });

    test('重置状态', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '123'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      engine.reset();
      expect(engine.state.display, '0');
      expect(engine.state.previousValue, null);
      expect(engine.state.operator, null);
    });
  });
} 