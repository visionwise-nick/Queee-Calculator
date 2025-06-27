import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import '../services/config_service.dart';

class CalculatorProvider extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  CalculatorConfig _config = CalculatorConfig.createDefault();

  CalculatorConfig get config => _config;
  CalculatorState get state => _engine.state;

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
  void executeAction(CalculatorAction action) {
    _engine.execute(action);
    notifyListeners();
  }

  // 重置计算器
  void reset() {
    _engine.reset();
    notifyListeners();
  }

  // 获取按钮文字颜色
  Color getButtonTextColor(CalculatorButton button) {
    switch (button.type) {
      case ButtonType.primary:
        return _parseColor(_config.theme.primaryButtonTextColor);
      case ButtonType.secondary:
        return _parseColor(_config.theme.secondaryButtonTextColor);
      case ButtonType.operator:
        return _parseColor(_config.theme.operatorButtonTextColor);
      case ButtonType.special:
        return _parseColor(_config.theme.operatorButtonTextColor);
    }
  }

  // 获取按钮背景颜色
  Color getButtonBackgroundColor(CalculatorButton button) {
    if (button.customColor != null) {
      return _parseColor(button.customColor!);
    }

    switch (button.type) {
      case ButtonType.primary:
        return _parseColor(_config.theme.primaryButtonColor);
      case ButtonType.secondary:
        return _parseColor(_config.theme.secondaryButtonColor);
      case ButtonType.operator:
        return _parseColor(_config.theme.operatorButtonColor);
      case ButtonType.special:
        return _parseColor(_config.theme.operatorButtonColor);
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
} 