import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';
import 'conversation_service.dart';
import 'dart:async';

class AIService {
  // Cloud Run 服务的 URL
  static const String _baseUrl = 'https://queee-calculator-ai-backend-685339952769.us-central1.run.app';

  /// 根据用户描述生成计算器配置
  static Future<CalculatorConfig?> generateCalculatorFromPrompt(
    String userPrompt, {
    CalculatorConfig? currentConfig,
    bool skipUserMessage = false,
  }) async {
    try {
      // 如果不跳过，则记录用户消息
      if (!skipUserMessage) {
        await _recordUserMessage(userPrompt);
      }

      // 获取对话历史作为上下文
      final conversationHistory = await _getConversationHistory();

      // 构建请求
      final url = Uri.parse('$_baseUrl/customize');
      final headers = {
        'Content-Type': 'application/json',
      };
      
      final requestBody = {
        'user_input': userPrompt,
        'conversation_history': conversationHistory,
      };
      
      // 如果有当前配置，添加到请求中
      if (currentConfig != null) {
        requestBody['current_config'] = currentConfig.toJson();
      }
      
      final body = json.encode(requestBody);

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
        
        // 使用AI生成的智能回复消息
        String responseMsg = '✅ 配置已生成完成'; // 默认消息
        
        // 优先使用AI返回的自定义回复
        final configJson = config.toJson();
        if (configJson['aiResponse'] != null && configJson['aiResponse'].toString().isNotEmpty) {
          responseMsg = configJson['aiResponse'].toString();
        } else {
          // 备用方案：根据上下文生成回复
          if (currentConfig != null) {
            responseMsg = '✅ 已按您的要求完成调整！';
          } else {
            responseMsg = '🎉 "${config.name}" 已准备就绪！\n\n💡 提示：您可以随时说出想要的调整，我会在保持现有设计基础上进行精确修改';
          }
        }
        await _recordAssistantMessage(responseMsg);
        
        return config;
      } else {
        print('❌ AI 服务响应错误: ${response.statusCode}');
        print('错误详情: ${response.body}');
        
        // 记录错误
        await _recordAssistantMessage('生成失败: HTTP ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      print('❌ AI 服务调用超时');
      await _recordAssistantMessage('生成失败: 服务超时');
      throw Exception('AI 服务调用超时，请稍后重试');
    } catch (e) {
      print('❌ AI 服务调用失败: $e');
      await _recordAssistantMessage('生成失败: $e');
      throw Exception('调用 AI 服务失败: $e');
    }
  }

  /// 记录用户消息
  static Future<void> _recordUserMessage(String content) async {
    try {
      // 确保有当前会话
      var currentSession = await ConversationService.getCurrentSession();
      if (currentSession == null) {
        await ConversationService.createNewSession('计算器定制会话');
      }

      final message = ConversationMessage(
        id: ConversationService.generateMessageId(),
        type: MessageType.user,
        content: content,
        timestamp: DateTime.now(),
      );

      await ConversationService.addMessage(message);
    } catch (e) {
      print('记录用户消息失败: $e');
    }
  }

  /// 记录AI响应消息
  static Future<void> _recordAssistantMessage(String content) async {
    try {
      final message = ConversationMessage(
        id: ConversationService.generateMessageId(),
        type: MessageType.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

      await ConversationService.addMessage(message);
    } catch (e) {
      print('记录AI消息失败: $e');
    }
  }

  /// 获取对话历史
  static Future<List<Map<String, String>>> _getConversationHistory() async {
    try {
      final session = await ConversationService.getCurrentSession();
      if (session == null) return [];

      // 只取最近的10条消息，避免上下文过长
      final recentMessages = session.messages.length > 10 
          ? session.messages.sublist(session.messages.length - 10)
          : session.messages;

      return recentMessages.map((msg) => {
        'role': msg.type == MessageType.user ? 'user' : 'assistant',
        'content': msg.content,
      }).toList();
    } catch (e) {
      print('获取对话历史失败: $e');
      return [];
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
      '我想要一个有平方功能的科学计算器，深蓝色主题',
      '创建一个小费计算器，有15%和20%快捷键',
      '我需要一个游戏风格的霓虹绿计算器',
      '设计一个极简风格的白色计算器',
      '创建一个工程师专用的计算器，有开根号和立方功能',
      '我想要一个有翻倍和减半按钮的烘焙计算器',
      '给我一个温暖的橙色主题计算器',
      '我需要一个适合夜晚使用的暗色计算器',
    ];
  }
} 