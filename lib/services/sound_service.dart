import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/calculator_dsl.dart';

/// 音效播放服务
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  double _masterVolume = 0.7;
  List<SoundEffect>? _currentSoundEffects;

  /// 初始化音效服务
  Future<void> initialize() async {
    try {
      // 设置音频播放器配置
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      debugPrint('🔊 音效服务初始化成功');
    } catch (e) {
      debugPrint('❌ 音效服务初始化失败: $e');
    }
  }

  /// 设置当前主题的音效配置
  void setSoundEffects(List<SoundEffect>? soundEffects) {
    _currentSoundEffects = soundEffects;
    debugPrint('🎵 加载音效配置: ${soundEffects?.length ?? 0} 个音效');
  }

  /// 播放指定触发器的音效
  Future<void> playSound(String trigger) async {
    if (!_soundEnabled || _currentSoundEffects == null) return;

    try {
      // 查找匹配的音效
      final soundEffect = _currentSoundEffects!
          .where((effect) => effect.trigger == trigger)
          .firstOrNull;

      if (soundEffect != null) {
        // 计算最终音量
        final finalVolume = _masterVolume * soundEffect.volume;
        
        // 音效文件路径映射（临时降级方案）
        String actualSoundUrl = _mapSoundUrl(soundEffect.soundUrl);
        
        // 播放音效
        await _audioPlayer.setVolume(finalVolume);
        await _audioPlayer.play(AssetSource(actualSoundUrl));
        
        debugPrint('🎵 播放音效: $trigger -> $actualSoundUrl');
      } else {
        // 如果没有找到特定音效，播放默认音效
        await _playDefaultSound(trigger);
      }
    } catch (e) {
      debugPrint('❌ 音效播放失败: $trigger - $e');
      // 降级到默认音效
      await _playDefaultSound(trigger);
    }
  }

  /// 音效文件路径映射（降级方案）
  String _mapSoundUrl(String originalUrl) {
    // 对于不存在的音效文件，映射到实际存在的文件
    if (originalUrl.contains('minimal/')) {
      return 'sounds/click_soft.wav'; // 使用轻柔点击音效
    } else if (originalUrl.contains('cyberpunk/')) {
      return 'sounds/click_sharp.wav'; // 使用尖锐点击音效
    } else if (originalUrl.contains('nature/')) {
      return 'sounds/click_soft.wav'; // 使用轻柔点击音效
    }
    return originalUrl; // 保持原有路径
  }

  /// 播放默认音效
  Future<void> _playDefaultSound(String trigger) async {
    try {
      String defaultSoundUrl;
      
      switch (trigger) {
        case 'buttonPress':
          defaultSoundUrl = 'sounds/click_soft.wav';
          break;
        case 'calculation':
          defaultSoundUrl = 'sounds/calculate.wav';
          break;
        case 'error':
          defaultSoundUrl = 'sounds/error.wav';
          break;
        case 'clear':
          defaultSoundUrl = 'sounds/clear.wav';
          break;
        default:
          defaultSoundUrl = 'sounds/click_soft.wav';
      }

      await _audioPlayer.setVolume(_masterVolume * 0.5);
      await _audioPlayer.play(AssetSource(defaultSoundUrl));
      
      debugPrint('🎵 播放默认音效: $trigger -> $defaultSoundUrl');
    } catch (e) {
      debugPrint('❌ 默认音效播放失败: $e');
    }
  }

  /// 设置音效开关
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    debugPrint('🔊 音效${enabled ? '开启' : '关闭'}');
  }

  /// 设置主音量
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    debugPrint('🔊 主音量设置为: ${(_masterVolume * 100).toInt()}%');
  }

  /// 获取音效开关状态
  bool get soundEnabled => _soundEnabled;

  /// 获取主音量
  double get masterVolume => _masterVolume;

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// 音效触发器常量
class SoundTriggers {
  static const String buttonPress = 'buttonPress';
  static const String buttonRelease = 'buttonRelease';
  static const String calculation = 'calculation';
  static const String error = 'error';
  static const String clear = 'clear';
  static const String themeChange = 'themeChange';
  static const String numberInput = 'numberInput';
  static const String operatorInput = 'operatorInput';
  static const String functionInput = 'functionInput';
} 