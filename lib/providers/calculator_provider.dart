import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';  // 临时注释
import '../core/calculator_engine.dart';
import '../models/calculator_dsl.dart';
import '../services/config_service.dart';

class CalculatorProvider extends ChangeNotifier {
  final CalculatorEngine _engine = CalculatorEngine();
  CalculatorConfig _config = CalculatorConfig.createDefault();
  // final AudioPlayer _audioPlayer = AudioPlayer();  // 临时注释

  CalculatorState get state => _engine.state;
  CalculatorConfig get config => _config;

  /// 执行计算器操作
  void execute(CalculatorAction action) {
    _engine.execute(action);
    _playSound('buttonPress');
    notifyListeners();
  }

  /// 通过按钮ID执行操作
  void executeButtonAction(String buttonId) {
    final button = _config.layout.buttons.firstWhere(
      (b) => b.id == buttonId,
      orElse: () => throw Exception('Button not found: $buttonId'),
    );
    
    // 检查是否是进制切换按钮
    if (_isBaseChangeButton(button.label)) {
      _handleBaseChange(button.label);
      return;
    }

    // 检查是否是十六进制字符输入（A-F）
    if (_isHexInput(button.label)) {
      execute(CalculatorAction(type: CalculatorActionType.input, value: button.label));
      return;
    }
    
    execute(button.action);
  }

  /// 检查是否是进制切换按钮
  bool _isBaseChangeButton(String label) {
    return ['Hex', 'Dec', 'Oct', 'Bin', 'HEX', 'DEC', 'OCT', 'BIN'].contains(label);
  }

  /// 检查是否是十六进制字符输入
  bool _isHexInput(String label) {
    return ['A', 'B', 'C', 'D', 'E', 'F'].contains(label.toUpperCase());
  }

  /// 处理进制切换
  void _handleBaseChange(String baseLabel) {
    String newBase;
    switch (baseLabel.toUpperCase()) {
      case 'HEX':
        newBase = 'hex';
        break;
      case 'DEC':
        newBase = 'decimal';
        break;
      case 'OCT':
        newBase = 'octal';
        break;
      case 'BIN':
        newBase = 'binary';
        break;
      default:
        return;
    }
    
    _engine.handleBaseChange(newBase);
    _playSound('buttonPress');
    notifyListeners();
  }

  /// 更新计算器配置
  void updateConfig(CalculatorConfig newConfig) {
    _config = newConfig;
    
    // 如果是程序员计算器，自动设置为十六进制模式
    if (_config.name.toLowerCase().contains('程序员') || 
        _config.name.toLowerCase().contains('programmer') ||
        _hasHexButtons()) {
      _engine.handleBaseChange('hex');
    }
    
    ConfigService.saveCurrentConfig(newConfig);
    notifyListeners();
  }

  /// 检查是否包含十六进制按钮
  bool _hasHexButtons() {
    return _config.layout.buttons.any((button) => 
      ['A', 'B', 'C', 'D', 'E', 'F'].contains(button.label.toUpperCase())
    );
  }

  /// 初始化配置
  Future<void> initializeConfig() async {
    _config = await ConfigService.loadCurrentConfig();
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

  /// 播放音效 (临时禁用)
  void _playSound(String trigger) {
    // 临时注释音效功能以解决Android编译问题
    // final soundEffect = _config.theme.soundEffects?.cast<SoundEffect?>().firstWhere(
    //   (sound) => sound?.trigger == trigger,
    //   orElse: () => null,
    // );
    // 
    // if (soundEffect != null) {
    //   try {
    //     _audioPlayer.play(UrlSource(soundEffect.soundUrl));
    //   } catch (e) {
    //     // 音效播放失败时不影响计算器功能
    //     if (kDebugMode) {
    //       print('Sound playback failed: $e');
    //     }
    //   }
    // }
  }

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
    // _audioPlayer.dispose();  // 临时注释
    super.dispose();
  }
} 