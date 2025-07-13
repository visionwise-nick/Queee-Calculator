import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculator_dsl.dart';

class ConfigService {
  static const String _currentConfigKey = 'current_calculator_config';
  static const String _customConfigsKey = 'custom_calculator_configs';
  // 🔧 新增：历史记录存储键
  static const String _appBackgroundHistoryKey = 'app_background_history';
  static const String _buttonPatternHistoryKey = 'button_pattern_history';
  static const String _displayBackgroundHistoryKey = 'display_background_history'; // 🔧 新增：显示区背景历史记录
  
  // 🔧 新增：历史记录项模型
  static const int _maxHistoryItems = 20; // 最多保存20条历史记录

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_currentConfigKey);
      
      if (configJson != null) {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        return CalculatorConfig.fromJson(configMap);
      }
    } catch (e) {
      print('Failed to load current config: $e');
    }
    
    // 如果没有保存的配置，使用默认配置而不是赛博朋克主题
    print('🔧 使用默认配置（修复后）');
    return CalculatorConfig.createDefault();
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

  // 🔧 新增：APP背景历史记录管理
  
  /// 保存APP背景历史记录
  static Future<void> saveAppBackgroundHistory(String prompt, String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadAppBackgroundHistory();
      
      // 创建新的历史记录项
      final newItem = {
        'prompt': prompt,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      // 检查是否已存在相同的提示词，如果存在则更新
      final existingIndex = historyList.indexWhere((item) => item['prompt'] == prompt);
      if (existingIndex >= 0) {
        historyList[existingIndex] = newItem;
      } else {
        historyList.insert(0, newItem); // 插入到开头
      }
      
      // 限制历史记录数量
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_appBackgroundHistoryKey, historyJson);
      
      print('📝 APP背景历史记录已保存：$prompt');
    } catch (e) {
      print('❌ 保存APP背景历史记录失败: $e');
    }
  }
  
  /// 加载APP背景历史记录
  static Future<List<Map<String, dynamic>>> loadAppBackgroundHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_appBackgroundHistoryKey);
      
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        return historyList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ 加载APP背景历史记录失败: $e');
    }
    
    return [];
  }
  
  /// 删除APP背景历史记录项
  static Future<void> deleteAppBackgroundHistoryItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadAppBackgroundHistory();
      
      historyList.removeWhere((item) => item['id'] == itemId);
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_appBackgroundHistoryKey, historyJson);
      
      print('🗑️ APP背景历史记录项已删除：$itemId');
    } catch (e) {
      print('❌ 删除APP背景历史记录项失败: $e');
    }
  }
  
  /// 清空APP背景历史记录
  static Future<void> clearAppBackgroundHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appBackgroundHistoryKey);
      print('🧹 APP背景历史记录已清空');
    } catch (e) {
      print('❌ 清空APP背景历史记录失败: $e');
    }
  }

  // 🔧 新增：按键背景图案历史记录管理
  
  /// 保存按键背景图案历史记录
  static Future<void> saveButtonPatternHistory(String prompt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadButtonPatternHistory();
      
      // 创建新的历史记录项
      final newItem = {
        'prompt': prompt,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      // 检查是否已存在相同的提示词，如果存在则更新时间戳
      final existingIndex = historyList.indexWhere((item) => item['prompt'] == prompt);
      if (existingIndex >= 0) {
        historyList[existingIndex] = newItem;
      } else {
        historyList.insert(0, newItem); // 插入到开头
      }
      
      // 限制历史记录数量
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_buttonPatternHistoryKey, historyJson);
      
      print('📝 按键背景图案历史记录已保存：$prompt');
    } catch (e) {
      print('❌ 保存按键背景图案历史记录失败: $e');
    }
  }
  
  /// 加载按键背景图案历史记录
  static Future<List<Map<String, dynamic>>> loadButtonPatternHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_buttonPatternHistoryKey);
      
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        return historyList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ 加载按键背景图案历史记录失败: $e');
    }
    
    return [];
  }
  
  /// 删除按键背景图案历史记录项
  static Future<void> deleteButtonPatternHistoryItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadButtonPatternHistory();
      
      historyList.removeWhere((item) => item['id'] == itemId);
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_buttonPatternHistoryKey, historyJson);
      
      print('🗑️ 按键背景图案历史记录项已删除：$itemId');
    } catch (e) {
      print('❌ 删除按键背景图案历史记录项失败: $e');
    }
  }
  
  /// 清空按键背景图案历史记录
  static Future<void> clearButtonPatternHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_buttonPatternHistoryKey);
      print('🧹 按键背景图案历史记录已清空');
    } catch (e) {
      print('❌ 清空按键背景图案历史记录失败: $e');
    }
  }

  // 🔧 新增：显示区背景历史记录管理
  
  /// 保存显示区背景历史记录
  static Future<void> saveDisplayBackgroundHistory(String prompt, String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadDisplayBackgroundHistory();
      
      // 创建新的历史记录项
      final newItem = {
        'prompt': prompt,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      // 检查是否已存在相同的提示词，如果存在则更新
      final existingIndex = historyList.indexWhere((item) => item['prompt'] == prompt);
      if (existingIndex >= 0) {
        historyList[existingIndex] = newItem;
      } else {
        historyList.insert(0, newItem); // 插入到开头
      }
      
      // 限制历史记录数量
      if (historyList.length > _maxHistoryItems) {
        historyList.removeRange(_maxHistoryItems, historyList.length);
      }
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_displayBackgroundHistoryKey, historyJson);
      
      print('📝 显示区背景历史记录已保存：$prompt');
    } catch (e) {
      print('❌ 保存显示区背景历史记录失败: $e');
    }
  }
  
  /// 加载显示区背景历史记录
  static Future<List<Map<String, dynamic>>> loadDisplayBackgroundHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_displayBackgroundHistoryKey);
      
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        return historyList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ 加载显示区背景历史记录失败: $e');
    }
    
    return [];
  }
  
  /// 删除显示区背景历史记录项
  static Future<void> deleteDisplayBackgroundHistoryItem(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = await loadDisplayBackgroundHistory();
      
      historyList.removeWhere((item) => item['id'] == itemId);
      
      final historyJson = json.encode(historyList);
      await prefs.setString(_displayBackgroundHistoryKey, historyJson);
      
      print('🗑️ 显示区背景历史记录项已删除：$itemId');
    } catch (e) {
      print('❌ 删除显示区背景历史记录项失败: $e');
    }
  }
  
  /// 清空显示区背景历史记录
  static Future<void> clearDisplayBackgroundHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_displayBackgroundHistoryKey);
      print('🧹 显示区背景历史记录已清空');
    } catch (e) {
      print('❌ 清空显示区背景历史记录失败: $e');
    }
  }
} 