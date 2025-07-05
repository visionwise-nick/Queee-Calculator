import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 对话消息类型
enum MessageType { user, assistant, system }

/// 对话消息
class ConversationMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ConversationMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  /// 检查是否包含计算器配置
  bool get hasCalculatorConfig => metadata?['hasConfig'] == true;
  
  /// 获取配置名称
  String? get configName => metadata?['configName'];
  
  /// 获取用户输入的Prompt
  String? get userPrompt => metadata?['userPrompt'];
  
  /// 检查是否可以回滚到此设计
  bool get canRollback => hasCalculatorConfig && type == MessageType.assistant;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
    id: json['id'],
    type: MessageType.values.firstWhere((e) => e.name == json['type']),
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'],
  );
}

/// 对话会话
class ConversationSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;

  const ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ConversationSession.fromJson(Map<String, dynamic> json) => ConversationSession(
    id: json['id'],
    title: json['title'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    messages: (json['messages'] as List).map((m) => ConversationMessage.fromJson(m)).toList(),
  );

  ConversationSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ConversationMessage>? messages,
  }) => ConversationSession(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
  );
}

/// 对话服务
class ConversationService {
  static const String _sessionsKey = 'conversation_sessions';
  static const String _currentSessionKey = 'current_session_id';

  /// 获取所有对话会话
  static Future<List<ConversationSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);
    
    if (sessionsJson == null) return [];
    
    try {
      final List<dynamic> sessionsList = json.decode(sessionsJson);
      return sessionsList.map((s) => ConversationSession.fromJson(s)).toList();
    } catch (e) {
      print('解析会话历史失败: $e');
      return [];
    }
  }

  /// 保存所有会话
  static Future<void> _saveSessions(List<ConversationSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = json.encode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, sessionsJson);
  }

  /// 获取当前会话ID
  static Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSessionKey);
  }

  /// 设置当前会话ID
  static Future<void> setCurrentSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionKey, sessionId);
  }

  /// 创建新会话
  static Future<ConversationSession> createNewSession(String title) async {
    final now = DateTime.now();
    final session = ConversationSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      title: title,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );

    final sessions = await getAllSessions();
    sessions.insert(0, session); // 新会话放在最前面
    await _saveSessions(sessions);
    await setCurrentSessionId(session.id);
    
    return session;
  }

  /// 添加消息到当前会话
  static Future<ConversationSession?> addMessage(ConversationMessage message) async {
    final currentSessionId = await getCurrentSessionId();
    if (currentSessionId == null) return null;

    final sessions = await getAllSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == currentSessionId);
    
    if (sessionIndex == -1) return null;

    final updatedSession = sessions[sessionIndex].copyWith(
      updatedAt: DateTime.now(),
      messages: [...sessions[sessionIndex].messages, message],
    );

    sessions[sessionIndex] = updatedSession;
    await _saveSessions(sessions);
    
    return updatedSession;
  }

  /// 获取当前会话
  static Future<ConversationSession?> getCurrentSession() async {
    final currentSessionId = await getCurrentSessionId();
    if (currentSessionId == null) return null;

    final sessions = await getAllSessions();
    return sessions.firstWhere(
      (s) => s.id == currentSessionId,
      orElse: () => sessions.isNotEmpty ? sessions.first : throw StateError('No session found'),
    );
  }

  /// 删除会话
  static Future<void> deleteSession(String sessionId) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions(sessions);

    // 如果删除的是当前会话，清除当前会话ID
    final currentSessionId = await getCurrentSessionId();
    if (currentSessionId == sessionId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentSessionKey);
    }
  }

  /// 清除所有会话
  static Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_currentSessionKey);
  }

  /// 更新消息
  static Future<ConversationSession?> updateMessage(ConversationMessage updatedMessage) async {
    final currentSessionId = await getCurrentSessionId();
    if (currentSessionId == null) return null;

    final sessions = await getAllSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == currentSessionId);
    
    if (sessionIndex == -1) return null;

    final currentSession = sessions[sessionIndex];
    final messageIndex = currentSession.messages.indexWhere((m) => m.id == updatedMessage.id);
    
    if (messageIndex == -1) return null;

    final updatedMessages = [...currentSession.messages];
    updatedMessages[messageIndex] = updatedMessage;

    final updatedSession = currentSession.copyWith(
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    sessions[sessionIndex] = updatedSession;
    await _saveSessions(sessions);
    
    return updatedSession;
  }

  /// 删除消息
  static Future<ConversationSession?> deleteMessage(String messageId) async {
    final currentSessionId = await getCurrentSessionId();
    if (currentSessionId == null) return null;

    final sessions = await getAllSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == currentSessionId);
    
    if (sessionIndex == -1) return null;

    final currentSession = sessions[sessionIndex];
    final updatedMessages = currentSession.messages.where((m) => m.id != messageId).toList();

    final updatedSession = currentSession.copyWith(
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    sessions[sessionIndex] = updatedSession;
    await _saveSessions(sessions);
    
    return updatedSession;
  }

  /// 生成消息ID
  static String generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 获取当前会话的设计历史记录
  static Future<List<ConversationMessage>> getDesignHistory() async {
    final session = await getCurrentSession();
    if (session == null) return [];
    
    // 返回所有包含计算器配置的助手消息，按时间倒序
    return session.messages
        .where((msg) => msg.canRollback)
        .toList()
        .reversed
        .toList();
  }

  /// 获取设计历史记录的简要信息
  static Future<List<Map<String, dynamic>>> getDesignHistorySummary() async {
    final designHistory = await getDesignHistory();
    
    return designHistory.map((msg) {
      // 从消息内容中提取简要描述
      String summary = msg.content;
      if (summary.length > 50) {
        summary = summary.substring(0, 50) + '...';
      }
      
      return {
        'id': msg.id,
        'configName': msg.configName ?? '未命名设计',
        'summary': summary,
        'timestamp': msg.timestamp,
        'userPrompt': msg.userPrompt,
      };
    }).toList();
  }

  /// 清理旧的设计历史记录，保留最近的指定数量
  static Future<void> cleanupDesignHistory({int keepCount = 20}) async {
    try {
      final session = await getCurrentSession();
      if (session == null) return;
      
      final designMessages = session.messages
          .where((msg) => msg.canRollback)
          .toList();
      
      if (designMessages.length <= keepCount) return;
      
      // 按时间排序，保留最新的keepCount条记录
      designMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final toRemove = designMessages.sublist(keepCount);
      
      // 删除旧记录
      var updatedMessages = session.messages.toList();
      for (final msg in toRemove) {
        updatedMessages.removeWhere((m) => m.id == msg.id);
      }
      
      // 更新会话
      final sessions = await getAllSessions();
      final sessionIndex = sessions.indexWhere((s) => s.id == session.id);
      if (sessionIndex != -1) {
        sessions[sessionIndex] = session.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        await _saveSessions(sessions);
      }
      
      print('🧹 已清理 ${toRemove.length} 条旧的设计历史记录');
    } catch (e) {
      print('清理设计历史失败: $e');
    }
  }

  /// 获取设计历史记录的统计信息
  static Future<Map<String, int>> getDesignHistoryStats() async {
    try {
      final session = await getCurrentSession();
      if (session == null) return {'total': 0, 'designs': 0};
      
      final designMessages = session.messages
          .where((msg) => msg.canRollback)
          .toList();
      
      return {
        'total': session.messages.length,
        'designs': designMessages.length,
      };
    } catch (e) {
      print('获取设计历史统计失败: $e');
      return {'total': 0, 'designs': 0};
    }
  }
} 