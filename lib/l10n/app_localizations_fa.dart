// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get history => 'History';

  @override
  String get multiParamHelp => 'Multi-parameter Function Help';

  @override
  String get aiDesigner => 'AI Designer';

  @override
  String get imageWorkshop => 'Image Generation Workshop';

  @override
  String get appTitle => 'Queee Calculator (Persian)';

  @override
  String get aiDesignerScreenTitle => 'AI Designer';

  @override
  String get aiDesignerTextFieldHint =>
      'Describe your calculator design needs...';

  @override
  String get imageGeneration => 'Image Generation Workshop';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get welcomeMessage1 =>
      '👋 Hello! I\'m your exclusive calculator function designer';

  @override
  String get welcomeMessage2 =>
      '✨ I\'m a professional calculator function design master! I specialize in designing and extending calculator function logic for you!\n\n🚀 I\'m specifically responsible for:\n• Function extension (scientific calculation, financial tools, unit conversion)\n• Smart calculation (equation solving, data analysis, statistical calculation)\n• Practical tools (exchange rate conversion, discount calculation, loan calculation)\n• Button function definition (adding new calculation buttons and functions)\n\n⚠️ Note: I\'m only responsible for function design, not appearance styling (background images, colors, fonts, etc.). For appearance modifications, please use the \"Image Generation Workshop\"!';

  @override
  String get welcomeMessage3 =>
      '💡 **Quick Start Examples**:\n\n🏦 **Financial Calculation**:\n\"3.5% interest rate, 30-year loan, input loan amount, output monthly mortgage\"\n\"4% annual interest compound calculation, 10-year investment period\"\n\"USD to CNY exchange rate 7.2, currency conversion\"\n\n🔬 **Scientific Calculation**:\n\"Add power operations, logarithms, trigonometric functions\"\n\"Add statistical functions: mean, standard deviation, variance\"\n\"Add combination and permutation calculations\"\n\n💼 **Practical Tools**:\n\"10% off, 15% off, 30% off discount calculator\"\n\"BMI calculator, input height and weight to calculate health index\"\n\"Unit conversion: cm to inches, kg to pounds\"\n\n🎯 **Usage Tips**:\n• Describe specific needs, I\'ll automatically generate corresponding buttons\n• Specify parameter ranges, such as \"3.5% interest rate\" will preset parameters\n• Mention usage scenarios, I\'ll optimize the operation process';

  @override
  String get aiDesignerWorking => '🎯 AI Designer is working';

  @override
  String get aiDesignerWorkingDesc =>
      'Designing exclusive calculator functions for you...';

  @override
  String get designComplete =>
      '✅ Function design completed! Automatically applied to calculator.';

  @override
  String designCompleteWithName(Object name) {
    return '🎉 $name successfully applied!';
  }

  @override
  String get view => 'View';

  @override
  String get sorryDifficulty =>
      '😅 Sorry, I encountered some difficulties. Can you describe your idea in a different way?';

  @override
  String smallProblem(Object error) {
    return '😓 There was a small problem: $error\n\nDon\'t worry, let\'s try again!';
  }

  @override
  String get networkTest => 'Network Connection Test';

  @override
  String get testingConnection => 'Testing AI service connection...';

  @override
  String get connectionSuccess => 'Connection Successful';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get connectionSuccessDesc =>
      '✅ AI service connection is normal, you can use AI customization features normally.';

  @override
  String get connectionFailedDesc =>
      '❌ Unable to connect to AI service. Please check network connection or try again later.\n\nPossible reasons:\n• Network connection issues\n• Firewall blocking\n• Service temporarily unavailable';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get testFailed => 'Test Failed';

  @override
  String testFailedDesc(Object error) {
    return 'An error occurred during testing:\n$error';
  }

  @override
  String get quickRepliesTitle => '🎯 Practical Personalized Case Library';

  @override
  String get quickRepliesSubtitle =>
      'Simple and practical, but full of personalized calculation functions';

  @override
  String get progressiveDesign => '💡 Progressive Design Philosophy';

  @override
  String get progressiveDesignDesc =>
      'Each level adds new functions based on the previous level, Level 1→Level 20 gradually builds a complete professional calculator';

  @override
  String get startNewConversation => 'Start New Conversation';

  @override
  String get startNewConversationDesc =>
      'Start a completely new design conversation?\n\nThe calculator will be reset to default style.';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetSuccess =>
      '✅ Reset to default calculator functions, background images from image workshop preserved!';

  @override
  String get messageOptions => 'Message Options';

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get editMessage => 'Edit Message';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get messageCopied => 'Message copied to clipboard';

  @override
  String get editMessageTitle => 'Edit Message';

  @override
  String get editMessageHint => 'Enter new message content...';

  @override
  String get save => 'Save';

  @override
  String get messageUpdated => 'Message updated';

  @override
  String updateFailed(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get deleteMessageTitle => 'Delete Message';

  @override
  String get deleteMessageDesc =>
      'Are you sure you want to delete this message? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String deleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get designing => 'Designing...';

  @override
  String get quickIdeas => 'Quick Ideas';

  @override
  String get newConversation => 'New Conversation';

  @override
  String get describeCalculator => 'Describe your calculator...';

  @override
  String get testNetworkConnection => 'Test Network Connection';

  @override
  String get buttonBackground => 'Button';

  @override
  String get appBackground => 'APP Background';

  @override
  String get displayArea => 'Display Area';

  @override
  String get opacityControl => 'Opacity Control';

  @override
  String get buttonOpacity => 'Button Opacity';

  @override
  String get displayOpacity => 'Display Opacity';

  @override
  String get appBackgroundOpacity => 'APP Background Opacity';

  @override
  String get customGeneration => 'Custom Generation';

  @override
  String get appBackgroundPrompt => 'Describe the APP background you want...';

  @override
  String get generateAppBackground => 'Generate APP Background';

  @override
  String get quickSelection => 'Quick Selection';

  @override
  String get appBackgroundQuickExamples => 'APP Background Quick Examples';

  @override
  String get preview => 'Preview';

  @override
  String get apply => 'Apply';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get resetToDefaultDesc =>
      'Reset all background images and opacity settings to default?';

  @override
  String get reset => 'Reset';

  @override
  String get buttonBackgroundPrompt =>
      'Describe the button background you want...';

  @override
  String get generateButtonBackground => 'Generate Button Background';

  @override
  String get selectButtons => 'Select Buttons';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get buttonPatternPrompt => 'Describe the button pattern you want...';

  @override
  String get generateButtonPattern => 'Generate Button Pattern';

  @override
  String get displayBackgroundPrompt =>
      'Describe the display area background you want...';

  @override
  String get generateDisplayBackground => 'Generate Display Background';

  @override
  String get displayBackgroundQuickExamples =>
      'Display Background Quick Examples';

  @override
  String get thinkingProcess => 'View Thinking Process';

  @override
  String get appliedToCalculator => 'Applied to Calculator';

  @override
  String get you => 'You';

  @override
  String get aiAssistant => '🤖 AI Assistant';
}
