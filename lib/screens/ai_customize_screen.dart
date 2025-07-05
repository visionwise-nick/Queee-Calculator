import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../models/calculator_dsl.dart';
import '../widgets/thinking_process_dialog.dart';

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
      '👋 你好！我是你的专属计算器功能设计师',
      '✨ 我是专业计算器功能设计大师！我专注于为你设计和扩展计算器的功能逻辑！\n\n🚀 我专门负责：\n• 功能扩展（科学计算、金融工具、单位转换）\n• 智能计算（方程求解、数据分析、统计计算）\n• 实用工具（汇率换算、折扣计算、贷款计算）\n• 按键功能定义（添加新计算按钮和功能）\n\n⚠️ 注意：我只负责功能设计，不处理外观样式（背景图、颜色、字体等）。如需修改外观，请使用"图像生成工坊"！',
      '💡 **快速上手案例**：\n\n🏦 **金融计算**：\n"利率3.5%，贷款30年，输入贷款金额，输出每月房贷"\n"4%年利率复利计算，投资期10年"\n"美元兑人民币汇率7.2，做货币转换"\n\n🔬 **科学计算**：\n"添加幂运算、对数、三角函数"\n"添加统计功能：平均数、标准差、方差"\n"添加组合排列计算"\n\n💼 **实用工具**：\n"打9折、8.5折、7折的折扣计算器"\n"BMI计算器，输入身高体重计算健康指数"\n"单位转换：厘米转英寸、公斤转磅"\n\n🎯 **使用技巧**：\n• 描述具体需求，我会自动生成对应按键\n• 说明参数范围，如"利率3.5%"会预设参数\n• 提及使用场景，我会优化操作流程',
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
      _isLoading = true;
    });
    
    // 立即保存用户消息到存储
    await ConversationService.addMessage(userMessage);
    
    // 立即滚动到底部显示用户消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final provider = Provider.of<CalculatorProvider>(context, listen: false);
      final currentConfig = provider.config;
      
      // AIService会自动处理AI消息记录，跳过用户消息记录
      final config = await AIService.generateCalculatorFromPrompt(
        userInput,
        currentConfig: currentConfig,
        skipUserMessage: true, // 跳过用户消息记录
      );

      if (config != null) {
        await provider.applyConfig(config);
        // 重新加载会话以获取AI记录的消息
        await _reloadSession();
      } else {
        // 只有在失败时才手动添加错误消息
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

  /// 测试网络连接
  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.network_check, color: Colors.blue),
            SizedBox(width: 8),
            Text('网络连接测试'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在测试AI服务连接...'),
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
              Text(isConnected ? '连接成功' : '连接失败'),
            ],
          ),
          content: Text(
            isConnected 
                ? '✅ AI服务连接正常，可以正常使用AI定制功能。'
                : '❌ 无法连接到AI服务。请检查网络连接或稍后重试。\n\n可能的原因：\n• 网络连接问题\n• 防火墙阻止\n• 服务暂时不可用',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
            if (!isConnected)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _testConnection(); // 重新测试
                },
                child: const Text('重新测试'),
              ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // 关闭加载对话框
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('测试失败'),
            ],
          ),
          content: Text('测试过程中发生错误：\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testConnection(); // 重新测试
              },
              child: const Text('重新测试'),
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

  void _showAdvancedPromptSheet(BuildContext context) {
    // 🚀 全新功能案例库 - 聚焦专业金融投研 & 潮流生活娱乐
    final quickReplies = [
      // --- 📈 专业金融投研 ---
      '给我一个"A股打新收益测算器"，需要输入新股价格、中签率、首日涨幅预期，然后计算出期望收益', // Level 1
      '在"打新测算器"基础上，增加一个"港股打新"模式，要考虑甲乙组、孖展倍数和手续费，然后对比A股和港股打新的不同', // Level 2
      '我需要一个专业的"股票成本与盈亏分析器"，支持多次买入和卖出，自动扣除佣金（万分之三）、印花税（千分之一），最后计算出真实的持仓成本和盈亏金额', // Level 3
      '升级"股票分析器"，增加"T+0成本计算"功能，模拟日内交易后成本的变化，帮助我决定做T策略', // Level 4
      '创建一个"基金定投复利计算器"，可以设置每月定投金额、预期年化收益率、定投年限，然后帮我计算出最终的本息总额和复利收益', // Level 5
      '我需要一个高风险的"加密货币合约计算器"，输入开仓价格、保证金、杠杆倍数，能帮我实时算出强平价格和预估的爆仓风险', // Level 6

      // --- 🎮 潮流生活娱乐 ---
      '做一个"游戏抽卡期望值计算器"，让我可以输入单抽概率、是否有保底机制，它能告诉我抽出目标角色大概需要多少抽', // Level 7
      '升级"抽卡计算器"，加入"成本计算"功能，让我输入每抽的价格，它能告诉我抽出一个满命座/满精炼的角色需要花多少钱', // Level 8
      '我是二次元爱好者，需要一个"谷子调价计算器"，能根据我入手的日元价格、当前汇率、国际运费和包装材料费，帮我算出每个吧唧的真实人民币成本', // Level 9
      '我是海淘达人，创建一个"海淘转运凑单计算器"，能根据商品价格、消费税、国际运费（按重量计费）、关税，帮我找到最划算的凑单方案', // Level 10
      '要去听演唱会，做一个"远征预算规划器"，一站式计算来回机票、酒店住宿、门票、荧光棒和当地交通的总开销', // Level 11

      // --- 🏠 保留的核心实用 ---
      '最后，给我一个专业的"房贷专家计算器"，除了计算月供，还要能对比等额本息和等额本金两种模式的总利息差异，并计算提前还款能省多少钱', // Level 12
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚀 全新功能案例库 - 聚焦专业金融投研 & 潮流生活娱乐',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '每个案例都极具挑战性，考验AI能力',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  
                  // 🎨 全新色彩和图标体系
                  final categoryColors = [
                    // 金融投研 - 蓝色系 (专业、冷静)
                    [Colors.blue.shade100, Colors.blue.shade700],
                    [Colors.blue.shade100, Colors.blue.shade700],
                    [Colors.blue.shade200, Colors.blue.shade800],
                    [Colors.blue.shade200, Colors.blue.shade800],
                    [Colors.blue.shade300, Colors.blue.shade900],
                    [Colors.blue.shade300, Colors.blue.shade900],
                    // 潮流生活 - 紫色系 (时尚、新潮)
                    [Colors.purple.shade100, Colors.purple.shade700],
                    [Colors.purple.shade100, Colors.purple.shade700],
                    [Colors.purple.shade200, Colors.purple.shade800],
                    [Colors.purple.shade200, Colors.purple.shade800],
                    [Colors.purple.shade300, Colors.purple.shade900],
                    // 核心实用 - 绿色系 (可靠、实用)
                    [Colors.green.shade100, Colors.green.shade700],
                  ];
                  
                  final categoryIcons = [
                    // 金融投研
                    Icons.show_chart,         // A股打新
                    Icons.sync_alt,          // 港股打新对比
                    Icons.attach_money,      // 股票成本
                    Icons.candlestick_chart, // T+0成本
                    Icons.stacked_line_chart,  // 基金定投
                    Icons.currency_bitcoin,  // 加密货币合约
                    // 潮流生活
                    Icons.sports_esports,    // 游戏抽卡
                    Icons.diamond,           // 抽卡成本
                    Icons.card_giftcard,     // 谷子调价
                    Icons.local_shipping,    // 海淘凑单
                    Icons.music_note,        // 演唱会预算
                    // 核心实用
                    Icons.real_estate_agent, // 房贷专家
                  ];

                  final colorPair = categoryColors[index];
                  final icon = categoryIcons[index];
                  
                  // 类别标签
                  String categoryLabel;
                  Color categoryColor;
                  if (index < 6) {
                    categoryLabel = '金融投研';
                    categoryColor = Colors.blue.shade800;
                  } else if (index < 11) {
                    categoryLabel = '潮流生活';
                    categoryColor = Colors.purple.shade800;
                  } else {
                    categoryLabel = '核心实用';
                    categoryColor = Colors.green.shade800;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorPair[0], colorPair[0].withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorPair[1].withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: colorPair[1].withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context);
                          _sendMessage(reply);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 图标和类别标签
                              Column(
                                children: [
                                  Icon(icon, color: colorPair[1], size: 28),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colorPair[1].withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      categoryLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // 案例描述
                              Expanded(
                                child: Text(
                                  reply,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
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
        content: const Text('要开始一个全新的设计对话吗？\n\n计算器将重置为默认样式。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // 重置为默认计算器配置
              final provider = Provider.of<CalculatorProvider>(context, listen: false);
              final defaultConfig = CalculatorConfig.createDefault();
              await provider.applyConfig(defaultConfig);
              
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
                    content: const Text('✅ 已重置为默认计算器，开始新的设计对话！'),
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
                  '消息选项',
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
                title: const Text('复制消息'),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message);
                },
              ),
              if (message.type == MessageType.user) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.orange.shade600),
                  title: const Text('编辑消息'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message, index);
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: const Text('删除消息'),
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
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('消息已复制到剪贴板'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 编辑用户消息
  void _editMessage(ConversationMessage message, int index) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: '输入新的消息内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 更新消息内容
  Future<void> _updateMessage(int index, String newContent) async {
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
          content: const Text('消息已更新'),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新失败: $e'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 删除消息
  Future<void> _deleteMessage(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
                    content: const Text('消息已删除'),
                    backgroundColor: Colors.orange.shade600,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('删除失败: $e'),
                    backgroundColor: Colors.red.shade600,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
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
            onPressed: () => _showAdvancedPromptSheet(context),
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
                  const SizedBox(width: 8),
                  // 网络测试按钮
                  IconButton(
                    icon: const Icon(Icons.network_check, size: 20),
                    onPressed: _testConnection,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: '测试网络连接',
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
    );
  }
} 