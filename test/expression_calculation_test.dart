import 'package:flutter_test/flutter_test.dart';
import 'package:queee_calculator/core/calculator_engine.dart';

void main() {
  group('表达式计算修复测试', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('多乘法运算 - x*x*x', () {
      // 输入5
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      expect(state.display, '5');

      // 执行立方运算 x*x*x
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x*x*x',
      ));
      expect(state.display, '125'); // 5^3 = 125
      expect(state.isError, false);
    });

    test('复杂表达式 - 2*3*4', () {
      // 输入1（作为x的值）
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '1',
      ));
      
      // 执行表达式 2*3*4，这会替换x为1，但主要计算2*3*4
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: '2*3*4',
      ));
      expect(state.display, '24'); // 2*3*4 = 24
      expect(state.isError, false);
    });

    test('除法运算 - x/2/3', () {
      // 输入24
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '24',
      ));
      
      // 执行除法运算 x/2/3
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x/2/3',
      ));
      expect(state.display, '4'); // 24/2/3 = 4
      expect(state.isError, false);
    });

    test('加法运算 - x+10+20', () {
      // 输入5
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      
      // 执行加法运算 x+10+20
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x+10+20',
      ));
      expect(state.display, '35'); // 5+10+20 = 35
      expect(state.isError, false);
    });

    test('减法运算 - x-5-3', () {
      // 输入20
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '20',
      ));
      
      // 执行减法运算 x-5-3
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x-5-3',
      ));
      expect(state.display, '12'); // 20-5-3 = 12
      expect(state.isError, false);
    });

    test('混合运算 - x*2+3*4', () {
      // 输入5
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      
      // 执行混合运算 x*2+3*4
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x*2+3*4',
      ));
      expect(state.display, '22'); // 5*2+3*4 = 10+12 = 22
      expect(state.isError, false);
    });

    test('单位转换 - 公斤转磅 x*2.20462', () {
      // 输入45（公斤）
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '45',
      ));
      
      // 执行转换 x*2.20462
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x*2.20462',
      ));
      expect(double.parse(state.display), closeTo(99.2079, 0.0001));
      expect(state.isError, false);
    });

    test('错误表达式处理', () {
      // 输入5
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      
      // 执行无效表达式
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'invalid_expression',
      ));
      expect(state.isError, true);
      expect(state.display, 'Error');
    });

    test('零除错误处理', () {
      // 输入5
      var state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      
      // 执行除零运算
      state = engine.execute(const CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'x/0',
      ));
      expect(state.isError, true);
      expect(state.display, 'Error');
    });
  });
} 