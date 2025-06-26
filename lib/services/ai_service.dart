import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';

class AIService {
  static const String _baseUrl = 'https://queee-calculator-backend-v2-685339952769.us-central1.run.app';

  /// 调用后端 AI 服务生成计算器配置
  /// 
  /// [prompt] 是用户输入的自然语言描述
  /// 返回一个 [CalculatorConfig] 对象，如果失败则返回 null
  Future<CalculatorConfig?> generateConfig(String prompt) async {
    final url = Uri.parse('$_baseUrl/generate-calculator');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'description': prompt}),
      );

      if (response.statusCode == 200) {
        // 使用 UTF-8 解码响应体以正确处理中文字符
        final responseBody = utf8.decode(response.bodyBytes);
        
        // 调试：打印从服务器收到的原始JSON
        print('--- AI Response JSON ---');
        print(responseBody);
        print('------------------------');

        final configMap = json.decode(responseBody) as Map<String, dynamic>;
        
        // 自我修复和验证
        return CalculatorConfig.fromJson(configMap);
      } else {
        print('AI Service Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Failed to connect to AI service: $e');
      return null;
    }
  }
} 