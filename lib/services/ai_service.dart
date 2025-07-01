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
        
        // 🛡️ 检测并添加图像生成工坊保护参数
        final (hasWorkshopContent, protectedFields) = _detectWorkshopContent(currentConfig);
        requestBody['has_image_workshop_content'] = hasWorkshopContent;
        requestBody['workshop_protected_fields'] = protectedFields;
        
        if (hasWorkshopContent) {
          print('🛡️ 检测到图像生成工坊内容，启用保护机制');
          print('🛡️ 保护字段: $protectedFields');
        }
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
      ).timeout(const Duration(seconds: 300)); // 增加超时到300秒

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
      print('🔍 正在测试AI服务连接...');
      final url = Uri.parse('$_baseUrl/health');
      print('🌐 测试URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      print('📡 收到响应: ${response.statusCode}');
      print('📝 响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ AI 服务连接正常');
        return true;
      } else {
        print('❌ AI 服务连接失败: ${response.statusCode}');
        print('❌ 错误详情: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ AI 服务连接测试失败: $e');
      print('❌ 错误类型: ${e.runtimeType}');
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

  /// 生成自定义计算器配置
  static Future<CalculatorConfig> generateCalculator({
    required String userInput,
    List<Map<String, String>>? conversationHistory,
    CalculatorConfig? currentConfig,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_input': userInput,
          'conversation_history': conversationHistory ?? [],
          'current_config': currentConfig?.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CalculatorConfig.fromJson(data);
      } else {
        throw Exception('生成失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取可用的AI模型列表
  static Future<Map<String, dynamic>> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('获取模型列表失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 切换AI模型
  static Future<Map<String, dynamic>> switchModel(String modelKey) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/switch-model/$modelKey'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('切换模型失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// AI生成图像
  static Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String style = 'realistic',
    String size = '1024x1024',
    String quality = 'standard',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'style': style,
          'size': size,
          'quality': quality,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('图像生成失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// AI生成按钮背景图案
  static Future<Map<String, dynamic>> generatePattern({
    required String prompt,
    String style = 'minimal',
    String size = '256x256',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-pattern'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'style': style,
          'size': size,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('图案生成失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// AI生成光影文字图片 - 用于按键文字
  static Future<Map<String, dynamic>> generateTextImage({
    required String prompt,
    required String text,
    String style = 'modern',
    String size = '512x512',
    String background = 'transparent',
    List<String> effects = const [],
  }) async {
    try {
      print('🎨 正在生成光影文字图片...');
      print('文字内容: $text');
      print('提示词: $prompt');
      print('风格: $style');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-text-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'text': text,
          'style': style,
          'size': size,
          'background': background,
          'effects': effects,
        }),
      ).timeout(const Duration(seconds: 60));

      print('📡 收到响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          print('✅ 光影文字图片生成成功: $text');
          return result;
        } else {
          throw Exception(result['message'] ?? '生成失败');
        }
      } else {
        print('❌ 光影文字图片生成失败: ${response.statusCode}');
        print('错误详情: ${response.body}');
        throw Exception('光影文字图片生成失败: ${response.body}');
      }
    } catch (e) {
      print('❌ 光影文字图片生成请求失败: $e');
      throw Exception('网络请求失败: $e');
    }
  }

  /// AI生成按键文字内容（保留备用方法）
  static Future<Map<String, dynamic>> generateButtonText({
    required String prompt,
    required String currentLabel,
    required String buttonType,
  }) async {
    try {
      print('✨ 正在生成按键文字...');
      print('提示词: $prompt');
      print('当前文字: $currentLabel');
      print('按键类型: $buttonType');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-button-text'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'current_label': currentLabel,
          'button_type': buttonType,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📡 收到响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ 按键文字生成成功: ${result['text']}');
        return result;
      } else {
        print('❌ 按键文字生成失败: ${response.statusCode}');
        print('错误详情: ${response.body}');
        
        // 如果后端API不存在，我们可以在前端生成一些创意文字
        return _generateCreativeText(currentLabel, buttonType, prompt);
      }
    } catch (e) {
      print('❌ 按键文字生成请求失败: $e');
      // 网络错误时，使用本地生成逻辑
      return _generateCreativeText(currentLabel, buttonType, prompt);
    }
  }

  /// 本地生成创意文字（备用方案）
  static Map<String, dynamic> _generateCreativeText(String currentLabel, String buttonType, String prompt) {
    print('🔄 使用本地生成逻辑...');
    
    // 表情符号映射
    Map<String, String> emojiNumbers = {
      '0': '😐', '1': '😀', '2': '😁', '3': '😂', '4': '😃',
      '5': '😄', '6': '😅', '7': '😆', '8': '😇', '9': '😈',
    };
    
    Map<String, String> animalEmojis = {
      '0': '🐶', '1': '🐱', '2': '🐰', '3': '🦊', '4': '🐻',
      '5': '🐼', '6': '🐨', '7': '🐯', '8': '🐮', '9': '🐷',
    };
    
    Map<String, String> fruitEmojis = {
      '0': '🍎', '1': '🍊', '2': '🍌', '3': '🍇', '4': '🍓',
      '5': '🥝', '6': '🍑', '7': '🥭', '8': '🍍', '9': '🥥',
    };
    
    Map<String, String> chineseNumbers = {
      '0': '零', '1': '壹', '2': '贰', '3': '叁', '4': '肆',
      '5': '伍', '6': '陆', '7': '柒', '8': '捌', '9': '玖',
    };
    
    Map<String, String> romanNumbers = {
      '0': '⓪', '1': 'Ⅰ', '2': 'Ⅱ', '3': 'Ⅲ', '4': 'Ⅳ',
      '5': 'Ⅴ', '6': 'Ⅵ', '7': 'Ⅶ', '8': 'Ⅷ', '9': 'Ⅸ',
    };
    
    Map<String, String> specialSymbols = {
      '+': '➕', '-': '➖', '×': '✖️', '÷': '➗', '=': '🟰',
      'AC': '🔄', 'C': '🗑️', '±': '🔄', '%': '💯', '.': '🔸',
    };
    
    String newText = currentLabel;
    
    if (prompt.contains('表情符号') && emojiNumbers.containsKey(currentLabel)) {
      newText = emojiNumbers[currentLabel]!;
    } else if (prompt.contains('动物') && animalEmojis.containsKey(currentLabel)) {
      newText = animalEmojis[currentLabel]!;
    } else if (prompt.contains('水果') && fruitEmojis.containsKey(currentLabel)) {
      newText = fruitEmojis[currentLabel]!;
    } else if (prompt.contains('古典汉字') && chineseNumbers.containsKey(currentLabel)) {
      newText = chineseNumbers[currentLabel]!;
    } else if (prompt.contains('罗马数字') && romanNumbers.containsKey(currentLabel)) {
      newText = romanNumbers[currentLabel]!;
    } else if (specialSymbols.containsKey(currentLabel)) {
      newText = specialSymbols[currentLabel]!;
    }
    
    return {
      'success': true,
      'text': newText,
      'message': '本地生成成功'
    };
  }

  /// AI生成APP背景图
  static Future<Map<String, dynamic>> generateAppBackground({
    required String prompt,
    String style = 'modern',
    String size = '1080x1920',
    String quality = 'high',
    String theme = 'calculator',
  }) async {
    try {
      print('🎨 正在生成APP背景图...');
      print('提示词: $prompt');
      print('风格: $style');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-app-background'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'style': style,
          'size': size,
          'quality': quality,
          'theme': theme,
        }),
      ).timeout(const Duration(seconds: 60));

      print('📡 收到响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ APP背景图生成成功');
        return result;
      } else {
        print('❌ APP背景图生成失败: ${response.statusCode}');
        print('错误详情: ${response.body}');
        throw Exception('APP背景图生成失败: ${response.body}');
      }
    } catch (e) {
      print('❌ APP背景图生成请求失败: $e');
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取APP背景图预设风格
  static Future<Map<String, dynamic>> getBackgroundPresets() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/background-presets'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('获取背景预设失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取APP背景图生成示例提示词
  static List<String> getBackgroundSamplePrompts() {
    return [
      '优雅的现代几何背景，适合计算器应用',
      '深色科技风背景，带有微妙的数字图案',
      '温暖的渐变背景，从橙色到红色',
      '极简主义的纯色背景，带有细微纹理',
      '未来主义的霓虹背景，蓝色和紫色调',
      '专业的商务风格背景，深蓝色调',
      '自然风格的背景，绿色渐变',
      '复古风格的背景，暖色调',
      '抽象艺术背景，多彩几何图案',
      '夜空主题背景，深色带星点',
    ];
  }

  /// 🛡️ 检测图像生成工坊内容
  static (bool, List<String>) _detectWorkshopContent(CalculatorConfig config) {
    List<String> protectedFields = [];
    
    // 检查APP背景图（优先检查appBackground）
    if (config.appBackground?.backgroundImageUrl != null) {
      protectedFields.addAll([
        'appBackground.backgroundImageUrl',
        'appBackground.backgroundType',
        'appBackground.backgroundColor',
        'appBackground.backgroundGradient',
        'appBackground.backgroundOpacity'
      ]);
    }
    
    // 检查主题背景图
    if (config.theme.backgroundImage != null) {
      protectedFields.addAll([
        'theme.backgroundImage',
        'theme.backgroundColor', 
        'theme.backgroundGradient'
      ]);
    }
    
    // 检查按钮背景图和图案
    for (final button in config.layout.buttons) {
      if (button.backgroundImage != null) {
        protectedFields.add('button.${button.id}.backgroundImage');
      }
      // 检查按钮背景图案
      if (button.backgroundPattern != null) {
        protectedFields.addAll([
          'button.${button.id}.backgroundPattern',
          'button.${button.id}.patternColor',
          'button.${button.id}.patternOpacity'
        ]);
      }
    }
    
    final hasWorkshopContent = protectedFields.isNotEmpty;
    
    return (hasWorkshopContent, protectedFields);
  }
} 