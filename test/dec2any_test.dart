import 'package:flutter_test/flutter_test.dart';
import 'package:queee_calculator/core/calculator_engine.dart';

void main() {
  group('任意进制转换测试', () {
    late CalculatorEngine engine;
    
    setUp(() {
      engine = CalculatorEngine();
    });
    
    test('dec2any - 六进制转换', () {
      // 测试31转六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '31',
      ));
      expect(state.display, '31');
      
      // 执行六进制转换
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 6)',
      ));
      
      // 验证显示结果 (31 in base 6 is 51)
      expect(state.display, '51');
      expect(state.displayFormat, 'custom');
      expect(state.rawResult, '51');
      expect(state.numericValue, 31.0);
    });
    
    test('dec2any - 三进制转换', () {
      // 测试27转三进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '27',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 3)',
      ));
      
      // 验证显示结果 (27 in base 3 is 1000)
      expect(state.display, '1000');
      expect(state.displayFormat, 'custom');
      expect(state.rawResult, '1000');
      expect(state.numericValue, 27.0);
    });
    
    test('dec2any - 十二进制转换', () {
      // 测试143转十二进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '143',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 12)',
      ));
      
      // 验证显示结果 (143 in base 12 is BB)
      expect(state.display, 'BB');
      expect(state.displayFormat, 'custom');
      expect(state.rawResult, 'BB');
      expect(state.numericValue, 143.0);
    });
    
    test('dec2any - 三十六进制转换', () {
      // 测试1295转三十六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '1295',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 36)',
      ));
      
      // 验证显示结果 (1295 in base 36 is ZZ)
      expect(state.display, 'ZZ');
      expect(state.displayFormat, 'custom');
      expect(state.rawResult, 'ZZ');
      expect(state.numericValue, 1295.0);
    });
    
    test('dec2any - 二进制转换（验证前缀）', () {
      // 测试15转二进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '15',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 2)',
      ));
      
      // 验证显示结果带前缀
      expect(state.display, '0b1111');
      expect(state.displayFormat, 'binary');
      expect(state.rawResult, '1111');
      expect(state.numericValue, 15.0);
    });
    
    test('dec2any - 十六进制转换（验证前缀）', () {
      // 测试255转十六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '255',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 16)',
      ));
      
      // 验证显示结果带前缀
      expect(state.display, '0xFF');
      expect(state.displayFormat, 'hex');
      expect(state.rawResult, 'FF');
      expect(state.numericValue, 255.0);
    });
    
    test('dec2any - 错误处理', () {
      // 测试无效进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '10',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 1)',
      ));
      
      // 验证显示错误
      expect(state.display, 'Error');
      expect(state.isError, true);
    });
    
    test('dec2any - 继续计算', () {
      // 测试进制转换后继续计算
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '100',
      ));
      
      // 转换为七进制
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2any(x, 7)',
      ));
      
      expect(state.display, '202'); // 100 in base 7 is 202
      
      // 继续计算：加50
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.operator,
        value: '+',
      ));
      
      // 验证操作符处理后清除了特殊格式
      expect(state.displayFormat, null);
      expect(state.previousValue, '100.0'); // 应该使用原始数值
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '50',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.equals,
      ));
      
      expect(state.display, '150');
    });
  });
} 