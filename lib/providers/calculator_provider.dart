import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import '../services/config_service.dart';
import '../services/sound_service.dart';

class CalculatorProvider extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  final SoundService _soundService = SoundService();
  CalculatorConfig _config = CalculatorConfig.createDefault();

  CalculatorState get state => _engine.state;
  CalculatorConfig get config => _config;

  /// 执行计算器操作
  void execute(CalculatorAction action) {
    // 根据操作类型播放不同音效
    String soundTrigger = 'buttonPress';
    if (action.type == CalculatorActionType.equals) {
      soundTrigger = 'calculation';
    } else if (action.type == CalculatorActionType.clearAll) {
      soundTrigger = 'clear';
    }
    
    _engine.execute(action);
    _soundService.playSound(soundTrigger);
    notifyListeners();
  }

  /// 通过按钮ID执行操作
  void executeButtonAction(String buttonId) {
    final button = _config.layout.buttons.firstWhere(
      (b) => b.id == buttonId,
      orElse: () => throw Exception('Button not found: $buttonId'),
    );
    
    execute(button.action);
  }

  /// 更新计算器配置
  void updateConfig(CalculatorConfig newConfig) {
    _config = newConfig;
    // 更新音效配置
    _soundService.setSoundEffects(_config.theme.soundEffects);
    ConfigService.saveCurrentConfig(newConfig);
    notifyListeners();
  }

  /// 初始化配置
  Future<void> initializeConfig() async {
    await _soundService.initialize();
    _config = await ConfigService.loadCurrentConfig();
    _soundService.setSoundEffects(_config.theme.soundEffects);
    notifyListeners();
  }

  /// 加载预设主题
  Future<void> loadPresetTheme(String presetName) async {
    final config = await ConfigService.loadPresetConfig(presetName);
    updateConfig(config);
  }

  /// 重置计算器
  void reset() {
    _engine.reset();
    notifyListeners();
  }

  /// 获取音效服务实例
  SoundService get soundService => _soundService;

  /// 获取按钮颜色
  Color getButtonColor(CalculatorButton button) {
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
        return _parseColor(_config.theme.secondaryButtonColor);
    }
  }

  /// 获取按钮文字颜色
  Color getButtonTextColor(CalculatorButton button) {
    if (button.customTextColor != null) {
      return _parseColor(button.customTextColor!);
    }
    
    switch (button.type) {
      case ButtonType.primary:
        return _parseColor(_config.theme.primaryButtonTextColor);
      case ButtonType.secondary:
        return _parseColor(_config.theme.secondaryButtonTextColor);
      case ButtonType.operator:
        return _parseColor(_config.theme.operatorButtonTextColor);
      case ButtonType.special:
        return _parseColor(_config.theme.secondaryButtonTextColor);
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) | 0xFF000000);
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
  }
} 