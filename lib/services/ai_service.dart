import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';

class AIService {
  // 使用您部署在 Cloud Run 上的后端服务 URL
  static const String _backendUrl = 'https://queee-calculator-backend-685339952769.us-central1.run.app/generate-config';

  /// 调用后端 AI 服务生成计算器配置
  /// 
  /// [userPrompt] 是用户输入的自然语言描述
  /// 返回一个 [CalculatorConfig] 对象，如果失败则抛出异常
  Future<CalculatorConfig> generateConfig(String userPrompt) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'prompt': userPrompt}),
      );

      if (response.statusCode == 200) {
        // 使用 UTF-8 解码响应体以正确处理中文字符
        final responseBody = utf8.decode(response.bodyBytes);
        
        // 调试：打印从服务器收到的原始JSON
        print('--- AI Response JSON ---');
        print(responseBody);
        print('------------------------');

        final configMap = json.decode(responseBody) as Map<String, dynamic>;
        return CalculatorConfig.fromJson(configMap);
      } else {
        // 如果服务器返回非 200 状态码，抛出异常
        throw Exception('Failed to generate config from AI. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // 捕获并重新抛出网络或其他异常
      throw Exception('Error connecting to AI service: $e');
    }
  }
} 