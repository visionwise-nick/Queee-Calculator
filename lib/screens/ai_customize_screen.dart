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

  void _showQuickReplies() {
    final quickReplies = [
      // 🔢 Level 1：基础数学增强 - 在标准计算器基础上增加平方根和百分比
      '基础计算器增强：在现有计算器基础上，添加√(开平方根)、x²(平方)、%(百分比)按键，让日常计算更便捷',
      
      // 🔬 Level 2：三角函数扩展 - 继续增加科学计算功能
      '三角函数计算器：在已有功能基础上，增加sin、cos、tan三角函数按键，支持角度计算，适用于工程和学习',
      
      // 📐 Level 3：对数指数增强 - 进一步扩展科学计算
      '对数指数计算器：继续添加ln(自然对数)、log(常用对数)、e^x(指数)、10^x(10的幂)按键，完善科学计算能力',
      
      // 🔄 Level 4：进制转换功能 - 添加程序员常用功能
      '进制转换计算器：新增二进制转换、八进制转换、十六进制转换按键，输入十进制数字一键转换其他进制',
      
      // 💰 Level 5：金融计算入门 - 添加基本金融功能
      '基础金融计算器：增加复利计算(本金、利率、年数)和汇率转换(金额、汇率)按键，满足投资理财基本需求',
      
      // 🏠 Level 6：房贷专业计算 - 专业金融计算扩展
      '房贷计算器专业版：添加房贷月供计算按键，输入贷款金额、年利率、贷款年限，一键计算每月还款额',
      
      // 📊 Level 7：统计分析功能 - 数据处理能力
      '统计分析计算器：新增平均值、标准差、方差、最大值、最小值按键，支持多数字输入进行统计分析',
      
      // 🔀 Level 8：组合排列数学 - 高级数学功能
      '组合排列计算器：添加组合C(n,r)、排列P(n,r)、阶乘n!按键，解决概率统计和数学问题',
      
      // 🏥 Level 9：生活实用工具 - 日常应用扩展
      '生活实用计算器：增加BMI计算(身高、体重)、小费计算(账单、小费率)、折扣计算(原价、折扣率)按键',
      
      // 🌡️ Level 10：单位转换大全 - 全方位转换功能
      '单位转换计算器：添加温度转换(摄氏度↔华氏度)、长度转换(厘米↔英寸)、重量转换(公斤↔磅)按键',
      
      // 🎯 Level 11：专业定制工具 - 行业专用功能
      '专业工具计算器：新增燃油效率(里程、油价)、学生成绩(各科分数平均)、餐厅AA(总额、人数)专用按键',
      
      // 🚀 Level 12：全功能计算器 - 终极完整版
      '全功能超级计算器：集成所有功能，包含基础运算+科学计算+金融工具+统计分析+单位转换+生活实用，打造专业计算平台',
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
                          '🚀 功能递进案例库',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '每个案例都在前面基础上增加新功能',
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
                  
                  // 递进式色彩设计：从浅到深表示功能的递进
                  final progressColors = [
                    // Level 1-3: 基础功能 - 绿色系（简单到复杂）
                    [const Color(0xFFE8F5E8), const Color(0xFFC8E6C9)], // 浅绿
                    [const Color(0xFFDCEDC8), const Color(0xFFAED581)], // 中绿  
                    [const Color(0xFFCDDC39), const Color(0xFF9E9D24)], // 深绿
                    
                    // Level 4-6: 专业功能 - 蓝色系（进阶功能）
                    [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)], // 浅蓝
                    [const Color(0xFF90CAF9), const Color(0xFF42A5F5)], // 中蓝
                    [const Color(0xFF2196F3), const Color(0xFF1976D2)], // 深蓝
                    
                    // Level 7-9: 高级功能 - 紫色系（高级功能）
                    [const Color(0xFFF3E5F5), const Color(0xFFCE93D8)], // 浅紫
                    [const Color(0xFFBA68C8), const Color(0xFF9C27B0)], // 中紫
                    [const Color(0xFF8E24AA), const Color(0xFF6A1B9A)], // 深紫
                    
                    // Level 10-12: 终极功能 - 橙色系（专家级）
                    [const Color(0xFFFFF3E0), const Color(0xFFFFCC02)], // 浅橙
                    [const Color(0xFFFFB74D), const Color(0xFFFF9800)], // 中橙
                    [const Color(0xFFFF6F00), const Color(0xFFE65100)], // 深橙
                  ];
                  
                  final colorPair = progressColors[index % progressColors.length];
                  
                  // 递进式图标设计
                  final progressIcons = [
                    // Level 1-3: 基础功能图标
                    Icons.calculate_outlined,        // 基础增强
                    Icons.functions,                 // 三角函数
                    Icons.science,                   // 对数指数
                    
                    // Level 4-6: 专业功能图标  
                    Icons.developer_mode,            // 进制转换
                    Icons.account_balance,           // 基础金融
                    Icons.home_work,                 // 房贷专业
                    
                    // Level 7-9: 高级功能图标
                    Icons.analytics,                 // 统计分析
                    Icons.scatter_plot,              // 组合排列
                    Icons.healing,                   // 生活实用
                    
                    // Level 10-12: 终极功能图标
                    Icons.swap_horiz,                // 单位转换
                    Icons.precision_manufacturing,   // 专业工具
                    Icons.rocket_launch,             // 全功能超级
                  ];
                  
                  final icon = progressIcons[index % progressIcons.length];
                  
                  // 递进式级别标签
                  final levelLabels = [
                    'Level 1', 'Level 2', 'Level 3', 'Level 4', 
                    'Level 5', 'Level 6', 'Level 7', 'Level 8',
                    'Level 9', 'Level 10', 'Level 11', 'Level 12'
                  ];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                            children: [
                              // 级别标签
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  levelLabels[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorPair[1],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
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
                              // 进度指示器
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(2),
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
                        const Text(
                          '💡 递进式设计理念',
              style: TextStyle(
                            fontWeight: FontWeight.bold,
                fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '每个级别都在前面基础上增加新功能，Level 1→Level 12 逐步构建功能完整的专业计算器',
                      style: TextStyle(
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