import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';
import 'conversation_service.dart';
import 'dart:async';

/// 🔧 新增：异步任务状态枚举
enum AITaskStatus { pending, processing, completed, failed }

/// 🔧 新增：任务结果类
class TaskResult {
  final String taskId;
  final AITaskStatus status;
  final dynamic result;
  final String? error;
  final double? progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskResult({
    required this.taskId,
    required this.status,
    this.result,
    this.error,
    this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskResult.fromJson(Map<String, dynamic> json) {
    return TaskResult(
      taskId: json['task_id'],
      status: AITaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AITaskStatus.pending,
      ),
      result: json['result'],
      error: json['error'],
      progress: json['progress']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AIService {
  // Cloud Run 服务的 URL - 更新为新部署的服务
  static const String _baseUrl = 'https://queee-calculator-ai-backend-adecumh2za-uc.a.run.app';

  /// 🔧 新增：异步生成计算器配置
  static Future<CalculatorConfig?> generateCalculatorFromPrompt(
    String userPrompt, {
    CalculatorConfig? currentConfig,
    bool skipUserMessage = false,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      // 如果不跳过，则记录用户消息
      if (!skipUserMessage) {
        await _recordUserMessage(userPrompt);
      }

      onStatusUpdate?.call('正在提交任务...');
      onProgress?.call(0.1);

      // 🔧 优化：减少对话历史数量，避免请求过大
      final conversationHistory = await _getConversationHistory(maxMessages: 5);

      // 构建请求
      final url = Uri.parse('$_baseUrl/tasks/submit/customize');
      final headers = {
        'Content-Type': 'application/json',
      };
      
      final requestBody = {
        'user_input': userPrompt,
        'conversation_history': conversationHistory,
      };
      
      // 🔧 优化：简化当前配置，只传递必要信息
      if (currentConfig != null) {
        final simplifiedConfig = _simplifyCurrentConfig(currentConfig);
        requestBody['current_config'] = simplifiedConfig;
        
        // 🛡️ 简化保护机制：只保护背景图URL，因为背景图只在本地保存
        requestBody['preserve_background_images'] = true;
        
        print('🛡️ 启用背景图保护机制');
      }
      
      final body = json.encode(requestBody);
      print('🚀 正在提交异步任务...');
      print('URL: $url');
      print('请求内容: $userPrompt');
      print('📦 请求体大小: ${body.length} 字节');

      // 🔧 优化：增加提交超时到60秒
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 60));

      print('📡 收到任务提交响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final taskId = responseData['task_id'] as String;
        
        onStatusUpdate?.call('任务已提交，正在后台处理...');
        onProgress?.call(0.2);
        
        print('✅ 任务已提交，任务ID: $taskId');
        
        // 轮询任务状态
        final result = await _pollTaskStatus(
          taskId,
          onProgress: onProgress,
          onStatusUpdate: onStatusUpdate,
        );
        
                 if (result.status == AITaskStatus.completed && result.result != null) {
           final configData = result.result['config'] as Map<String, dynamic>;
           final config = CalculatorConfig.fromJson(configData);
           
           print('✅ AI 配置生成成功: ${config.name}');
           
           // 记录成功消息
           String responseMsg = '✅ 配置已生成完成';
        
        // 优先使用AI返回的自定义回复
           if (configData['aiResponse'] != null && configData['aiResponse'].toString().isNotEmpty) {
             responseMsg = configData['aiResponse'].toString();
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
         } else if (result.status == AITaskStatus.failed) {
           throw Exception(result.error ?? '任务执行失败');
         }
      } else {
        print('❌ 任务提交失败: ${response.statusCode}');
        print('错误详情: ${response.body}');
        
        await _recordAssistantMessage('生成失败: HTTP ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      print('❌ 任务提交超时');
      await _recordAssistantMessage('生成失败: 服务超时');
      throw Exception('任务提交超时，请稍后重试');
    } catch (e) {
      print('❌ 任务提交失败: $e');
      await _recordAssistantMessage('生成失败: $e');
      throw Exception('任务提交失败: $e');
    }
    
    return null;
  }

  /// 🔧 新增：轮询任务状态
  static Future<TaskResult> _pollTaskStatus(
    String taskId, {
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
    Duration pollInterval = const Duration(seconds: 2),
    Duration maxWaitTime = const Duration(minutes: 10),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxWaitTime) {
      try {
        final url = Uri.parse('$_baseUrl/tasks/$taskId/status');
        final response = await http.get(url).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final taskResult = TaskResult.fromJson(json.decode(response.body));
          
          // 更新进度
          if (taskResult.progress != null) {
            onProgress?.call(taskResult.progress!);
          }
          
                     // 更新状态消息
           switch (taskResult.status) {
             case AITaskStatus.pending:
               onStatusUpdate?.call('任务等待中...');
               break;
             case AITaskStatus.processing:
               onStatusUpdate?.call('AI正在处理中...');
               break;
             case AITaskStatus.completed:
               onStatusUpdate?.call('任务完成！');
               return taskResult;
             case AITaskStatus.failed:
               onStatusUpdate?.call('任务失败');
               return taskResult;
           }
          
          print('📊 任务状态: ${taskResult.status}, 进度: ${taskResult.progress}');
        } else {
          print('❌ 获取任务状态失败: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ 轮询任务状态失败: $e');
      }
      
      // 等待下次轮询
      await Future.delayed(pollInterval);
    }
    
    throw Exception('任务超时，请稍后查看结果');
  }

  /// 🔧 新增：异步生成图像
  static Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String style = 'realistic',
    String size = '1024x1024',
    String quality = 'standard',
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    return await _submitImageTask(
      endpoint: 'generate-image',
      params: {
        'prompt': prompt,
        'style': style,
        'size': size,
        'quality': quality,
      },
      taskName: '图像生成',
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// 🔧 新增：异步生成按键背景图案
  static Future<Map<String, dynamic>> generatePattern({
    required String prompt,
    String style = 'minimal',
    String size = '256x256',
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    return await _submitImageTask(
      endpoint: 'generate-pattern',
      params: {
        'prompt': prompt,
        'style': style,
        'size': size,
      },
      taskName: '按键背景图生成',
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// 🔧 新增：异步生成APP背景图
  static Future<Map<String, dynamic>> generateAppBackground({
    required String prompt,
    String style = 'modern',
    String size = '1080x1920',
    String quality = 'high',
    String theme = 'calculator',
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    return await _submitImageTask(
      endpoint: 'generate-app-background',
      params: {
        'prompt': prompt,
        'style': style,
        'size': size,
        'quality': quality,
        'theme': theme,
      },
      taskName: 'APP背景图生成',
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// 🔧 新增：异步生成显示区背景图
  static Future<Map<String, dynamic>> generateDisplayBackground({
    required String prompt,
    String style = 'clean',
    String size = '800x400',
    String quality = 'high',
    String theme = 'display',
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    return await _submitImageTask(
      endpoint: 'generate-display-background',
      params: {
        'prompt': prompt,
        'style': style,
        'size': size,
        'quality': quality,
        'theme': theme,
      },
      taskName: '显示区背景图生成',
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// 🔧 新增：异步生成光影文字图片
  static Future<Map<String, dynamic>> generateTextImage({
    required String prompt,
    required String text,
    String style = 'modern',
    String size = '512x512',
    String background = 'transparent',
    List<String> effects = const [],
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    return await _submitImageTask(
      endpoint: 'generate-text-image',
      params: {
        'prompt': prompt,
        'text': text,
        'style': style,
        'size': size,
        'background': background,
        'effects': effects,
      },
      taskName: '光影文字图片生成',
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// 🔧 新增：通用异步图像任务提交
  static Future<Map<String, dynamic>> _submitImageTask({
    required String endpoint,
    required Map<String, dynamic> params,
    required String taskName,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('正在提交$taskName任务...');
      onProgress?.call(0.1);

      final url = Uri.parse('$_baseUrl/tasks/submit/$endpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(params),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final taskId = responseData['task_id'] as String;
        
        onStatusUpdate?.call('$taskName任务已提交，正在后台处理...');
        onProgress?.call(0.2);
        
        print('✅ $taskName任务已提交，任务ID: $taskId');
        
        // 轮询任务状态
        final result = await _pollTaskStatus(
          taskId,
          onProgress: onProgress,
          onStatusUpdate: onStatusUpdate,
        );
        
        if (result.status == AITaskStatus.completed && result.result != null) {
          print('✅ $taskName成功');
          return result.result;
        } else if (result.status == AITaskStatus.failed) {
          throw Exception(result.error ?? '$taskName失败');
        }
      } else {
        throw Exception('$taskName任务提交失败: ${response.body}');
      }
    } catch (e) {
      print('❌ $taskName失败: $e');
      throw Exception('$taskName失败: $e');
    }
    
    throw Exception('$taskName任务异常结束');
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
  static Future<List<Map<String, String>>> _getConversationHistory({int maxMessages = 10}) async {
    try {
      final session = await ConversationService.getCurrentSession();
      if (session == null) return [];

      // 🔧 优化：使用参数控制消息数量，避免上下文过长
      final recentMessages = session.messages.length > maxMessages 
          ? session.messages.sublist(session.messages.length - maxMessages)
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

  /// 🔧 新增：简化当前配置，只保留必要字段
  static Map<String, dynamic> _simplifyCurrentConfig(CalculatorConfig config) {
    try {
      // 只保留AI需要的关键信息，大幅减少数据量
      final simplified = {
        'id': config.id,
        'name': config.name,
        'description': config.description,
        'layout': {
          'rows': config.layout.rows,
          'columns': config.layout.columns,
          'buttons': config.layout.buttons.map((button) => {
            'id': button.id,
            'label': button.label,
            'type': button.type,
            'action': button.action.toJson(),
            'gridPosition': button.gridPosition.toJson(),
            // 🔧 保留按键背景图信息
            if (button.backgroundImage != null) 'backgroundImage': button.backgroundImage,
          }).toList(),
        },
        // 🔧 保留主题关键信息但简化
        'theme': {
          'name': config.theme.name,
          // 🔧 保留主题背景图
          if (config.theme.backgroundImage != null) 'backgroundImage': config.theme.backgroundImage,
        },
      };

      // 🔧 完整保留APP背景图信息
      if (config.appBackground != null) {
        simplified['appBackground'] = {
          'backgroundType': config.appBackground!.backgroundType,
          'backgroundImageUrl': config.appBackground!.backgroundImageUrl,
          'backgroundColor': config.appBackground!.backgroundColor,
          'backgroundGradient': config.appBackground!.backgroundGradient,
          'backgroundOpacity': config.appBackground!.backgroundOpacity,
          'buttonOpacity': config.appBackground!.buttonOpacity,
          'displayOpacity': config.appBackground!.displayOpacity,
        };
      }

      print('🔧 配置简化完成：原始 ${json.encode(config.toJson()).length} 字节 → 简化 ${json.encode(simplified).length} 字节');
      return simplified;
    } catch (e) {
      print('❌ 简化配置失败，使用完整配置: $e');
      return config.toJson();
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


} 