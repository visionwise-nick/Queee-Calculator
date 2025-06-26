import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculator_dsl.dart';

class ConfigService {
  static const String _currentConfigKey = 'current_calculator_config';
  static const String _customConfigsKey = 'custom_calculator_configs';

  /// 加载预设主题配置
  static Future<CalculatorConfig> loadPresetConfig(String configName) async {
    try {
      final configJson = await rootBundle.loadString('assets/themes/$configName.json');
      final configMap = json.decode(configJson) as Map<String, dynamic>;
      return CalculatorConfig.fromJson(configMap);
    } catch (e) {
      print('Failed to load preset config $configName: $e');
      return CalculatorConfig.createDefault();
    }
  }

  /// 获取所有可用的预设主题
  static Future<List<String>> getAvailablePresets() async {
    return [
      'cyberpunk_theme',
      'tip_calculator_theme',
      'enhanced_test_theme',
    ];
  }

  /// 保存当前配置
  static Future<void> saveCurrentConfig(CalculatorConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toJson());
      await prefs.setString(_currentConfigKey, configJson);
    } catch (e) {
      print('Failed to save current config: $e');
    }
  }

  /// 加载当前配置
  static Future<CalculatorConfig> loadCurrentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final configJson = prefs.getString(_currentConfigKey);
      
      if (configJson != null) {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        return CalculatorConfig.fromJson(configMap);
      }
    } catch (e) {
      print('加载已保存的配置失败: $e. 将删除损坏的配置。');
      // 如果解析失败，删除损坏的配置，防止应用卡在错误状态
      await prefs.remove(_currentConfigKey);
    }
    
    // 如果没有找到配置，或加载失败，则加载一个安全的默认主题
    return loadPresetConfig('cyberpunk_theme');
  }

  /// 保存自定义配置
  static Future<void> saveCustomConfig(CalculatorConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customConfigs = await loadCustomConfigs();
      
      // 更新或添加配置
      final index = customConfigs.indexWhere((c) => c.id == config.id);
      if (index >= 0) {
        customConfigs[index] = config;
      } else {
        customConfigs.add(config);
      }
      
      final configsJson = json.encode(customConfigs.map((c) => c.toJson()).toList());
      await prefs.setString(_customConfigsKey, configsJson);
    } catch (e) {
      print('Failed to save custom config: $e');
    }
  }

  /// 加载自定义配置列表
  static Future<List<CalculatorConfig>> loadCustomConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configsJson = prefs.getString(_customConfigsKey);
      
      if (configsJson != null) {
        final configsList = json.decode(configsJson) as List;
        return configsList
            .map((configMap) => CalculatorConfig.fromJson(configMap as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Failed to load custom configs: $e');
    }
    
    return [];
  }

  /// 删除自定义配置
  static Future<void> deleteCustomConfig(String configId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customConfigs = await loadCustomConfigs();
      
      customConfigs.removeWhere((c) => c.id == configId);
      
      final configsJson = json.encode(customConfigs.map((c) => c.toJson()).toList());
      await prefs.setString(_customConfigsKey, configsJson);
    } catch (e) {
      print('Failed to delete custom config: $e');
    }
  }

  /// 导出配置为JSON字符串
  static String exportConfig(CalculatorConfig config) {
    return json.encode(config.toJson());
  }

  /// 从JSON字符串导入配置
  static CalculatorConfig? importConfig(String configJson) {
    try {
      final configMap = json.decode(configJson) as Map<String, dynamic>;
      return CalculatorConfig.fromJson(configMap);
    } catch (e) {
      print('Failed to import config: $e');
      return null;
    }
  }
} 