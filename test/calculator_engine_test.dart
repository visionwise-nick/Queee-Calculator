import 'package:flutter_test/flutter_test.dart';
import 'package:queee_calculator/core/calculator_engine.dart';

void main() {
  group('CalculatorEngine Tests', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('基础计算测试', () {
      // 输入 2
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '2'));
      expect(engine.state.display, '2');

      // 加法
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      expect(engine.state.operator, '+');

      // 输入 3
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      expect(engine.state.display, '3');

      // 等号
      engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(engine.state.display, '5');
    });

    test('单参数函数测试', () {
      // 输入 4
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '4'));
      expect(engine.state.display, '4');

      // 平方根函数
      engine.execute(const CalculatorAction(type: CalculatorActionType.expression, expression: 'sqrt(x)'));
      expect(engine.state.display, '2');
    });

    test('多参数函数测试 - pow(2,3)', () {
      // 输入 2 (第一个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '2'));
      expect(engine.state.display, '2');

      // 开始多参数函数 pow
      engine.execute(const CalculatorAction(type: CalculatorActionType.multiParamFunction, value: 'pow'));
      expect(engine.state.isInputtingFunction, true);
      expect(engine.state.currentFunction, 'pow');
      expect(engine.state.functionParameters.length, 1);
      expect(engine.state.functionParameters[0], 2.0);

      // 输入 3 (第二个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      expect(engine.state.display, '3');

      // 执行函数
      engine.execute(const CalculatorAction(type: CalculatorActionType.functionExecute));
      expect(engine.state.display, '8'); // 2^3 = 8
      expect(engine.state.isInputtingFunction, false);
    });

    test('多参数函数测试 - max(5,3,8)', () {
      // 输入 5 (第一个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '5'));
      
      // 开始多参数函数 max
      engine.execute(const CalculatorAction(type: CalculatorActionType.multiParamFunction, value: 'max'));
      
      // 输入 3 (第二个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      
      // 参数分隔符
      engine.execute(const CalculatorAction(type: CalculatorActionType.parameterSeparator));
      expect(engine.state.functionParameters.length, 2);
      expect(engine.state.functionParameters[1], 3.0);
      
      // 输入 8 (第三个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '8'));
      
      // 执行函数
      engine.execute(const CalculatorAction(type: CalculatorActionType.functionExecute));
      expect(engine.state.display, '8'); // max(5,3,8) = 8
    });

    test('多参数函数测试 - log(100,10)', () {
      // 输入 100 (第一个参数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '100'));
      
      // 开始多参数函数 log
      engine.execute(const CalculatorAction(type: CalculatorActionType.multiParamFunction, value: 'log'));
      
      // 输入 10 (底数)
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '10'));
      
      // 执行函数
      engine.execute(const CalculatorAction(type: CalculatorActionType.functionExecute));
      expect(engine.state.display, '2'); // log₁₀(100) = 2
    });

    test('基本运算测试', () {
      // 乘法测试
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '6'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '*'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '7'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(engine.state.display, '42');

      // 重置
      engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      
      // 除法测试
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '15'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '/'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(engine.state.display, '5');
    });

    test('错误处理测试', () {
      // 除零错误
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '5'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '/'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '0'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.equals));
      expect(engine.state.isError, true);
    });

    test('小数点测试', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.decimal));
      expect(engine.state.display, '3.');
      
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '14'));
      expect(engine.state.display, '3.14');
    });

    test('正负号测试', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '42'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.negate));
      expect(engine.state.display, '-42');
      
      engine.execute(const CalculatorAction(type: CalculatorActionType.negate));
      expect(engine.state.display, '42');
    });

    test('清除功能测试', () {
      // 输入一些数据
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '123'));
      expect(engine.state.display, '123');

      // 清除
      engine.execute(const CalculatorAction(type: CalculatorActionType.clear));
      expect(engine.state.display, '0');

      // 输入更多数据
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '456'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.operator, value: '+'));
      
      // 清除所有
      engine.execute(const CalculatorAction(type: CalculatorActionType.clearAll));
      expect(engine.state.display, '0');
      expect(engine.state.operator, null);
      expect(engine.state.previousValue, null);
    });

    test('退格测试', () {
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '123'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(engine.state.display, '12');
      
      engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(engine.state.display, '1');
      
      engine.execute(const CalculatorAction(type: CalculatorActionType.backspace));
      expect(engine.state.display, '0');
    });

    test('显示文本测试', () {
      // 测试普通显示
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '42'));
      expect(engine.state.getFunctionDisplayText(), '42');

      // 测试函数显示
      engine.execute(const CalculatorAction(type: CalculatorActionType.multiParamFunction, value: 'pow'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '3'));
      expect(engine.state.getFunctionDisplayText(), 'pow(42, 3)');
    });

    test('科学函数测试', () {
      // 三角函数
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '0'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.expression, expression: 'sin(x)'));
      expect(engine.state.display, '0');

      engine.reset();
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '1'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.expression, expression: 'cos(x)'));
      expect(double.parse(engine.state.display), closeTo(0.5403, 0.001));

      // 指数函数
      engine.reset();
      engine.execute(const CalculatorAction(type: CalculatorActionType.input, value: '2'));
      engine.execute(const CalculatorAction(type: CalculatorActionType.expression, expression: 'exp(x)'));
      expect(double.parse(engine.state.display), closeTo(7.389, 0.001));
    });
  });
} 