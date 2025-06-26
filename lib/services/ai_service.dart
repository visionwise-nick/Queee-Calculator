import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';
import 'dart:async';

class AIService {
  // Cloud Run 服务的 URL
  static const String _baseUrl = 'https://queee-calculator-ai-backend-685339952769.us-central1.run.app';

  /// 根据用户描述生成计算器配置
  static Future<CalculatorConfig?> generateCalculatorFromPrompt(String userPrompt) async {
    try {
      // 构建请求
      final url = Uri.parse('$_baseUrl/generate-config');
      final headers = {
        'Content-Type': 'application/json',
      };
      final body = json.encode({
        'prompt': userPrompt,
      });

      print('🚀 正在调用 AI 服务...');
      print('URL: $url');
      print('请求内容: $userPrompt');

      // 发送请求到 Cloud Run 服务
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 120)); // 增加超时到120秒

      print('📡 收到响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // 解析响应
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        // 使用我们的 DSL 模型解析 AI 返回的配置
        final config = CalculatorConfig.fromJson(responseData);
        
        print('✅ AI 配置生成成功: ${config.name}');
        return config;
      } else {
        print('❌ AI 服务响应错误: ${response.statusCode}');
        print('错误详情: ${response.body}');
        return null;
      }
    } on TimeoutException {
      print('❌ AI 服务调用超时');
      throw Exception('AI 服务调用超时，请稍后重试');
    } catch (e) {
      print('❌ AI 服务调用失败: $e');
      throw Exception('调用 AI 服务失败: $e');
    }
  }

  /// 测试 AI 服务连接
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('✅ AI 服务连接正常');
        return true;
      } else {
        print('❌ AI 服务连接失败: ${response.statusCode}');
        return false;
  }
    } catch (e) {
      print('❌ AI 服务连接测试失败: $e');
      return false;
    }
  }

  /// 获取一些预设的示例提示
  static List<String> getSamplePrompts() {
    return [
      '我想要一个赛博朋克风格的计算器，黑底配霓虹蓝的按键',
      '给我一个温暖的橙色主题计算器',
      '我需要一个简洁的白色极简风格计算器',
      '创建一个绿色护眼主题的计算器',
      '我想要一个深色模式的专业计算器',
      '给我一个彩虹渐变色的有趣计算器',
      '我需要一个适合夜晚使用的暗色计算器',
      '创建一个红色和金色的豪华主题计算器',
    ];
  }
} 