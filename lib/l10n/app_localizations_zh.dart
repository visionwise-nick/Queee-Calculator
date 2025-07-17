// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get history => 'History';

  @override
  String get multiParamHelp => 'Multi-parameter Function Help';

  @override
  String get aiDesigner => 'AI设计师';

  @override
  String get imageWorkshop => 'Image Generation Workshop';

  @override
  String get appTitle => 'Queee Calculator (English)';

  @override
  String get aiDesignerScreenTitle => 'AI 设计师';

  @override
  String get aiDesignerTextFieldHint => '输入你的计算器设计需求...';

  @override
  String get imageGeneration => '图像生成工坊';

  @override
  String get themeSettings => '主题设置';

  @override
  String get welcomeMessage1 => '👋 你好！我是你的专属计算器功能设计师';

  @override
  String get welcomeMessage2 =>
      '✨ 我是专业计算器功能设计大师！我专注于为你设计和扩展计算器的功能逻辑！\n\n🚀 我专门负责：\n• 功能扩展（科学计算、金融工具、单位转换）\n• 智能计算（方程求解、数据分析、统计计算）\n• 实用工具（汇率换算、折扣计算、贷款计算）\n• 按键功能定义（添加新计算按钮和功能）\n\n⚠️ 注意：我只负责功能设计，不处理外观样式（背景图、颜色、字体等）。如需修改外观，请使用\"图像生成工坊\"！';

  @override
  String get welcomeMessage3 =>
      '💡 **快速上手案例**：\n\n🏦 **金融计算**：\n\"利率3.5%，贷款30年，输入贷款金额，输出每月房贷\"\n\"4%年利率复利计算，投资期10年\"\n\"美元兑人民币汇率7.2，做货币转换\"\n\n🔬 **科学计算**：\n\"添加幂运算、对数、三角函数\"\n\"添加统计功能：平均数、标准差、方差\"\n\"添加组合排列计算\"\n\n💼 **实用工具**：\n\"打9折、8.5折、7折的折扣计算器\"\n\"BMI计算器，输入身高体重计算健康指数\"\n\"单位转换：厘米转英寸、公斤转磅\"\n\n🎯 **使用技巧**：\n• 描述具体需求，我会自动生成对应按键\n• 说明参数范围，如\"利率3.5%\"会预设参数\n• 提及使用场景，我会优化操作流程';

  @override
  String get aiDesignerWorking => '🎯 AI设计师正在工作';

  @override
  String get aiDesignerWorkingDesc => '正在为您设计专属的计算器功能...';

  @override
  String get designComplete => '✅ 功能设计完成！已为您自动应用到计算器。';

  @override
  String designCompleteWithName(Object name) {
    return '🎉 $name 已成功应用！';
  }

  @override
  String get view => '查看';

  @override
  String get sorryDifficulty => '😅 抱歉，我遇到了一些困难。能换个方式描述你的想法吗？';

  @override
  String smallProblem(Object error) {
    return '😓 出现了一个小问题：$error\n\n不用担心，我们再试一次！';
  }

  @override
  String get networkTest => '网络连接测试';

  @override
  String get testingConnection => '正在测试AI服务连接...';

  @override
  String get connectionSuccess => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get connectionSuccessDesc => '✅ AI服务连接正常，可以正常使用AI定制功能。';

  @override
  String get connectionFailedDesc =>
      '❌ 无法连接到AI服务。请检查网络连接或稍后重试。\n\n可能的原因：\n• 网络连接问题\n• 防火墙阻止\n• 服务暂时不可用';

  @override
  String get confirm => '确定';

  @override
  String get retry => '重新测试';

  @override
  String get testFailed => '测试失败';

  @override
  String testFailedDesc(Object error) {
    return '测试过程中发生错误：\n$error';
  }

  @override
  String get quickRepliesTitle => '🎯 实用个性化案例库';

  @override
  String get quickRepliesSubtitle => '简单实用，但充满个性化的计算功能';

  @override
  String get progressiveDesign => '💡 递进式设计理念';

  @override
  String get progressiveDesignDesc =>
      '每个级别都在前面基础上增加新功能，Level 1→Level 20 逐步构建功能完整的专业计算器';

  @override
  String get startNewConversation => '开始新对话';

  @override
  String get startNewConversationDesc => '要开始一个全新的设计对话吗？\n\n计算器将重置为默认样式。';

  @override
  String get cancel => '取消';

  @override
  String get resetSuccess => '✅ 已重置为默认计算器功能，保留了图像工坊的背景图！';

  @override
  String get messageOptions => '消息选项';

  @override
  String get copyMessage => '复制消息';

  @override
  String get editMessage => '编辑消息';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get messageCopied => '消息已复制到剪贴板';

  @override
  String get editMessageTitle => '编辑消息';

  @override
  String get editMessageHint => '输入新的消息内容...';

  @override
  String get save => '保存';

  @override
  String get messageUpdated => '消息已更新';

  @override
  String updateFailed(Object error) {
    return '更新失败: $error';
  }

  @override
  String get deleteMessageTitle => '删除消息';

  @override
  String get deleteMessageDesc => '确定要删除这条消息吗？此操作无法撤销。';

  @override
  String get delete => '删除';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String deleteFailed(Object error) {
    return '删除失败: $error';
  }

  @override
  String get designing => '正在设计中...';

  @override
  String get quickIdeas => '快速想法';

  @override
  String get newConversation => '新对话';

  @override
  String get describeCalculator => '描述你想要的计算器...';

  @override
  String get testNetworkConnection => '测试网络连接';

  @override
  String get buttonBackground => '按键';

  @override
  String get appBackground => 'APP背景';

  @override
  String get displayArea => '显示区';

  @override
  String get opacityControl => '透明度控制';

  @override
  String get buttonOpacity => '按键透明度';

  @override
  String get displayOpacity => '显示区域透明度';

  @override
  String get appBackgroundOpacity => 'APP背景图透明度';

  @override
  String get customGeneration => '自定义生成';

  @override
  String get appBackgroundPrompt => '描述你想要的APP背景...';

  @override
  String get generateAppBackground => '生成APP背景';

  @override
  String get quickSelection => '快速选择';

  @override
  String get appBackgroundQuickExamples => 'APP背景快速示例';

  @override
  String get preview => '预览';

  @override
  String get apply => '应用';

  @override
  String get resetToDefault => '恢复默认';

  @override
  String get resetToDefaultDesc => '重置所有背景图片和透明度设置为默认？';

  @override
  String get reset => '重置';

  @override
  String get buttonBackgroundPrompt => '描述你想要的按键背景...';

  @override
  String get generateButtonBackground => '生成按键背景';

  @override
  String get selectButtons => '选择按键';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get buttonPatternPrompt => '描述你想要的按键图案...';

  @override
  String get generateButtonPattern => '生成按键图案';

  @override
  String get displayBackgroundPrompt => '描述你想要的显示区背景...';

  @override
  String get generateDisplayBackground => '生成显示区背景';

  @override
  String get displayBackgroundQuickExamples => '显示区背景快速示例';

  @override
  String get thinkingProcess => '查看思考过程';

  @override
  String get appliedToCalculator => '已应用到计算器';

  @override
  String get you => '你';

  @override
  String get aiAssistant => '🤖 AI助手';
}
