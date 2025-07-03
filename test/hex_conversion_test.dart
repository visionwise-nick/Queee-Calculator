import 'package:flutter_test/flutter_test.dart';
import 'package:queee_calculator/core/calculator_engine.dart';

void main() {
  group('十六进制转换测试', () {
    late CalculatorEngine engine;
    
    setUp(() {
      engine = CalculatorEngine();
    });
    
    test('十六进制转换 - 基本测试', () {
      // 测试255转十六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '255',
      ));
      expect(state.display, '255');
      
      // 执行十六进制转换
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2hex(x)',
      ));
      
      // 验证显示结果
      expect(state.display, '0xFF');
      expect(state.displayFormat, 'hex');
      expect(state.rawResult, 'FF');
      expect(state.numericValue, 255.0);
    });
    
    test('十六进制转换 - 多个数值', () {
      // 测试16转十六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '16',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2hex(x)',
      ));
      
      expect(state.display, '0x10');
      expect(state.rawResult, '10');
      expect(state.numericValue, 16.0);
    });
    
    test('十六进制转换 - 大数值', () {
      // 测试4095转十六进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '4095',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2hex(x)',
      ));
      
      expect(state.display, '0xFFF');
      expect(state.rawResult, 'FFF');
      expect(state.numericValue, 4095.0);
    });
    
    test('二进制转换测试', () {
      // 测试15转二进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '15',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2bin(x)',
      ));
      
      expect(state.display, '0b1111');
      expect(state.displayFormat, 'binary');
      expect(state.rawResult, '1111');
      expect(state.numericValue, 15.0);
    });
    
    test('八进制转换测试', () {
      // 测试64转八进制
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '64',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2oct(x)',
      ));
      
      expect(state.display, '0o100');
      expect(state.displayFormat, 'octal');
      expect(state.rawResult, '100');
      expect(state.numericValue, 64.0);
    });
    
    test('进制转换后继续计算', () {
      // 测试十六进制结果能否继续计算
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '255',
      ));
      
      // 转换为十六进制
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2hex(x)',
      ));
      
      expect(state.display, '0xFF');
      
      // 继续计算：加100
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.operator,
        value: '+',
      ));
      
      // 验证操作符处理后清除了特殊格式
      expect(state.displayFormat, null);
      expect(state.previousValue, '255.0'); // 应该使用数值
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '100',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.equals,
      ));
      
      expect(state.display, '355');
    });
    
    test('输入新数字清除特殊格式', () {
      // 测试输入新数字时清除十六进制显示
      var state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '255',
      ));
      
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.expression,
        expression: 'dec2hex(x)',
      ));
      
      expect(state.display, '0xFF');
      expect(state.displayFormat, 'hex');
      
      // 输入新数字
      state = engine.execute(CalculatorAction(
        type: CalculatorActionType.input,
        value: '5',
      ));
      
      // 验证特殊格式被清除
      expect(state.display, '5');
      expect(state.displayFormat, null);
      expect(state.rawResult, null);
      expect(state.numericValue, null);
    });
  });
} 