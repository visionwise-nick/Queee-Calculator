import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../services/task_service.dart'; // 🔧 新增：导入任务服务
import '../models/calculator_dsl.dart';
import '../widgets/thinking_process_dialog.dart';
import '../widgets/generation_status_widget.dart'; // 🔧 新增：导入状态显示组件
import '../widgets/ai_generation_progress_dialog.dart'; // 🔧 新增：导入进度弹窗
import 'dart:convert';

class AICustomizeScreen extends StatefulWidget {
  const AICustomizeScreen({super.key});

  @override
  State<AICustomizeScreen> createState() => _AICustomizeScreenState();
}

class _AICustomizeScreenState extends State<AICustomizeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ConversationMessage> _messages = [];
  bool _isLoading = false;
  ConversationSession? _currentSession;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  // 🔧 新增：进度弹窗控制器
  final AIGenerationProgressController _progressController = AIGenerationProgressController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabAnimationController.dispose();
    _progressController.dispose(); // 🔧 新增：清理进度控制器
    super.dispose();
  }

  Future<void> _loadCurrentSession() async {
    try {
      var session = await ConversationService.getCurrentSession();
      if (session == null) {
        session = await ConversationService.createNewSession('AI定制会话');
      }
      
      setState(() {
        _currentSession = session;
        _messages = session!.messages;
      });
      
      if (_messages.isEmpty) {
        await _addWelcomeMessages();
      }
      _scrollToBottom();
    } catch (e) {
      print('加载会话失败: $e');
    }
  }

  Future<void> _addWelcomeMessages() async {
    final l10n = AppLocalizations.of(context)!;
    final welcomeMessages = [
      l10n.welcomeMessage1,
      l10n.welcomeMessage2,
      l10n.welcomeMessage3,
    ];

    for (int i = 0; i < welcomeMessages.length; i++) {
      await Future.delayed(Duration(milliseconds: 500 * i));
      await _addSystemMessage(welcomeMessages[i]);
    }
  }

  Future<void> _addSystemMessage(String content) async {
    final message = ConversationMessage(
      id: ConversationService.generateMessageId(),
      type: MessageType.system,
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    await ConversationService.addMessage(message);
    _scrollToBottom();
  }

  Future<void> _addUserMessage(String content) async {
    final message = ConversationMessage(
      id: ConversationService.generateMessageId(),
      type: MessageType.user,
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    await ConversationService.addMessage(message);
    _scrollToBottom();
  }

  Future<void> _addAssistantMessage(String content, {CalculatorConfig? config}) async {
    final metadata = <String, dynamic>{};
    if (config != null) {
      metadata['hasConfig'] = true;
      metadata['configName'] = config.name;
      if (config.thinkingProcess != null) {
        metadata['hasThinkingProcess'] = true;
        metadata['thinkingProcess'] = config.thinkingProcess;
      }
    }

    final message = ConversationMessage(
      id: ConversationService.generateMessageId(),
      type: MessageType.assistant,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata.isNotEmpty ? metadata : null,
    );

    setState(() {
      _messages.add(message);
    });

    await ConversationService.addMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userInput = text.trim();
    _textController.clear();
    _focusNode.requestFocus();

    // 立即添加用户消息到UI和存储
    final userMessage = ConversationMessage(
      id: ConversationService.generateMessageId(),
      type: MessageType.user,
      content: userInput,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    
    // 立即保存用户消息到存储
    await ConversationService.addMessage(userMessage);
    
    // 立即滚动到底部显示用户消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // 🔧 显示强制性进度弹窗
    final l10n = AppLocalizations.of(context)!;
    _progressController.show(
      title: l10n.aiDesignerWorking,
      description: l10n.aiDesignerWorkingDesc,
      taskType: 'customize',
      allowCancel: false,
    );

    try {
      setState(() {
        _isLoading = true;
      });
      
      final provider = Provider.of<CalculatorProvider>(context, listen: false);
      final currentConfig = provider.config;
      
      // 使用AI生成服务，带进度回调
      final config = await AIService.generateCalculatorFromPrompt(
        userInput,
        currentConfig: currentConfig,
        skipUserMessage: true,
        onProgress: (progress) {
          // 更新进度弹窗
          String statusMessage = '正在生成配置...';
          if (progress < 0.3) {
            statusMessage = '正在分析您的需求...';
          } else if (progress < 0.6) {
            statusMessage = '正在设计计算器功能...';
          } else if (progress < 0.9) {
            statusMessage = '正在优化配置...';
          } else {
            statusMessage = '即将完成...';
          }
          
          _progressController.updateProgress(progress, statusMessage);
        },
        onStatusUpdate: (status) {
          // 更新状态消息
          _progressController.updateProgress(_progressController.progress, status);
        },
      );

      // 隐藏进度弹窗
      _progressController.hide();

      if (config != null) {
        await provider.applyConfig(config);
        await _reloadSession();
        await _addAssistantMessage(l10n.designComplete);
        
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.designCompleteWithName(config.name)),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: l10n.view,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pop(); // 返回计算器界面
                },
              ),
            ),
          );
        }
      } else {
        await _addAssistantMessage(l10n.sorryDifficulty);
      }
      
    } catch (e) {
      // 隐藏进度弹窗
      _progressController.hide();
      
      await _addAssistantMessage(l10n.smallProblem(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🔧 新增：AI生成任务完成回调
  void _onAiGenerationCompleted(GenerationTask task) async {
    if (!mounted) return;
    
    try {
      // 解析生成结果
      final resultData = json.decode(task.result!);
      final config = CalculatorConfig.fromJson(resultData);
      
      // 应用配置
      final provider = Provider.of<CalculatorProvider>(context, listen: false);
      await provider.applyConfig(config);
      
      // 添加成功消息
      await _addAssistantMessage(
        '✅ 功能设计完成！已为您自动应用到计算器。\n\n🎯 新功能：${config.name}\n💡 ${config.description}\n\n您可以立即开始使用新功能，或继续告诉我其他需求！',
        config: config,
      );
      
      // 重新加载会话
      await _reloadSession();
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${config.name} 已自动应用！'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // 返回计算器界面
              },
            ),
          ),
        );
      }
      
    } catch (e) {
      print('解析AI生成结果失败: $e');
      await _addAssistantMessage('😅 生成完成，但应用时遇到了小问题：$e\n\n请重新描述您的需求。');
    }
  }

  /// 🔧 新增：AI生成任务失败回调
  void _onAiGenerationFailed(GenerationTask task) async {
    if (!mounted) return;
    
    final errorMsg = task.error ?? '未知错误';
    await _addAssistantMessage('😓 生成失败：$errorMsg\n\n不用担心，请重新描述您的需求，我会再次为您设计！');
  }

  /// 🔧 新增：获取对话历史
  Future<List<Map<String, String>>> _getConversationHistory() async {
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

  /// 测试网络连接
  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.network_check, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.networkTest),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.testingConnection),
          ],
        ),
      ),
    );

    try {
      final isConnected = await AIService.testConnection();
      Navigator.of(context).pop(); // 关闭加载对话框
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle : Icons.error,
                color: isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(isConnected ? l10n.connectionSuccess : l10n.connectionFailed),
            ],
          ),
          content: Text(
            isConnected 
                ? l10n.connectionSuccessDesc
                : l10n.connectionFailedDesc,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
            ),
            if (!isConnected)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _testConnection(); // 重新测试
                },
                child: Text(l10n.retry),
              ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // 关闭加载对话框
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.testFailed),
            ],
          ),
          content: Text(l10n.testFailedDesc(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testConnection(); // 重新测试
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
  }

  /// 重新加载会话以同步AIService记录的消息
  Future<void> _reloadSession() async {
    try {
      final session = await ConversationService.getCurrentSession();
      if (session != null) {
        setState(() {
          _messages = session.messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('重新加载会话失败: $e');
    }
  }

  void _showQuickReplies() {
    final l10n = AppLocalizations.of(context)!;
    final quickReplies = [
      // 🎯 简单实用个性化案例 - 放到最前面
      '添加"log₉"按键，计算以9为底的对数：log₉(x) = log(x)/log(9)，适合特定数学计算需求',
      
      '新增"π×"按键，直接计算圆周率倍数：x×3.14159，常用于几何计算',
      
      '添加"²⁄₃次方"按键，计算立方根的平方：x^(2/3)，适合工程和数学计算',
      
      '新增"黄金比例"按键，计算黄金分割：x×1.618，用于设计和美学比例',
      
      '添加"e^x/10"按键，计算缩放指数：e^(x/10)，适合数据分析和统计',
      
      '新增"√(x²+1)"按键，计算勾股定理变形：√(x²+1)，常用于几何计算',
      
      '添加"1/√x"按键，计算平方根的倒数：1/√x，用于物理和工程计算',
      
      '新增"log₂"按键，计算以2为底的对数：log₂(x) = log(x)/log(2)，计算机科学常用',
      
      '添加"x mod 7"按键，计算除以7的余数：x % 7，用于周期性计算',
      
      '新增"华氏度"按键，摄氏度转华氏度：x×9/5+32，日常温度转换',
      
      // 🔬 科学计算基础功能
      '新增科学计算按键组：sin/cos/tan三角函数、log/ln对数函数、x²/x³/√x幂运算，提供完整科学计算能力',
      
      '添加"度数转弧度"按键：x×π/180，和"弧度转度数"按键：x×180/π，角度单位转换',
      
      // 💰 实用金融工具
      '添加"房贷计算器"按键，输入贷款金额(万)、利率(%)、年数，计算月供金额',
      
      '新增"复利计算"按键，输入本金、年利率、年数，计算复利收益',
      
      // 📏 日常单位转换
      '增加单位转换按键组：英寸↔厘米(×2.54)、磅↔公斤(×0.453)、英尺↔米(×0.3048)',
      
      // 🎮 趣味个性计算
      '添加"狗狗年龄"按键，计算狗龄对应人类年龄：16×ln(狗龄)+15',
      
      '新增"BMI计算"按键，输入身高(cm)和体重(kg)，计算健康指数',
      
      '添加"小费计算"按键组：15%小费(×0.15)、18%小费(×0.18)、20%小费(×0.20)',
      
      // 保留少量经典案例
      '添加"奶茶成瘾度"按键，输入体重计算个人奶茶安全指数：体重×1.2×0.8×2.5',
      
      '新增"熬夜伤害值"按键，输入年龄计算熬夜对身体的伤害：(24-6)²×年龄×0.03×1.2'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.quickRepliesTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.quickRepliesSubtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: quickReplies.length,
                itemBuilder: (context, index) {
                  final reply = quickReplies[index];
                  
                  // 简化色彩设计：按功能类型分组
                  final categoryColors = [
                    // 个性化数学函数 - 蓝色系
                    [const Color(0xFFE3F2FD), const Color(0xFF2196F3)], // log₉
                    [const Color(0xFFE8F5E8), const Color(0xFF4CAF50)], // π×
                    [const Color(0xFFFFF3E0), const Color(0xFFFF9800)], // ²⁄₃次方
                    [const Color(0xFFF3E5F5), const Color(0xFF9C27B0)], // 黄金比例
                    [const Color(0xFFE0F2F1), const Color(0xFF009688)], // e^x/10
                    [const Color(0xFFE3F2FD), const Color(0xFF2196F3)], // √(x²+1)
                    [const Color(0xFFE8F5E8), const Color(0xFF4CAF50)], // 1/√x
                    [const Color(0xFFFFF3E0), const Color(0xFFFF9800)], // log₂
                    [const Color(0xFFF3E5F5), const Color(0xFF9C27B0)], // x mod 7
                    [const Color(0xFFE0F2F1), const Color(0xFF009688)], // 华氏度
                    
                    // 科学计算 - 深蓝色
                    [const Color(0xFF1A237E), const Color(0xFF3F51B5)],
                    [const Color(0xFF0D47A1), const Color(0xFF2196F3)],
                    
                    // 金融工具 - 绿色
                    [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
                    [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                    
                    // 单位转换 - 橙色
                    [const Color(0xFFE65100), const Color(0xFFFF9800)],
                    
                    // 趣味计算 - 紫色
                    [const Color(0xFF4A148C), const Color(0xFF9C27B0)],
                    [const Color(0xFF6A1B9A), const Color(0xFFBA68C8)],
                    [const Color(0xFF4A148C), const Color(0xFF9C27B0)],
                    
                    // 经典案例 - 灰色
                    [const Color(0xFF424242), const Color(0xFF757575)],
                    [const Color(0xFF616161), const Color(0xFF9E9E9E)],
                  ];
                  
                  final colorPair = categoryColors[index % categoryColors.length];
                  
                  // 功能图标设计
                  final categoryIcons = [
                    // 个性化数学函数
                    Icons.functions,           // log₉
                    Icons.circle,             // π×
                    Icons.superscript,        // ²⁄₃次方
                    Icons.auto_awesome,       // 黄金比例
                    Icons.trending_up,        // e^x/10
                    Icons.square_foot,        // √(x²+1)
                    Icons.flip,               // 1/√x
                    Icons.memory,             // log₂
                    Icons.calculate,          // x mod 7
                    Icons.thermostat,         // 华氏度
                    
                    // 科学计算
                    Icons.science,
                    Icons.rotate_90_degrees_ccw,
                    
                    // 金融工具
                    Icons.home,
                    Icons.savings,
                    
                    // 单位转换
                    Icons.straighten,
                    
                    // 趣味计算
                    Icons.pets,
                    Icons.monitor_weight,
                    Icons.restaurant,
                    
                    // 经典案例
                    Icons.local_cafe,
                    Icons.bedtime,
                  ];
                  
                  final icon = categoryIcons[index % categoryIcons.length];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _sendMessage(reply);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colorPair,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorPair[1].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 功能图标
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: colorPair[1],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 案例描述
                              Expanded(
                                child: Text(
                                  reply,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          l10n.progressiveDesign,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.progressiveDesignDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearConversation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.startNewConversation),
          ],
        ),
        content: Text(l10n.startNewConversationDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // 重置为默认计算器配置，但保留图像工坊的内容
              final provider = Provider.of<CalculatorProvider>(context, listen: false);
              final currentConfig = provider.config;
              
              // 创建默认配置
              final defaultConfig = CalculatorConfig.createDefault();
              
              // 🔧 保留图像工坊的内容：APP背景图和按键背景图
              final preservedConfig = CalculatorConfig(
                id: defaultConfig.id,
                name: defaultConfig.name,
                description: defaultConfig.description,
                theme: defaultConfig.theme,
                layout: CalculatorLayout(
                  name: defaultConfig.layout.name,
                  rows: defaultConfig.layout.rows,
                  columns: defaultConfig.layout.columns,
                  buttons: defaultConfig.layout.buttons.map((defaultButton) {
                    // 查找原配置中对应的按键，保留背景图
                    final originalButton = currentConfig.layout.buttons.firstWhere(
                      (b) => b.id == defaultButton.id,
                      orElse: () => defaultButton,
                    );
                    
                    // 只保留背景图，其他属性使用默认值
                    return CalculatorButton(
                      id: defaultButton.id,
                      label: defaultButton.label,
                      action: defaultButton.action,
                      gridPosition: defaultButton.gridPosition,
                      type: defaultButton.type,
                      customColor: defaultButton.customColor,
                      isWide: defaultButton.isWide,
                      widthMultiplier: defaultButton.widthMultiplier,
                      heightMultiplier: defaultButton.heightMultiplier,
                      gradientColors: defaultButton.gradientColors,
                      backgroundImage: originalButton.backgroundImage, // 🔧 保留背景图
                      fontSize: defaultButton.fontSize,
                      borderRadius: defaultButton.borderRadius,
                      elevation: defaultButton.elevation,
                      width: defaultButton.width,
                      height: defaultButton.height,
                      backgroundColor: defaultButton.backgroundColor,
                      textColor: defaultButton.textColor,
                      borderColor: defaultButton.borderColor,
                      borderWidth: defaultButton.borderWidth,
                      shadowColor: defaultButton.shadowColor,
                      shadowOffset: defaultButton.shadowOffset,
                      shadowRadius: defaultButton.shadowRadius,
                      opacity: defaultButton.opacity,
                      rotation: defaultButton.rotation,
                      scale: defaultButton.scale,
                      backgroundPattern: defaultButton.backgroundPattern,
                      patternColor: defaultButton.patternColor,
                      patternOpacity: defaultButton.patternOpacity,
                      animation: defaultButton.animation,
                      animationDuration: defaultButton.animationDuration,
                      customIcon: defaultButton.customIcon,
                      iconSize: defaultButton.iconSize,
                      iconColor: defaultButton.iconColor,
                    );
                  }).toList(),
                  description: defaultConfig.layout.description,
                  minButtonSize: defaultConfig.layout.minButtonSize,
                  maxButtonSize: defaultConfig.layout.maxButtonSize,
                  gridSpacing: defaultConfig.layout.gridSpacing,
                ),
                appBackground: currentConfig.appBackground, // 🔧 保留APP背景图
                version: defaultConfig.version,
                createdAt: defaultConfig.createdAt,
                authorPrompt: defaultConfig.authorPrompt,
                thinkingProcess: defaultConfig.thinkingProcess,
                aiResponse: defaultConfig.aiResponse,
              );
              
              await provider.applyConfig(preservedConfig);
              
              // 完全重置计算器状态，包括清除所有计算数据
              provider.resetCalculatorState();
              
              // 删除当前对话会话
              if (_currentSession != null) {
                await ConversationService.deleteSession(_currentSession!.id);
              }
              
              // 重新加载对话（会创建新会话）
              await _loadCurrentSession();
              
              // 显示重置成功提示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.resetSuccess),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.startNewConversation, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage message, int index) {
    final l10n = AppLocalizations.of(context)!;
    final isUser = message.type == MessageType.user;
    final isSystem = message.type == MessageType.system;
    final isFirst = index == 0 || _messages[index - 1].type != message.type;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(
                top: isFirst ? 16 : 4,
                bottom: 4,
                left: isUser ? 64 : 16,
                right: isUser ? 16 : 64,
              ),
            child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                  if (isFirst && !isSystem) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
                      child: Text(
                        isUser ? l10n.you : l10n.aiAssistant,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(message, index),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _getBubbleColor(message),
                        borderRadius: _getBubbleRadius(message, isFirst),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                            message.content,
                            style: TextStyle(
                              color: _getTextColor(message),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        if (message.metadata?['hasConfig'] == true) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '已应用到计算器',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (message.metadata?['hasThinkingProcess'] == true) ...[
                                GestureDetector(
                                  onTap: () {
                                    final thinkingProcess = message.metadata?['thinkingProcess'] as String?;
                                    final configName = message.metadata?['configName'] as String? ?? '计算器';
                                    if (thinkingProcess != null) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierColor: Colors.black.withValues(alpha: 0.7),
                                        builder: (context) => ThinkingProcessDialog(
                                          thinkingProcess: thinkingProcess,
                                          calculatorName: configName,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple.shade400, Colors.indigo.shade500],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.psychology, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          '查看思考过程',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 显示消息选项菜单（编辑、复制等）
  void _showMessageOptions(ConversationMessage message, int index) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.messageOptions,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.copy, color: Colors.blue.shade600),
                title: Text(l10n.copyMessage),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message);
                },
              ),
              if (message.type == MessageType.user) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.orange.shade600),
                  title: Text(l10n.editMessage),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message, index);
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: Text(l10n.deleteMessage),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 复制消息内容
  void _copyMessage(ConversationMessage message) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.messageCopied),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 编辑用户消息
  void _editMessage(ConversationMessage message, int index) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editMessageTitle),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: l10n.editMessageHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                Navigator.pop(context);
                await _updateMessage(index, newContent);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 更新消息内容
  Future<void> _updateMessage(int index, String newContent) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final oldMessage = _messages[index];
      final updatedMessage = ConversationMessage(
        id: oldMessage.id,
        type: oldMessage.type,
        content: newContent,
        timestamp: oldMessage.timestamp,
        metadata: oldMessage.metadata,
      );

      // 更新本地状态
      setState(() {
        _messages[index] = updatedMessage;
      });

      // 更新存储的会话
      await ConversationService.updateMessage(updatedMessage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageUpdated),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.updateFailed(e.toString())),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 删除消息
  Future<void> _deleteMessage(int index) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMessageTitle),
        content: Text(l10n.deleteMessageDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final messageToDelete = _messages[index];
                
                // 更新本地状态
                setState(() {
                  _messages.removeAt(index);
                });

                // 从存储中删除
                await ConversationService.deleteMessage(messageToDelete.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.messageDeleted),
                    backgroundColor: Colors.orange.shade600,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.deleteFailed(e.toString())),
                    backgroundColor: Colors.red.shade600,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor(ConversationMessage message) {
    switch (message.type) {
      case MessageType.user:
        return const Color(0xFF6366F1);
      case MessageType.system:
        return Colors.grey.shade100;
      case MessageType.assistant:
        return Colors.white;
    }
  }

  Color _getTextColor(ConversationMessage message) {
    switch (message.type) {
      case MessageType.user:
        return Colors.white;
      case MessageType.system:
        return Colors.grey.shade700;
      case MessageType.assistant:
        return Colors.grey.shade800;
    }
  }

  BorderRadius _getBubbleRadius(ConversationMessage message, bool isFirst) {
    const radius = Radius.circular(20);
    const smallRadius = Radius.circular(4);
    
    if (message.type == MessageType.system) {
      return BorderRadius.circular(16);
    }
    
    final isUser = message.type == MessageType.user;
    
    return BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isUser ? radius : (isFirst ? radius : smallRadius),
      bottomRight: isUser ? (isFirst ? radius : smallRadius) : radius,
    );
  }

  Widget _buildTypingIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 64, top: 8, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                    ),
                  ),
                  const SizedBox(width: 12),
            Text(
              l10n.designing,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1), size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.aiDesignerScreenTitle,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
            onPressed: _showQuickReplies,
            tooltip: l10n.quickIdeas,
          ),

          IconButton(
            icon: Icon(Icons.refresh, color: Colors.orange.shade600),
            onPressed: _clearConversation,
            tooltip: l10n.newConversation,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 🔧 新增：全局生成状态栏
              const GlobalGenerationStatusBar(),
              
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index], index);
                  },
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l10n.describeCalculator,
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: _sendMessage,
                            enabled: !_isLoading,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 网络测试按钮
                      IconButton(
                        icon: const Icon(Icons.network_check, size: 20),
                        onPressed: _testConnection,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: l10n.testNetworkConnection,
                      ),
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _textController.text.trim().isNotEmpty && !_isLoading
                                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                : [Colors.grey.shade300, Colors.grey.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: _textController.text.trim().isNotEmpty && !_isLoading
                              ? [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isLoading ? Icons.hourglass_empty : Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isLoading 
                              ? null 
                              : () => _sendMessage(_textController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // 🔧 进度弹窗
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              if (!_progressController.isVisible) {
                return const SizedBox.shrink();
              }
              
              return AIGenerationProgressDialog(
                title: _progressController.title,
                description: _progressController.description,
                progress: _progressController.progress,
                statusMessage: _progressController.statusMessage,
                taskType: _progressController.taskType,
                allowCancel: _progressController.allowCancel,
                onCancel: _progressController.onCancel,
              );
            },
          ),
        ],
      ),
    );
  }
} 