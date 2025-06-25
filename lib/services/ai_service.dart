import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';

class AIService {
  // 模拟的API端点，在实际应用中应该替换为真正的AI服务
  static const String _baseUrl = 'https://api.example.com';
  static const String _apiKey = 'your-api-key';

  /// 根据用户描述生成计算器配置
  static Future<CalculatorConfig?> generateCalculatorFromPrompt(String userPrompt) async {
    try {
      // 构建发送给AI的prompt
      final systemPrompt = _buildSystemPrompt();
      final fullPrompt = '$systemPrompt\n\n用户需求：$userPrompt';

      // 模拟AI响应（在实际应用中，这里应该调用真实的AI API）
      final generatedConfig = await _simulateAIResponse(userPrompt);
      
      if (generatedConfig != null) {
        return generatedConfig.copyWith(
          authorPrompt: userPrompt,
          createdAt: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('AI服务错误: $e');
      return null;
    }
  }

  /// 构建系统提示词
  static String _buildSystemPrompt() {
    return '''
你是一个专业的计算器设计师AI助手。你的任务是根据用户的自然语言描述，生成一个完整的计算器配置JSON。

请遵循以下DSL规范：

1. 计算器配置结构：
{
  "id": "唯一标识符",
  "name": "计算器名称",
  "description": "简短描述",
  "version": "1.0.0",
  "createdAt": "当前时间ISO格式",
  "authorPrompt": "用户原始需求",
  "theme": { 主题配置 },
  "layout": { 布局配置 }
}

2. 主题配置包含：
- backgroundColor: 背景色 (十六进制)
- displayBackgroundColor: 显示区背景色
- displayTextColor: 显示区文字颜色
- primaryButtonColor: 主按钮颜色
- primaryButtonTextColor: 主按钮文字颜色
- secondaryButtonColor: 副按钮颜色
- secondaryButtonTextColor: 副按钮文字颜色
- operatorButtonColor: 运算符按钮颜色
- operatorButtonTextColor: 运算符按钮文字颜色
- fontSize: 字体大小
- buttonBorderRadius: 按钮圆角
- hasGlowEffect: 是否有发光效果
- shadowColor: 阴影颜色

3. 布局配置包含：
- name: 布局名称
- rows: 行数 (通常为6)
- columns: 列数 (通常为4)
- buttons: 按钮数组

4. 按钮配置包含：
- id: 按钮唯一标识
- label: 按钮显示文字
- action: 操作定义
- gridPosition: 网格位置 {row, column, columnSpan?}
- type: 按钮类型 (primary/secondary/operator/special)
- customColor?: 自定义颜色
- customTextColor?: 自定义文字颜色
- isWide?: 是否为宽按钮

5. 操作类型：
- input: 数字输入
- operator: 运算符 (+, -, *, /)
- equals: 等号
- clear/clearAll: 清除
- decimal: 小数点
- percentage: 百分比
- negate: 正负号
- macro: 自定义宏 (如小费计算)
- memory: 内存操作
- scientific: 科学计算
- bitwise: 位运算

请根据用户需求生成完整、有效的JSON配置。确保：
- 颜色搭配合理美观
- 按钮布局符合使用习惯
- 功能完整可用
- JSON格式正确

只返回纯JSON，不要包含任何解释文字。
''';
  }

  /// 模拟AI响应（在实际应用中替换为真实API调用）
  static Future<CalculatorConfig?> _simulateAIResponse(String userPrompt) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));

