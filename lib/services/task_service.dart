import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/calculator_dsl.dart';

/// 任务状态枚举
enum TaskStatus {
  pending,    // 等待处理
  running,    // 正在处理
  completed,  // 已完成
  failed,     // 失败
  cancelled   // 已取消
}

/// 任务类型枚举
enum TaskType {
  aiDesigner,       // AI设计师
  appBackground,    // APP背景图生成
  buttonPattern,    // 按键背景图生成
}

/// 生成任务模型
class GenerationTask {
  final String id;
  final TaskType type;
  final TaskStatus status;
  final String? prompt;
  final Map<String, dynamic>? parameters;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? result;
  final String? error;
  final double progress;

  const GenerationTask({
    required this.id,
    required this.type,
    required this.status,
    this.prompt,
    this.parameters,
    required this.createdAt,
    this.completedAt,
    this.result,
    this.error,
    this.progress = 0.0,
  });

  factory GenerationTask.fromJson(Map<String, dynamic> json) {
    return GenerationTask(
      id: json['id'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.aiDesigner,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      prompt: json['prompt'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      result: json['result'] as String?,
      error: json['error'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'prompt': prompt,
      'parameters': parameters,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'result': result,
      'error': error,
      'progress': progress,
    };
  }

  GenerationTask copyWith({
    String? id,
    TaskType? type,
    TaskStatus? status,
    String? prompt,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? completedAt,
    String? result,
    String? error,
    double? progress,
  }) {
    return GenerationTask(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}

/// 任务管理服务
class TaskService {
  static const String _baseUrl = 'https://queee-calculator-ai-backend-adecumh2za-uc.a.run.app';
  
  // 活跃任务缓存
  static final Map<String, GenerationTask> _activeTasks = {};
  
  // 任务状态变化回调
  static final Map<String, List<Function(GenerationTask)>> _taskCallbacks = {};
  
  // 轮询定时器
  static Timer? _pollingTimer;
  
  /// 提交AI设计师任务
  static Future<String> submitAiDesignerTask({
    required String userInput,
    List<Map<String, String>>? conversationHistory,
    CalculatorConfig? currentConfig,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/submit-async-task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'task_type': 'ai_designer',
          'parameters': {
            'user_input': userInput,
            'conversation_history': conversationHistory ?? [],
            'current_config': currentConfig?.toJson(),
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final taskId = data['task_id'] as String;
        
        // 创建本地任务记录
        final task = GenerationTask(
          id: taskId,
          type: TaskType.aiDesigner,
          status: TaskStatus.pending,
          prompt: userInput,
          parameters: {
            'conversation_history': conversationHistory,
            'current_config': currentConfig?.toJson(),
          },
          createdAt: DateTime.now(),
        );
        
        _activeTasks[taskId] = task;
        _startPolling();
        
        print('✅ AI设计师任务已提交: $taskId');
        return taskId;
      } else {
        throw Exception('提交任务失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 提交APP背景图生成任务
  static Future<String> submitAppBackgroundTask({
    required String prompt,
    String style = 'modern',
    String size = '1080x1920',
    String quality = 'high',
    String theme = 'calculator',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/submit-async-task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'task_type': 'app_background',
          'parameters': {
            'prompt': prompt,
            'style': style,
            'size': size,
            'quality': quality,
            'theme': theme,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final taskId = data['task_id'] as String;
        
        // 创建本地任务记录
        final task = GenerationTask(
          id: taskId,
          type: TaskType.appBackground,
          status: TaskStatus.pending,
          prompt: prompt,
          parameters: {
            'style': style,
            'size': size,
            'quality': quality,
            'theme': theme,
          },
          createdAt: DateTime.now(),
        );
        
        _activeTasks[taskId] = task;
        _startPolling();
        
        print('✅ APP背景图任务已提交: $taskId');
        return taskId;
      } else {
        throw Exception('提交任务失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 提交按键背景图案生成任务
  static Future<String> submitButtonPatternTask({
    required String prompt,
    String style = 'minimal',
    String size = '48x48',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/submit-async-task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'task_type': 'button_pattern',
          'parameters': {
            'prompt': prompt,
            'style': style,
            'size': size,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final taskId = data['task_id'] as String;
        
        // 创建本地任务记录
        final task = GenerationTask(
          id: taskId,
          type: TaskType.buttonPattern,
          status: TaskStatus.pending,
          prompt: prompt,
          parameters: {
            'style': style,
            'size': size,
          },
          createdAt: DateTime.now(),
        );
        
        _activeTasks[taskId] = task;
        _startPolling();
        
        print('✅ 按键背景图案任务已提交: $taskId');
        return taskId;
      } else {
        throw Exception('提交任务失败: ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 查询任务状态
  static Future<GenerationTask?> getTaskStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/task-status/$taskId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final task = GenerationTask.fromJson(data);
        
        // 更新本地缓存
        _activeTasks[taskId] = task;
        
        // 触发回调
        _notifyTaskCallbacks(task);
        
        return task;
      } else if (response.statusCode == 404) {
        // 任务不存在
        _activeTasks.remove(taskId);
        return null;
      } else {
        throw Exception('查询任务状态失败: ${response.body}');
      }
    } catch (e) {
      print('查询任务状态失败: $e');
      return null;
    }
  }

  /// 取消任务
  static Future<bool> cancelTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/task/$taskId'),
      );

      if (response.statusCode == 200) {
        _activeTasks.remove(taskId);
        print('✅ 任务已取消: $taskId');
        return true;
      } else {
        throw Exception('取消任务失败: ${response.body}');
      }
    } catch (e) {
      print('取消任务失败: $e');
      return false;
    }
  }

  /// 注册任务状态变化回调
  static void registerTaskCallback(String taskId, Function(GenerationTask) callback) {
    if (!_taskCallbacks.containsKey(taskId)) {
      _taskCallbacks[taskId] = [];
    }
    _taskCallbacks[taskId]!.add(callback);
  }

  /// 移除任务回调
  static void removeTaskCallback(String taskId, Function(GenerationTask) callback) {
    _taskCallbacks[taskId]?.remove(callback);
    if (_taskCallbacks[taskId]?.isEmpty == true) {
      _taskCallbacks.remove(taskId);
    }
  }

  /// 触发任务回调
  static void _notifyTaskCallbacks(GenerationTask task) {
    final callbacks = _taskCallbacks[task.id];
    if (callbacks != null) {
      for (final callback in callbacks) {
        try {
          callback(task);
        } catch (e) {
          print('任务回调执行失败: $e');
        }
      }
    }
  }

  /// 开始轮询
  static void _startPolling() {
    if (_pollingTimer?.isActive == true) {
      return; // 已经在轮询中
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_activeTasks.isEmpty) {
        timer.cancel();
        return;
      }

      // 轮询所有活跃任务
      final taskIds = _activeTasks.keys.toList();
      for (final taskId in taskIds) {
        final currentTask = _activeTasks[taskId];
        if (currentTask?.status == TaskStatus.completed || 
            currentTask?.status == TaskStatus.failed ||
            currentTask?.status == TaskStatus.cancelled) {
          continue; // 跳过已完成的任务
        }

        await getTaskStatus(taskId);
      }

      // 清理已完成的任务（延迟5分钟后清理）
      final now = DateTime.now();
      final completedTasks = _activeTasks.entries
          .where((entry) => 
              (entry.value.status == TaskStatus.completed || 
               entry.value.status == TaskStatus.failed ||
               entry.value.status == TaskStatus.cancelled) &&
              entry.value.completedAt != null &&
              now.difference(entry.value.completedAt!).inMinutes > 5)
          .map((entry) => entry.key)
          .toList();

      for (final taskId in completedTasks) {
        _activeTasks.remove(taskId);
        _taskCallbacks.remove(taskId);
      }
    });
  }

  /// 停止轮询
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 获取所有活跃任务
  static List<GenerationTask> getActiveTasks() {
    return _activeTasks.values.toList();
  }

  /// 获取特定类型的活跃任务
  static List<GenerationTask> getActiveTasksByType(TaskType type) {
    return _activeTasks.values
        .where((task) => task.type == type)
        .toList();
  }

  /// 清理所有任务
  static void clearAllTasks() {
    _activeTasks.clear();
    _taskCallbacks.clear();
    stopPolling();
  }
} 