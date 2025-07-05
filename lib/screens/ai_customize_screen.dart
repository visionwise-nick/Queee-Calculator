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

  Future<void> _addAssistantMessage(String content, {CalculatorConfig? config, String? userPrompt}) async {
    final metadata = <String, dynamic>{};
    if (config != null) {
      metadata['hasConfig'] = true;
      metadata['configName'] = config.name;
      if (config.thinkingProcess != null) {
        metadata['hasThinkingProcess'] = true;
        metadata['thinkingProcess'] = config.thinkingProcess;
      }
    }
    if (userPrompt != null) {
      metadata['userPrompt'] = userPrompt;
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
      // 🐶 Level 1：宠物年龄换算器 - 预设狗狗年龄模型（刚需第一位）
      '添加"宠物年龄"按键，输入宠物年龄(岁)计算相当于人类年龄：宠物年龄×7×0.8×1.2+宠物年龄×2，预设换算系数7、品种系数0.8、健康系数1.2、基础年龄调整2',
      
      // 🏠 Level 2：一键房贷计算器 - 预设3.5%利率30年（刚需第二位）
      '添加"房贷神器"按键，输入贷款金额(万元)计算月供：贷款金额×10000×0.00292×(1.00292^360)÷((1.00292^360)-1)，预设3.5%年利率30年等额本息',
      
      // 🚗 Level 3：停车费计算器 - 预设城市停车模型（刚需）
      '新增"停车费"按键，输入停车时长(小时)计算总费用：时长×8×1.2+5×1.5，预设每小时8元、高峰系数1.2、起步费5元、超时系数1.5',
      
      // ☕ Level 4：咖啡因安全计算器 - 预设健康标准（刚需）
      '增加"咖啡因安全"按键，输入体重(kg)计算每日安全摄入量：体重×6×0.9×1.1，预设每公斤6mg安全标准、年龄系数0.9、健康系数1.1',
      
      // 🛒 Level 5：购物清单预算器 - 预设家庭开支模型（刚需）
      '添加"购物预算"按键，输入预算金额(元)计算合理分配：预算×0.4+预算×0.3+预算×0.2+预算×0.1，预设生鲜40%、日用30%、零食20%、应急10%',
      
      // 🚇 Level 6：通勤成本计算器 - 预设城市通勤模型（刚需）
      '新增"通勤成本"按键，输入通勤距离(公里)计算月度真实成本：距离×2×22×(8+5+2)×1.2+距离×50，预设往返2次、工作日22天、地铁8元+时间成本5元+疲劳成本2元、综合系数1.2、健康成本50元/公里',
      
      // 📱 Level 7：手机流量费用计算器 - 预设运营商模型（刚需）
      '增加"流量费用"按键，输入使用流量(GB)计算超额费用：(流量-10)×5×1.2+128，预设套餐10GB、超额每GB5元、高峰系数1.2、基础月费128元',
      
      // 🍕 Level 8：外卖真实成本计算器 - 预设外卖模型（刚需）
      '添加"外卖成本"按键，输入外卖次数计算月度真实成本：次数×(25+6+3)×1.15+次数×20，预设餐费25元、配送费6元、包装费3元、平台加价15%、健康成本20元/次',
      
      // 🎬 Level 9：观影时间价值计算器 - 预设娱乐价值模型
      '新增"观影价值"按键，输入电影时长(分钟)计算时间投入价值：时长×0.5×1.2+50×0.8，预设每分钟时间成本0.5元、娱乐价值系数1.2、票价50元、满意度0.8',
      
      // 💪 Level 10：健身效果计算器 - 预设运动科学模型
      '增加"健身效果"按键，输入运动时长(分钟)计算卡路里消耗：时长×8×0.8×1.3+时长×0.2，预设每分钟8卡、效率系数0.8、个人系数1.3、后燃效应0.2卡/分钟',
      
      // 🧋 Level 11：奶茶健康指数计算器 - 预设健康标准
      '添加"奶茶指数"按键，输入体重(kg)计算个人奶茶安全指数：体重×1.2×0.8×2.5，预设代谢率1.2、年龄系数0.8、运动频率2.5',
      
      // 🎮 Level 12：游戏氪金性价比分析器 - 预设玩家模型
      '新增"氪金性价比"按键，输入充值金额(元)计算真实价值：充值金额÷(50×1.5×100×30)，预设每月50小时、技能提升率1.5、社交价值100、时薪30元',
      
      // 😴 Level 13：熬夜损耗计算器 - 预设睡眠科学模型
      '增加"熬夜损耗"按键，输入熬夜时长(小时)计算健康损耗：熬夜时长×15×1.5×0.8，预设每小时损耗15点、累积系数1.5、恢复系数0.8',
      
      // 💕 Level 14：约会成本计算器 - 预设恋爱模型
      '添加"约会成本"按键，输入月收入(元)计算合理约会预算：月收入×0.15×1.2×0.9，预设约会占比15%、情感投资系数1.2、理性系数0.9',
      
      // 🚗 Level 15：购车全成本计算器 - 预设5年使用周期
      '新增"购车全成本"按键，输入车价(万元)计算5年总成本：车价×10000+车价×1000×5+15000×5+3000×10+车价×5000×0.6+1200×12×5，预设保险1000元/年、油费15000元/年、保养3000元/次×10次、折旧率60%、停车费1200元/月',
      
      // 💼 Level 16：跳槽收益分析器 - 预设职业发展模型
      '增加"跳槽收益"按键，输入新工作薪资(元)计算跳槽价值：(新薪资-8000)×0.8×1.2×1.1×1.3-5000，预设当前薪资8000元、稳定系数0.8、发展潜力1.2、学习成长1.1、行业前景1.3、跳槽风险成本5000元',
      
      // 📱 Level 17：社交媒体时间成本计算器 - 预设数字生活模型
      '添加"社交时间成本"按键，输入每日使用时长(小时)计算年度机会成本：时长×365×30×0.6，预设年度天数365、时薪30元、注意力价值折扣0.6',
      
      // 💰 Level 18：理财目标计算器 - 预设投资模型
      '新增"理财目标"按键，输入目标金额(万元)计算达成时间：目标金额×10000÷(5000×1.06^年数)，预设每月投资5000元、年化收益6%、复利计算模型',
      
      // 🎓 Level 19：学习效率计算器 - 预设学习科学模型
      '增加"学习效率"按键，输入学习天数计算掌握概率：(学习天数×2×0.8×1.2+20)÷100，预设每天学习2小时、吸收率0.8、个人系数1.2、基础概率20%、结果转换百分比',
      
      // 🏠 Level 20：租房性价比分析器 - 预设居住质量模型
      '添加"租房性价比"按键，输入房租(元)计算居住质量指数：房租÷(30×1.2×0.8×1.5×100)，预设每平米30元合理价格、位置系数1.2、配套系数0.8、交通系数1.5、质量基准100',
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
                  
                  // 递进式图标设计 - 刚需生活计算
                  final progressIcons = [
                    // Level 1-4: 核心刚需计算
                    Icons.pets,                      // 宠物年龄（刚需第一位）
                    Icons.calculate,                 // 房贷神器（刚需第二位）
                    Icons.local_parking,             // 停车费（城市刚需）
                    Icons.local_cafe,                // 咖啡因安全（健康刚需）
                    
                    // Level 5-8: 日常生活刚需
                    Icons.shopping_cart,             // 购物预算（家庭刚需）
                    Icons.commute,                   // 通勤成本（工作刚需）
                    Icons.signal_cellular_4_bar,     // 流量费用（通讯刚需）
                    Icons.restaurant,                // 外卖成本（餐饮刚需）
                    
                    // Level 9-12: 娱乐健康计算
                    Icons.movie,                     // 观影价值（娱乐时间）
                    Icons.fitness_center,            // 健身效果（运动健康）
                    Icons.local_drink,               // 奶茶指数（饮食健康）
                    Icons.sports_esports,            // 氪金性价比（游戏娱乐）
                    
                    // Level 13-16: 生活方式分析
                    Icons.bedtime,                   // 熬夜损耗（睡眠健康）
                    Icons.favorite,                  // 约会成本（情感投资）
                    Icons.directions_car,            // 购车全成本（大宗消费）
                    Icons.trending_up,               // 跳槽收益（职业发展）
                    
                    // Level 17-20: 深度生活分析
                    Icons.phone_android,             // 社交时间成本（数字生活）
                    Icons.savings,                   // 理财目标（财务规划）
                    Icons.school,                    // 学习效率（知识投资）
                    Icons.apartment,                 // 租房性价比（居住质量）
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

  /// 显示设计历史
  Future<void> _showDesignHistory() async {
    try {
      final designHistory = await ConversationService.getDesignHistorySummary();
      final stats = await ConversationService.getDesignHistoryStats();
      
      if (designHistory.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💡 还没有设计历史记录'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 自动清理旧记录
      await ConversationService.cleanupDesignHistory();

      if (mounted) {
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
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '设计历史',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '共 ${stats['designs']} 个设计',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // 历史记录列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: designHistory.length,
                    itemBuilder: (context, index) {
                      final item = designHistory[index];
                      final timestamp = item['timestamp'] as DateTime;
                      final configName = item['configName'] as String;
                      final summary = item['summary'] as String;
                      final userPrompt = item['userPrompt'] as String?;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            configName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (userPrompt != null && userPrompt.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '💬 "$userPrompt"',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                summary,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🕒 ${_formatTimestamp(timestamp)}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.restore, color: Colors.blue.shade600),
                                onPressed: () => _rollbackToDesign(item['id'] as String),
                                tooltip: '回滚到此设计',
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange.shade600),
                                onPressed: () => _editFromDesign(userPrompt ?? ''),
                                tooltip: '基于此设计重新编辑',
                              ),
                            ],
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
    } catch (e) {
      print('显示设计历史失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 加载设计历史失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  /// 回滚到指定设计
  Future<void> _rollbackToDesign(String messageId) async {
    try {
      Navigator.pop(context); // 关闭历史记录面板
      
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restore, color: Colors.blue),
              SizedBox(width: 8),
              Text('确认回滚'),
            ],
          ),
          content: const Text('确定要回滚到此设计吗？当前的计算器配置将被替换。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认回滚'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // 获取历史消息
      final designHistory = await ConversationService.getDesignHistory();
      final targetMessage = designHistory.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => throw Exception('未找到目标设计'),
      );
      
      // 从消息中恢复配置
      final configData = targetMessage.metadata?['configData'] as Map<String, dynamic>?;
      if (configData == null) {
        throw Exception('配置数据不完整，无法回滚');
      }
      
      // 恢复配置
      final config = CalculatorConfig.fromJson(configData);
      final provider = Provider.of<CalculatorProvider>(context, listen: false);
      await provider.applyConfig(config);
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已成功回滚到"${targetMessage.configName}"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // 记录回滚操作
      await _addSystemMessage('🔄 已回滚到历史设计："${targetMessage.configName}"');
      
    } catch (e) {
      print('回滚设计失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 回滚失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 基于历史设计重新编辑
  void _editFromDesign(String originalPrompt) {
    Navigator.pop(context); // 关闭历史记录面板
    
    // 将原始Prompt填入输入框
    _textController.text = originalPrompt;
    _focusNode.requestFocus();
    
    // 显示提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💡 已填入原始Prompt，您可以修改后重新生成'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            icon: Icon(Icons.restore, color: Colors.blue.shade600),
            onPressed: _showDesignHistory,
            tooltip: '设计历史',
          ),
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