    // 根据关键词生成不同的配置
    if (userPrompt.contains('赛博朋克') || userPrompt.contains('霓虹') || userPrompt.contains('未来')) {
      return _generateCyberpunkCalculator();
    } else if (userPrompt.contains('小费') || userPrompt.contains('15%') || userPrompt.contains('税')) {
      return _generateTipCalculator();
    } else if (userPrompt.contains('程序员') || userPrompt.contains('十六进制') || userPrompt.contains('位运算')) {
      return _generateProgrammerCalculator();
    } else if (userPrompt.contains('猫') || userPrompt.contains('可爱') || userPrompt.contains('粉色')) {
      return _generateCuteCalculator();
    } else if (userPrompt.contains('简洁') || userPrompt.contains('白色') || userPrompt.contains('minimalist')) {
      return _generateMinimalCalculator();
    } else {
      // 默认生成一个经典风格的计算器
      return _generateClassicCalculator();
    }
  }

  /// 生成赛博朋克风格计算器
  static CalculatorConfig _generateCyberpunkCalculator() {
    return CalculatorConfig(
      id: 'ai_cyberpunk_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 赛博朋克计算器',
      description: 'AI生成的赛博朋克风格计算器，黑底霓虹蓝按键',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: 'AI 赛博朋克',
        backgroundColor: '#0a0a0a',
        displayBackgroundColor: '#1a1a2e',
        displayTextColor: '#00f5ff',
        primaryButtonColor: '#16213e',
        primaryButtonTextColor: '#00f5ff',
        secondaryButtonColor: '#0f3460',
        secondaryButtonTextColor: '#00f5ff',
        operatorButtonColor: '#e94560',
        operatorButtonTextColor: '#ffffff',
        fontSize: 24.0,
        buttonBorderRadius: 12.0,
        hasGlowEffect: true,
        shadowColor: '#00f5ff',
      ),
      layout: CalculatorLayout.fromJson({
        'name': 'AI 赛博朋克布局',
        'rows': 6,
        'columns': 4,
        'hasDisplay': true,
        'buttons': _getStandardButtons(),
      }),
    );
  }

  /// 生成小费计算器
  static CalculatorConfig _generateTipCalculator() {
    final buttons = _getStandardButtons();
    // 替换百分比按钮为小费计算按钮
    final tipButtonIndex = buttons.indexWhere((b) => b['id'] == 'percentage');
    if (tipButtonIndex >= 0) {
      buttons[tipButtonIndex] = {
        'id': 'tip_15',
        'label': '小费15%',
        'action': {
          'type': 'macro',
          'macro': 'input * 0.15'
        },
        'gridPosition': {'row': 1, 'column': 2},
        'type': 'special',
        'customColor': '#28a745',
        'customTextColor': '#ffffff'
      };
    }

    return CalculatorConfig(
      id: 'ai_tip_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 小费计算器',
      description: 'AI生成的小费计算器，一键计算15%小费',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: 'AI 小费计算',
        backgroundColor: '#f8f9fa',
        displayBackgroundColor: '#ffffff',
        displayTextColor: '#212529',
        primaryButtonColor: '#e9ecef',
        primaryButtonTextColor: '#212529',
        secondaryButtonColor: '#6c757d',
        secondaryButtonTextColor: '#ffffff',
        operatorButtonColor: '#007bff',
        operatorButtonTextColor: '#ffffff',
        fontSize: 22.0,
        buttonBorderRadius: 8.0,
        hasGlowEffect: false,
      ),
      layout: CalculatorLayout.fromJson({
        'name': 'AI 小费布局',
        'rows': 6,
        'columns': 4,
        'hasDisplay': true,
        'buttons': buttons,
      }),
    );
  }

  /// 生成程序员计算器
  static CalculatorConfig _generateProgrammerCalculator() {
    return CalculatorConfig(
      id: 'ai_programmer_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 程序员计算器',
      description: 'AI生成的程序员专用计算器，支持十六进制和位运算',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: 'AI 程序员',
        backgroundColor: '#2d3748',
        displayBackgroundColor: '#1a202c',
        displayTextColor: '#e2e8f0',
        primaryButtonColor: '#4a5568',
        primaryButtonTextColor: '#e2e8f0',
        secondaryButtonColor: '#2d3748',
        secondaryButtonTextColor: '#e2e8f0',
        operatorButtonColor: '#3182ce',
        operatorButtonTextColor: '#ffffff',
        fontSize: 20.0,
        buttonBorderRadius: 6.0,
        hasGlowEffect: false,
      ),
      layout: CalculatorLayout.fromJson({
        'name': 'AI 程序员布局',
        'rows': 6,
        'columns': 4,
        'hasDisplay': true,
        'buttons': _getProgrammerButtons(),
      }),
    );
  }

  /// 生成可爱计算器
  static CalculatorConfig _generateCuteCalculator() {
    return CalculatorConfig(
      id: 'ai_cute_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 可爱计算器',
      description: 'AI生成的可爱粉色主题计算器',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: 'AI 可爱粉',
        backgroundColor: '#ffeef8',
        displayBackgroundColor: '#ffffff',
        displayTextColor: '#d6336c',
        primaryButtonColor: '#f8bbd9',
        primaryButtonTextColor: '#d6336c',
        secondaryButtonColor: '#e91e63',
        secondaryButtonTextColor: '#ffffff',
        operatorButtonColor: '#ff6b9d',
        operatorButtonTextColor: '#ffffff',
        fontSize: 24.0,
        buttonBorderRadius: 16.0,
        hasGlowEffect: true,
        shadowColor: '#f8bbd9',
      ),
      layout: CalculatorLayout.fromJson({
        'name': 'AI 可爱布局',
        'rows': 6,
        'columns': 4,
        'hasDisplay': true,
        'buttons': _getStandardButtons(),
      }),
    );
  }

  /// 生成简洁计算器
  static CalculatorConfig _generateMinimalCalculator() {
    return CalculatorConfig(
      id: 'ai_minimal_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 简洁计算器',
      description: 'AI生成的极简白色主题计算器',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: 'AI 极简白',
        backgroundColor: '#ffffff',
        displayBackgroundColor: '#f5f5f5',
        displayTextColor: '#333333',
        primaryButtonColor: '#ffffff',
        primaryButtonTextColor: '#333333',
        secondaryButtonColor: '#e0e0e0',
        secondaryButtonTextColor: '#333333',
        operatorButtonColor: '#2196f3',
        operatorButtonTextColor: '#ffffff',
        fontSize: 22.0,
        buttonBorderRadius: 4.0,
        hasGlowEffect: false,
      ),
      layout: CalculatorLayout.fromJson({
        'name': 'AI 极简布局',
        'rows': 6,
        'columns': 4,
        'hasDisplay': true,
        'buttons': _getStandardButtons(),
      }),
    );
  }

  /// 生成经典计算器
  static CalculatorConfig _generateClassicCalculator() {
    return CalculatorConfig.createDefault().copyWith(
      id: 'ai_classic_${DateTime.now().millisecondsSinceEpoch}',
      name: 'AI 经典计算器',
      description: 'AI生成的经典黑色主题计算器',
    );
  }

  /// 获取标准按钮布局
  static List<Map<String, dynamic>> _getStandardButtons() {
    return [
      {'id': 'clear', 'label': 'AC', 'action': {'type': 'clearAll'}, 'gridPosition': {'row': 1, 'column': 0}, 'type': 'secondary'},
      {'id': 'negate', 'label': '±', 'action': {'type': 'negate'}, 'gridPosition': {'row': 1, 'column': 1}, 'type': 'secondary'},
      {'id': 'percentage', 'label': '%', 'action': {'type': 'percentage'}, 'gridPosition': {'row': 1, 'column': 2}, 'type': 'secondary'},
      {'id': 'divide', 'label': '÷', 'action': {'type': 'operator', 'value': '/'}, 'gridPosition': {'row': 1, 'column': 3}, 'type': 'operator'},
      {'id': 'seven', 'label': '7', 'action': {'type': 'input', 'value': '7'}, 'gridPosition': {'row': 2, 'column': 0}, 'type': 'primary'},
      {'id': 'eight', 'label': '8', 'action': {'type': 'input', 'value': '8'}, 'gridPosition': {'row': 2, 'column': 1}, 'type': 'primary'},
      {'id': 'nine', 'label': '9', 'action': {'type': 'input', 'value': '9'}, 'gridPosition': {'row': 2, 'column': 2}, 'type': 'primary'},
      {'id': 'multiply', 'label': '×', 'action': {'type': 'operator', 'value': '*'}, 'gridPosition': {'row': 2, 'column': 3}, 'type': 'operator'},
      {'id': 'four', 'label': '4', 'action': {'type': 'input', 'value': '4'}, 'gridPosition': {'row': 3, 'column': 0}, 'type': 'primary'},
      {'id': 'five', 'label': '5', 'action': {'type': 'input', 'value': '5'}, 'gridPosition': {'row': 3, 'column': 1}, 'type': 'primary'},
      {'id': 'six', 'label': '6', 'action': {'type': 'input', 'value': '6'}, 'gridPosition': {'row': 3, 'column': 2}, 'type': 'primary'},
      {'id': 'subtract', 'label': '−', 'action': {'type': 'operator', 'value': '-'}, 'gridPosition': {'row': 3, 'column': 3}, 'type': 'operator'},
      {'id': 'one', 'label': '1', 'action': {'type': 'input', 'value': '1'}, 'gridPosition': {'row': 4, 'column': 0}, 'type': 'primary'},
      {'id': 'two', 'label': '2', 'action': {'type': 'input', 'value': '2'}, 'gridPosition': {'row': 4, 'column': 1}, 'type': 'primary'},
      {'id': 'three', 'label': '3', 'action': {'type': 'input', 'value': '3'}, 'gridPosition': {'row': 4, 'column': 2}, 'type': 'primary'},
      {'id': 'add', 'label': '+', 'action': {'type': 'operator', 'value': '+'}, 'gridPosition': {'row': 4, 'column': 3}, 'type': 'operator'},
      {'id': 'zero', 'label': '0', 'action': {'type': 'input', 'value': '0'}, 'gridPosition': {'row': 5, 'column': 0, 'columnSpan': 2}, 'type': 'primary', 'isWide': true},
      {'id': 'decimal', 'label': '.', 'action': {'type': 'decimal'}, 'gridPosition': {'row': 5, 'column': 2}, 'type': 'primary'},
      {'id': 'equals', 'label': '=', 'action': {'type': 'equals'}, 'gridPosition': {'row': 5, 'column': 3}, 'type': 'operator'},
    ];
  }

  /// 获取程序员按钮布局
  static List<Map<String, dynamic>> _getProgrammerButtons() {
    return [
      {'id': 'clear', 'label': 'AC', 'action': {'type': 'clearAll'}, 'gridPosition': {'row': 1, 'column': 0}, 'type': 'secondary'},
      {'id': 'hex_a', 'label': 'A', 'action': {'type': 'input', 'value': 'A'}, 'gridPosition': {'row': 1, 'column': 1}, 'type': 'special'},
      {'id': 'hex_b', 'label': 'B', 'action': {'type': 'input', 'value': 'B'}, 'gridPosition': {'row': 1, 'column': 2}, 'type': 'special'},
      {'id': 'divide', 'label': '÷', 'action': {'type': 'operator', 'value': '/'}, 'gridPosition': {'row': 1, 'column': 3}, 'type': 'operator'},
      {'id': 'seven', 'label': '7', 'action': {'type': 'input', 'value': '7'}, 'gridPosition': {'row': 2, 'column': 0}, 'type': 'primary'},
      {'id': 'eight', 'label': '8', 'action': {'type': 'input', 'value': '8'}, 'gridPosition': {'row': 2, 'column': 1}, 'type': 'primary'},
      {'id': 'nine', 'label': '9', 'action': {'type': 'input', 'value': '9'}, 'gridPosition': {'row': 2, 'column': 2}, 'type': 'primary'},
      {'id': 'multiply', 'label': '×', 'action': {'type': 'operator', 'value': '*'}, 'gridPosition': {'row': 2, 'column': 3}, 'type': 'operator'},
      {'id': 'four', 'label': '4', 'action': {'type': 'input', 'value': '4'}, 'gridPosition': {'row': 3, 'column': 0}, 'type': 'primary'},
      {'id': 'five', 'label': '5', 'action': {'type': 'input', 'value': '5'}, 'gridPosition': {'row': 3, 'column': 1}, 'type': 'primary'},
      {'id': 'six', 'label': '6', 'action': {'type': 'input', 'value': '6'}, 'gridPosition': {'row': 3, 'column': 2}, 'type': 'primary'},
      {'id': 'subtract', 'label': '−', 'action': {'type': 'operator', 'value': '-'}, 'gridPosition': {'row': 3, 'column': 3}, 'type': 'operator'},
      {'id': 'one', 'label': '1', 'action': {'type': 'input', 'value': '1'}, 'gridPosition': {'row': 4, 'column': 0}, 'type': 'primary'},
      {'id': 'two', 'label': '2', 'action': {'type': 'input', 'value': '2'}, 'gridPosition': {'row': 4, 'column': 1}, 'type': 'primary'},
      {'id': 'three', 'label': '3', 'action': {'type': 'input', 'value': '3'}, 'gridPosition': {'row': 4, 'column': 2}, 'type': 'primary'},
      {'id': 'add', 'label': '+', 'action': {'type': 'operator', 'value': '+'}, 'gridPosition': {'row': 4, 'column': 3}, 'type': 'operator'},
      {'id': 'zero', 'label': '0', 'action': {'type': 'input', 'value': '0'}, 'gridPosition': {'row': 5, 'column': 0, 'columnSpan': 2}, 'type': 'primary', 'isWide': true},
      {'id': 'hex_f', 'label': 'F', 'action': {'type': 'input', 'value': 'F'}, 'gridPosition': {'row': 5, 'column': 2}, 'type': 'special'},
      {'id': 'equals', 'label': '=', 'action': {'type': 'equals'}, 'gridPosition': {'row': 5, 'column': 3}, 'type': 'operator'},
    ];
  }
} 