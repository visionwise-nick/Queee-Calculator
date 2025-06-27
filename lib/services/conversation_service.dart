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
} 