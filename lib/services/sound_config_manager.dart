import '../models/calculator_dsl.dart';

/// 音效配置管理器
class SoundConfigManager {
  /// 预定义的音效配置方案
  static const Map<String, List<SoundEffect>> presetSoundSchemes = {
    'cyberpunk': [
      SoundEffect(
        trigger: 'buttonPress',
        soundUrl: 'sounds/cyberpunk/cyber_click.wav',
        volume: 0.8,
      ),
      SoundEffect(
        trigger: 'calculation',
        soundUrl: 'sounds/cyberpunk/cyber_beep.wav',
        volume: 0.9,
      ),
      SoundEffect(
        trigger: 'error',
        soundUrl: 'sounds/error.wav',
        volume: 0.7,
      ),
      SoundEffect(
        trigger: 'clear',
        soundUrl: 'sounds/clear.wav',
        volume: 0.6,
      ),
    ],
    'nature': [
      SoundEffect(
        trigger: 'buttonPress',
        soundUrl: 'sounds/nature/wood_tap.wav',
        volume: 0.7,
      ),
      SoundEffect(
        trigger: 'calculation',
        soundUrl: 'sounds/nature/wind_chime.wav',
        volume: 0.8,
      ),
      SoundEffect(
        trigger: 'error',
        soundUrl: 'sounds/error.wav',
        volume: 0.6,
      ),
      SoundEffect(
        trigger: 'clear',
        soundUrl: 'sounds/clear.wav',
        volume: 0.5,
      ),
    ],
    'minimal': [
      SoundEffect(
        trigger: 'buttonPress',
        soundUrl: 'sounds/minimal/soft_tick.wav',
        volume: 0.6,
      ),
      SoundEffect(
        trigger: 'calculation',
        soundUrl: 'sounds/minimal/gentle_pop.wav',
        volume: 0.8,
      ),
      SoundEffect(
        trigger: 'error',
        soundUrl: 'sounds/error.wav',
        volume: 0.5,
      ),
      SoundEffect(
        trigger: 'clear',
        soundUrl: 'sounds/clear.wav',
        volume: 0.5,
      ),
    ],
    'classic': [
      SoundEffect(
        trigger: 'buttonPress',
        soundUrl: 'sounds/click_soft.wav',
        volume: 0.7,
      ),
      SoundEffect(
        trigger: 'calculation',
        soundUrl: 'sounds/calculate.wav',
        volume: 0.8,
      ),
      SoundEffect(
        trigger: 'error',
        soundUrl: 'sounds/error.wav',
        volume: 0.6,
      ),
      SoundEffect(
        trigger: 'clear',
        soundUrl: 'sounds/clear.wav',
        volume: 0.6,
      ),
    ],
  };

  /// 根据主题风格获取推荐的音效方案
  static List<SoundEffect>? getRecommendedSoundScheme(String themeName) {
    final lowerThemeName = themeName.toLowerCase();
    
    if (lowerThemeName.contains('cyber') || lowerThemeName.contains('科技') || 
        lowerThemeName.contains('赛博') || lowerThemeName.contains('未来')) {
      return presetSoundSchemes['cyberpunk'];
    }
    
    if (lowerThemeName.contains('nature') || lowerThemeName.contains('自然') || 
        lowerThemeName.contains('木') || lowerThemeName.contains('森林')) {
      return presetSoundSchemes['nature'];
    }
    
    if (lowerThemeName.contains('minimal') || lowerThemeName.contains('极简') || 
        lowerThemeName.contains('简约') || lowerThemeName.contains('现代')) {
      return presetSoundSchemes['minimal'];
    }
    
    return presetSoundSchemes['classic'];
  }

  /// 验证音效配置是否有效
  static bool validateSoundEffects(List<SoundEffect>? soundEffects) {
    if (soundEffects == null || soundEffects.isEmpty) {
      return true; // 允许没有音效配置
    }

    // 检查必需的触发器
    const requiredTriggers = ['buttonPress', 'calculation', 'error', 'clear'];
    final configuredTriggers = soundEffects.map((e) => e.trigger).toSet();
    
    // 至少应该有buttonPress触发器
    if (!configuredTriggers.contains('buttonPress')) {
      return false;
    }

    // 验证音量范围
    for (final effect in soundEffects) {
      if (effect.volume < 0.0 || effect.volume > 1.0) {
        return false;
      }
    }

    // 验证音效文件路径格式
    for (final effect in soundEffects) {
      if (effect.soundUrl.isEmpty || !effect.soundUrl.startsWith('sounds/')) {
        return false;
      }
    }

    return true;
  }

  /// 生成完整的音效配置
  static List<SoundEffect> generateCompleteSoundConfig(String themeStyle) {
    final recommended = getRecommendedSoundScheme(themeStyle);
    return recommended ?? presetSoundSchemes['classic']!;
  }

  /// 获取所有可用的音效方案名称
  static List<String> getAvailableSoundSchemes() {
    return presetSoundSchemes.keys.toList();
  }

  /// 获取音效方案的显示名称
  static String getSoundSchemeName(String scheme) {
    switch (scheme) {
      case 'cyberpunk':
        return '赛博朋克';
      case 'nature':
        return '自然主题';
      case 'minimal':
        return '极简风格';
      case 'classic':
        return '经典音效';
      default:
        return '未知方案';
    }
  }

  /// 获取音效方案的描述
  static String getSoundSchemeDescription(String scheme) {
    switch (scheme) {
      case 'cyberpunk':
        return '电子音效，未来感十足';
      case 'nature':
        return '木质敲击音，温暖自然';
      case 'minimal':
        return '轻柔音效，简约现代';
      case 'classic':
        return '标准按键音，经典实用';
      default:
        return '未知描述';
    }
  }
} 