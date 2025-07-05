import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../models/calculator_dsl.dart';
import '../widgets/thinking_process_dialog.dart';
import 'package:audioplayers/audioplayers.dart';
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
  
  final TextEditingController _soundPromptController = TextEditingController();
  bool _isGeneratingSound = false;
  String? _generatedSoundBase64;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _soundPromptController.dispose();
    _audioPlayer.dispose();
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
      // 🧋 Level 1：奶茶成瘾指数计算器 - 预设25岁标准
      '添加"奶茶成瘾度"按键，输入体重(kg)计算个人奶茶安全指数：体重×1.2×0.8×2.5，预设25岁成人、代谢率1.2、年龄系数0.8、运动频率2.5',
      
      // 🎮 Level 2：游戏氪金性价比分析器 - 预设标准玩家模型
      '新增"氪金性价比"按键，输入充值金额(元)计算真实价值：充值金额÷(50×1.5×100×30)，预设每月50小时、技能提升率1.5、社交价值100、时薪30元',
      
      // 😴 Level 3：熬夜生命损耗计算器 - 预设标准睡眠模型
      '增加"熬夜生命值"按键，输入年龄计算熬夜伤害：(24-6)²×年龄×0.03×1.2，预设6小时睡眠、身体指数0.03、恢复能力1.2',
      
      // 🏠 Level 4：一键房贷计算器 - 预设3.5%利率30年
      '添加"房贷神器"按键，输入贷款金额(万元)计算月供：贷款金额×10000×0.00292×(1.00292^360)÷((1.00292^360)-1)，预设3.5%年利率30年等额本息',
      
      // 🛍️ Level 5：网购真实成本分析器 - 预设隐性成本系数
      '新增"网购真相"按键，输入商品价格(元)计算真实成本：商品价格×(1+0.08+0.15+0.05+0.12)，预设快递费8%、时间成本15%、退换货风险5%、冲动溢价12%',
      
      // 💪 Level 6：个人减肥效率计算器 - 预设70kg基准
      '添加"减肥效率"按键，输入目标体重(kg)计算减肥天数：(70-目标体重)×7700÷(300+200)÷1500×0.8，预设当前70kg、运动消耗300卡、饮食控制200卡、基础代谢1500、年龄系数0.8',
      
      // ☕ Level 7：咖啡因代谢个性化计算器 - 预设标准代谢率
      '新增"咖啡因代谢"按键，输入体重(kg)计算每日安全摄入量：体重×6×1.0×0.9×1.1，预设每公斤6mg、代谢率1.0、年龄系数0.9、健康指数1.1',
      
      // 💕 Level 8：恋爱成本效益分析器 - 预设标准恋爱模型
      '增加"恋爱成本"按键，输入月收入(元)计算月恋爱成本：(月收入×0.3+月收入×0.2+月收入×0.1+月收入×0.05)×1.2×0.8，预设约会费30%、礼物20%、时间成本10%、机会成本5%、投资回报率1.2、幸福指数0.8',
      
      // 🚗 Level 9：购车综合成本计算器 - 预设5年使用周期
      '添加"购车真相"按键，输入车价(万元)计算5年总成本：车价×10000+车价×1000×5+15000×5+3000×10+车价×5000×0.6+1200×12×5，预设保险1000元/年、油费15000元/年、保养3000元/次×10次、折旧率60%、停车费1200元/月',
      
      // 🍕 Level 10：外卖健康成本双重计算器 - 预设标准外卖模型
      '新增"外卖双重成本"按键，输入月外卖次数计算总成本：次数×25×1.8+次数×50×1.5×0.6，预设外卖均价25元、溢价率1.8、健康成本50元/次、身体负担1.5、长期影响系数0.6',
      
      // 💼 Level 11：跳槽收益风险评估器 - 预设职业发展模型
      '增加"跳槽分析"按键，输入新工作薪资(元)计算跳槽价值：(新薪资-8000)×0.8×1.2×1.1×1.3-5000，预设当前薪资8000元、稳定系数0.8、发展潜力1.2、学习成长1.1、行业前景1.3、跳槽风险成本5000元',
      
      // 🌟 Level 12：网红打卡投资回报率计算器 - 预设社交资本模型
      '添加"打卡ROI"按键，输入打卡费用(元)计算社交投资回报：打卡费用÷(100×50×1.5×0.8)，预设社交影响力100、个人品牌价值50、网络效应1.5、长期收益潜力0.8',
      
      // 🐶 Level 13：宠物年龄换算器 - 预设狗狗年龄模型
      '添加"狗狗年龄"按键，输入狗狗年龄(岁)计算相当于人类年龄：狗狗年龄×7×0.8×1.2+狗狗年龄×2，预设换算系数7、品种系数0.8、健康系数1.2、基础年龄调整2',
      
      // 👍 Level 14：朋友圈点赞成本计算器 - 预设社交投入模型
      '添加"点赞成本"按键，输入每日点赞次数计算年度社交投入：点赞次数×0.5×365×1.2×0.8，预设每次点赞0.5分钟、全年365天、注意力成本1.2、社交回报0.8',
      
      // 📺 Level 15：追剧时间成本分析器 - 预设娱乐价值模型
      '添加"追剧成本"按键，输入剧集集数计算时间投入价值：剧集集数×45×30×0.6×1.5，预设每集45分钟、时薪30元、娱乐折扣0.6、情感价值1.5',
      
      // 🏃 Level 16：跑步减肥效果计算器 - 预设运动科学模型
      '添加"跑步减肥"按键，输入跑步时长(分钟)计算减肥效果：跑步时长×10×0.8×1.3÷7700×1000，预设每分钟消耗10卡、效率系数0.8、个人系数1.3、每克脂肪7700卡、结果转换克',
      
      // 🚇 Level 17：通勤成本综合计算器 - 预设城市通勤模型
      '添加"通勤成本"按键，输入通勤距离(公里)计算月度真实成本：距离×2×22×(8+5+2)×1.2+距离×50，预设往返2次、工作日22天、地铁8元+时间成本5元+疲劳成本2元、综合系数1.2、健康成本50元/公里',
      
      // 💰 Level 18：理财收益目标计算器 - 预设投资回报模型
      '添加"理财目标"按键，输入目标金额(万元)计算达成时间：目标金额×10000÷(5000×1.06^年数)，预设每月投资5000元、年化收益6%、复利计算模型',
      
      // 🎓 Level 19：考试通过率预测器 - 预设学习效率模型
      '添加"考试通过率"按键，输入学习天数计算通过概率：(学习天数×2×0.8×1.2+20)÷100，预设每天学习2小时、吸收率0.8、个人系数1.2、基础概率20%、结果转换百分比',
      
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
                  
                  // 递进式图标设计 - 复杂多因式计算
                  final progressIcons = [
                    // Level 1-4: 个性化健康评估
                    Icons.psychology,                // 奶茶成瘾度（心理健康）
                    Icons.analytics,                 // 游戏氪金性价比（数据分析）
                    Icons.health_and_safety,         // 熬夜生命值（健康安全）
                    Icons.calculate,                 // 房贷神器（复杂计算）
                    
                    // Level 5-8: 隐性成本分析
                    Icons.visibility,                // 网购真相（揭示隐性成本）
                    Icons.timeline,                  // 减肥效率（时间轴规划）
                    Icons.biotech,                   // 咖啡因代谢（生物技术）
                    Icons.account_balance_wallet,    // 恋爱成本（经济分析）
                    
                    // Level 9-12: 全生命周期评估
                    Icons.directions_car,            // 购车真相（汽车全成本）
                    Icons.restaurant,                // 外卖双重成本（餐饮分析）
                    Icons.trending_up,               // 跳槽分析（职业发展）
                    Icons.network_check,             // 打卡ROI（网络效应）
                    
                    // Level 13-16: 生活趣味计算
                    Icons.pets,                      // 狗狗年龄（宠物）
                    Icons.thumb_up,                  // 点赞成本（社交媒体）
                    Icons.tv,                        // 追剧成本（娱乐）
                    Icons.directions_run,            // 跑步减肥（运动健身）
                    
                    // Level 17-20: 生活质量评估
                    Icons.commute,                   // 通勤成本（交通）
                    Icons.savings,                   // 理财目标（投资）
                    Icons.school,                    // 考试通过率（学习）
                    Icons.apartment,                 // 租房性价比（居住）
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

  /// 🆕 生成音效
  Future<void> _generateSound() async {
    if (_soundPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入音效描述')),
      );
      return;
    }

    setState(() {
      _isGeneratingSound = true;
      _generatedSoundBase64 = null;
    });

    try {
      final base64Sound = await AIService.generateSoundEffect(
        prompt: _soundPromptController.text.trim(),
      );

      if (base64Sound != null) {
        setState(() {
          _generatedSoundBase64 = base64Sound;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 音效生成成功！点击预览按钮播放。'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 音效生成失败，请稍后重试。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 发生错误: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingSound = false;
      });
    }
  }

  /// 🆕 预览音效
  Future<void> _previewSound() async {
    if (_generatedSoundBase64 == null) return;
    try {
      await _audioPlayer.play(BytesSource(base64Decode(_generatedSoundBase64!)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 播放失败: $e')),
      );
    }
  }

  /// 🆕 应用音效
  void _applySound() {
    if (_generatedSoundBase64 == null) return;

    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    final currentConfig = provider.config;

    // 创建一个新的主题对象，只修改自定义音效字段
    final newTheme = currentConfig.theme.copyWith(
      customButtonSound: _generatedSoundBase64,
    );

    // 创建一个新的配置对象
    final newConfig = currentConfig.copyWith(
      theme: newTheme,
    );

    // 应用新配置
    provider.applyConfig(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 自定义音效已应用！'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 