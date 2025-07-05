import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import '../services/config_service.dart';
import '../widgets/calculation_history_dialog.dart';
import '../services/ai_service.dart';

class CalculatorProvider extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  CalculatorConfig _config = CalculatorConfig.createDefault();
  Map<String, String> _buttonLabels = {};
  Map<String, bool> _loadingButtons = {};

  CalculatorConfig get config => _config;
  CalculatorState get state => _engine.state;
  List<CalculationStep> get calculationHistory => _engine.calculationHistory;

  // 初始化
  Future<void> initialize() async {
    await _loadConfig();
  }

     // 加载配置
   Future<void> _loadConfig() async {
     try {
       final loadedConfig = await ConfigService.loadCurrentConfig();
       _config = loadedConfig;
       notifyListeners();
     } catch (e) {
       print('配置加载失败: $e');
     }
   }

   // 应用新配置
   Future<void> applyConfig(CalculatorConfig newConfig) async {
     _config = newConfig;
     await ConfigService.saveCurrentConfig(_config);
     notifyListeners();
   }

  // 执行计算器操作
  Future<void> executeAction(CalculatorAction action, {String? buttonId}) async {
    if (action.type == 'network_request') {
      await _handleNetworkRequest(action, buttonId!);
    } else {
      _engine.execute(action);
    }
    notifyListeners();
  }

  // 重置计算器
  void reset() {
    _engine.reset();
    notifyListeners();
  }

  // 完全重置计算器状态（包括清除所有数据）
  void resetCalculatorState() {
    _engine.reset();
    _engine.clearHistory(); // 清除计算历史
    notifyListeners();
  }

  // 获取按钮文字颜色
  Color getButtonTextColor(CalculatorButton button) {
    switch (button.type) {
      case 'primary':
        return _parseColor(_config.theme.primaryButtonTextColor);
      case 'secondary':
        return _parseColor(_config.theme.secondaryButtonTextColor);
      case 'operator':
        return _parseColor(_config.theme.operatorButtonTextColor);
      case 'special':
        return _parseColor(_config.theme.operatorButtonTextColor);
      default:
        return _parseColor(_config.theme.primaryButtonTextColor);
    }
  }

  // 获取按钮背景颜色
  Color getButtonBackgroundColor(CalculatorButton button) {
    if (button.customColor != null) {
      return _parseColor(button.customColor!);
    }

    switch (button.type) {
      case 'primary':
        return _parseColor(_config.theme.primaryButtonColor);
      case 'secondary':
        return _parseColor(_config.theme.secondaryButtonColor);
      case 'operator':
        return _parseColor(_config.theme.operatorButtonColor);
      case 'special':
        return _parseColor(_config.theme.operatorButtonColor);
      default:
        return _parseColor(_config.theme.primaryButtonColor);
    }
  }

  // 获取显示屏背景颜色
  Color getDisplayBackgroundColor() {
    return _parseColor(_config.theme.displayBackgroundColor);
  }

  // 获取显示屏文字颜色
  Color getDisplayTextColor() {
    return _parseColor(_config.theme.displayTextColor);
  }

  // 获取主背景颜色
  Color getBackgroundColor() {
    return _parseColor(_config.theme.backgroundColor);
  }

  // 解析颜色字符串
  Color _parseColor(String colorString) {
    try {
      String hexString = colorString;
      if (hexString.startsWith('#')) {
        hexString = hexString.substring(1);
      }
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return Colors.grey; // 默认颜色
    }
  }

  // 🆕 新增：获取按钮是否在加载中的方法
  bool isButtonLoading(String buttonId) => _loadingButtons[buttonId] ?? false;

  // 🆕 新增：处理网络请求的方法
  Future<void> _handleNetworkRequest(CalculatorAction action, String buttonId) async {
    if (action.url == null || action.parameters == null) return;

    // 1. 设置加载状态
    _loadingButtons[buttonId] = true;
    if (action.loadingLabel != null) {
      _buttonLabels[buttonId] = action.loadingLabel!;
    }
    notifyListeners();

    try {
      // 2. 调用API
      final rate = await AIService.getExchangeRate(
        fromCurrency: action.parameters!['from_currency'],
        toCurrency: action.parameters!['to_currency'],
      );

      if (rate != null) {
        // 3. 执行计算
        final expression = action.value?.replaceAll('rate', rate.toString()) ?? 'x * $rate';
        final newAction = CalculatorAction(type: 'expression', expression: expression);
        _engine.execute(newAction);
      }
    } catch (e) {
      print("网络请求失败: $e");
      // 可以在这里处理错误，比如在界面上显示错误信息
    } finally {
      // 4. 恢复按钮状态
      _loadingButtons[buttonId] = false;
      if (action.successLabel != null) {
        _buttonLabels[buttonId] = action.successLabel!;
      } else {
         final originalButton = _config.layout.buttons.firstWhere((btn) => btn.id == buttonId);
        _buttonLabels[buttonId] = originalButton.label;
      }
      notifyListeners();
    }
  }

  // 🆕 新增：获取按钮标签的方法
  String getButtonLabel(CalculatorButton button) {
    return _buttonLabels[button.id] ?? button.label;
  }

  ButtonStyle getThemeForButton(CalculatorButton button) {
    // 这是一个示例实现，您可以根据需要进行扩展
    // 例如，从 CalculatorTheme 中获取颜色
    Color backgroundColor;
    Color foregroundColor;

    switch (button.type) {
      case 'operator':
        backgroundColor = Colors.orange;
        foregroundColor = Colors.white;
        break;
      case 'secondary':
        backgroundColor = Colors.grey[700]!;
        foregroundColor = Colors.white;
        break;
      default: // primary
        backgroundColor = Colors.grey[850]!;
        foregroundColor = Colors.white;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(20),
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
} 