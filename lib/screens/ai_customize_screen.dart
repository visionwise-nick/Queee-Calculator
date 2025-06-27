import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../models/calculator_dsl.dart';

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
    final welcomeMessages = [
      '👋 你好！我是你的专属计算器设计师',
              '✨ 我是专业计算器设计大师！我会在保留所有基础功能的前提下，为你增加强大的新功能！\n\n🚀 我擅长创造：\n• 丰富功能扩展（科学计算、金融工具、单位转换）\n• 专业级主题设计（视觉效果、配色方案、动画效果）\n• 智能布局优化（功能分区、按钮排列、用户体验）\n• 永远保留原有功能（绝不删除基础按钮）\n\n💡 点击灯泡查看专业设计画廊，或者描述你需要的功能！',
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
    final message = ConversationMessage(
      id: ConversationService.generateMessageId(),
      type: MessageType.assistant,
      content: content,
      timestamp: DateTime.now(),
      metadata: config != null ? {'hasConfig': true, 'configName': config.name} : null,
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

    await _addUserMessage(userInput);

    setState(() {
      _isLoading = true;
    });

    try {
      final config = await AIService.generateCalculatorFromPrompt(userInput);

      if (config != null) {
        final provider = Provider.of<CalculatorProvider>(context, listen: false);
        await provider.applyConfig(config);

        await _addAssistantMessage(
          '🎉 完美！我为你创建了"${config.name}"！\n\n${config.description}\n\n还想要什么调整吗？随时告诉我！',
          config: config,
        );
      } else {
        await _addAssistantMessage('😅 抱歉，我遇到了一些困难。能换个方式描述你的想法吗？');
      }
    } catch (e) {
      await _addAssistantMessage('😓 出现了一个小问题：$e\n\n不用担心，我们再试一次！');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showQuickReplies() {
    final quickReplies = [
      '设计一个完整的赛博朋克科学计算器：深黑背景配霓虹蓝边框，包含三角函数(sin/cos/tan)、对数运算(log/ln)、幂运算(x²/x³/x^y)、开根号等科学计算功能，按钮有发光效果和数字雨风格的未来感字体',
      '创建一个专业金融投资计算器：深海蓝渐变主题，包含复利计算、贷款利率、投资回报率、小费计算(15%/18%/20%)、税率计算、汇率转换等实用金融功能，配备专业的金融配色和图标',
      '我想要一个可爱粉色多功能计算器：粉色到紫色的渐变背景，圆润的心形按钮，包含基础运算、平方/立方计算、百分比计算、单位转换(华氏度/摄氏度、英寸/厘米)，还要有星星和爱心装饰元素',
      '设计一个苹果风格的极简高级计算器：纯白背景配浅灰按钮，包含基础四则运算、科学计算(sin/cos/log/sqrt)、工程计算(倒数/绝对值/阶乘)，按钮有轻微的阴影和圆角，整体极简优雅',
      '创建一个复古游戏机风格的多功能计算器：8位像素风格界面，复古绿色显示屏，包含基础运算、游戏相关计算(伤害计算/概率计算)、进制转换、随机数生成，按钮像游戏机按键一样有点击反馈',
      '我需要一个完整的工程师专用科学计算器：橙色工程主题，包含完整的三角函数、双曲函数、对数函数、指数函数、幂运算、根号运算、倒数、绝对值等，支持度数和弧度模式切换',
      '设计一个温暖自然的木质纹理计算器：真实木纹背景，棕色系按钮，包含基础运算、自然对数、温度转换、长度转换(英寸/厘米/英尺/米)、面积计算，按钮有木头质感和自然的颜色渐变',
      '创建一个护眼夜间模式专业计算器：深灰黑背景，温暖橙色数字显示，包含基础运算、科学计算、单位转换、百分比计算、记忆功能，专为夜间使用优化的低对比度配色方案',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette, color: Colors.amber.shade700),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '🎨 设计灵感画廊',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  final colors = [
                    [Colors.purple.shade100, Colors.purple.shade50],
                    [Colors.blue.shade100, Colors.blue.shade50],
                    [Colors.pink.shade100, Colors.pink.shade50],
                    [Colors.grey.shade100, Colors.grey.shade50],
                    [Colors.green.shade100, Colors.green.shade50],
                    [Colors.orange.shade100, Colors.orange.shade50],
                    [Colors.brown.shade100, Colors.brown.shade50],
                    [Colors.indigo.shade100, Colors.indigo.shade50],
                  ];
                  
                  final colorPair = colors[index % colors.length];
                  final icons = [
                    Icons.flash_on,
                    Icons.account_balance,
                    Icons.favorite,
                    Icons.apple,
                    Icons.games,
                    Icons.engineering,
                    Icons.nature,
                    Icons.bedtime,
                  ];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
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
                            border: Border.all(color: colorPair[0]),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icons[index % icons.length],
                                  color: colorPair[0],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  reply,
              style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
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
              child: Text(
                '💡 点击任意设计开始创作',
              style: TextStyle(
                  color: Colors.grey.shade600,
                fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
      children: [
            Icon(Icons.refresh, color: Colors.orange),
            SizedBox(width: 8),
            Text('开始新对话'),
          ],
        ),
        content: const Text('要开始一个全新的设计对话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (_currentSession != null) {
                await ConversationService.deleteSession(_currentSession!.id);
              }
              await _loadCurrentSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('开始新对话', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage message, int index) {
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
                        isUser ? '你' : '🤖 AI助手',
                  style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  Container(
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
                        ],
                      ],
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
              '正在设计中...',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
              children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 8),
                Text(
              'AI设计师',
                  style: TextStyle(
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
            tooltip: '快速想法',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.orange.shade600),
            onPressed: _clearConversation,
            tooltip: '新对话',
          ),
        ],
      ),
      body: Column(
        children: [
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
                        decoration: const InputDecoration(
                          hintText: '描述你想要的计算器...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: _sendMessage,
                        enabled: !_isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
    );
  }
} 