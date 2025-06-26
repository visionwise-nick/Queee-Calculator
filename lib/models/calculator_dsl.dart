import '../core/calculator_engine.dart';

/// 计算器主题配置
class CalculatorTheme {
  final String name;
  final String backgroundColor;
  final String displayBackgroundColor;
  final String displayTextColor;
  final String primaryButtonColor;
  final String primaryButtonTextColor;
  final String secondaryButtonColor;
  final String secondaryButtonTextColor;
  final String operatorButtonColor;
  final String operatorButtonTextColor;
  final String? backgroundImage;
  final String? fontFamily;
  final double fontSize;
  final double buttonBorderRadius;
  final bool hasGlowEffect;
  final String? shadowColor;
  final List<SoundEffect>? soundEffects;

  const CalculatorTheme({
    required this.name,
    required this.backgroundColor,
    required this.displayBackgroundColor,
    required this.displayTextColor,
    required this.primaryButtonColor,
    required this.primaryButtonTextColor,
    required this.secondaryButtonColor,
    required this.secondaryButtonTextColor,
    required this.operatorButtonColor,
    required this.operatorButtonTextColor,
    this.backgroundImage,
    this.fontFamily,
    this.fontSize = 24.0,
    this.buttonBorderRadius = 8.0,
    this.hasGlowEffect = false,
    this.shadowColor,
    this.soundEffects,
  });

  factory CalculatorTheme.fromJson(Map<String, dynamic> json) {
    return CalculatorTheme(
      name: json['name']?.toString() ?? 'AI 主题',
      backgroundColor: json['backgroundColor']?.toString() ?? '#000000',
      displayBackgroundColor: json['displayBackgroundColor']?.toString() ?? '#1a1a1a',
      displayTextColor: json['displayTextColor']?.toString() ?? '#ffffff',
      primaryButtonColor: json['primaryButtonColor']?.toString() ?? '#333333',
      primaryButtonTextColor: json['primaryButtonTextColor']?.toString() ?? '#ffffff',
      secondaryButtonColor: json['secondaryButtonColor']?.toString() ?? '#666666',
      secondaryButtonTextColor: json['secondaryButtonTextColor']?.toString() ?? '#ffffff',
      operatorButtonColor: json['operatorButtonColor']?.toString() ?? '#ff9500',
      operatorButtonTextColor: json['operatorButtonTextColor']?.toString() ?? '#ffffff',
      backgroundImage: json['backgroundImage']?.toString(),
      fontFamily: json['fontFamily']?.toString(),
      fontSize: _parseDouble(json['fontSize']) ?? 24.0,
      buttonBorderRadius: _parseDouble(json['buttonBorderRadius']) ?? 8.0,
      hasGlowEffect: json['hasGlowEffect'] ?? false,
      shadowColor: json['shadowColor']?.toString(),
      soundEffects: (json['soundEffects'] as List<dynamic>?)
          ?.map((e) => SoundEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 安全解析数值，支持字符串转换
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// 安全解析整数，支持字符串转换
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'backgroundColor': backgroundColor,
      'displayBackgroundColor': displayBackgroundColor,
      'displayTextColor': displayTextColor,
      'primaryButtonColor': primaryButtonColor,
      'primaryButtonTextColor': primaryButtonTextColor,
      'secondaryButtonColor': secondaryButtonColor,
      'secondaryButtonTextColor': secondaryButtonTextColor,
      'operatorButtonColor': operatorButtonColor,
      'operatorButtonTextColor': operatorButtonTextColor,
      if (backgroundImage != null) 'backgroundImage': backgroundImage,
      if (fontFamily != null) 'fontFamily': fontFamily,
      'fontSize': fontSize,
      'buttonBorderRadius': buttonBorderRadius,
      'hasGlowEffect': hasGlowEffect,
      if (shadowColor != null) 'shadowColor': shadowColor,
      if (soundEffects != null)
        'soundEffects': soundEffects!.map((e) => e.toJson()).toList(),
    };
  }
}

/// 音效配置
class SoundEffect {
  final String trigger; // 'buttonPress', 'error', 'result', etc.
  final String soundUrl;
  final double volume;

  const SoundEffect({
    required this.trigger,
    required this.soundUrl,
    this.volume = 1.0,
  });

  factory SoundEffect.fromJson(Map<String, dynamic> json) {
    return SoundEffect(
      trigger: json['trigger']?.toString() ?? 'buttonPress',
      soundUrl: json['soundUrl']?.toString() ?? '',
      volume: CalculatorTheme._parseDouble(json['volume']) ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      'soundUrl': soundUrl,
      'volume': volume,
    };
  }
}

/// 计算器按钮配置
class CalculatorButton {
  final String id;
  final String label;
  final CalculatorAction action;
  final GridPosition gridPosition;
  final ButtonType type;
  final String? customColor;
  final String? customTextColor;
  final String? icon;
  final bool isWide; // 是否占两格宽度
  final bool isHigh; // 是否占两格高度

  const CalculatorButton({
    required this.id,
    required this.label,
    required this.action,
    required this.gridPosition,
    required this.type,
    this.customColor,
    this.customTextColor,
    this.icon,
    this.isWide = false,
    this.isHigh = false,
  });

  factory CalculatorButton.fromJson(Map<String, dynamic> json) {
    String label = json['label']?.toString() ?? '';
    
    return CalculatorButton(
      id: json['id']?.toString() ?? 'btn-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      action: _parseAction(json['action'] as Map<String, dynamic>?, label),
      gridPosition: GridPosition.fromJson(json['gridPosition'] as Map<String, dynamic>? ?? {}),
      type: ButtonType.values.firstWhere(
        (e) => e.toString() == 'ButtonType.${json['type']}',
        orElse: () => ButtonType.primary,
      ),
      customColor: json['customColor']?.toString(),
      customTextColor: json['customTextColor']?.toString(),
      icon: json['icon']?.toString(),
      isWide: json['isWide'] ?? false,
      isHigh: json['isHigh'] ?? false,
    );
  }

  /// 智能解析action，如果没有提供则根据label自动生成
  static CalculatorAction _parseAction(Map<String, dynamic>? actionJson, String label) {
    if (actionJson != null && actionJson.isNotEmpty) {
      try {
        return CalculatorAction.fromJson(actionJson);
      } catch (e) {
        print('Failed to parse action from JSON: $e');
      }
    }
    
    // 根据label自动生成action
    return _inferActionFromLabel(label);
  }

  /// 根据按钮标签推断操作类型
  static CalculatorAction _inferActionFromLabel(String label) {
    // 数字输入
    if (RegExp(r'^[0-9A-F]$').hasMatch(label)) {
      return CalculatorAction(type: CalculatorActionType.input, value: label);
    }
    
    // 运算符
    switch (label) {
      case '+':
      case '-':
      case '*':
      case '/':
        return CalculatorAction(type: CalculatorActionType.operator, value: label);
      case '=':
        return CalculatorAction(type: CalculatorActionType.equals);
      case '.':
        return CalculatorAction(type: CalculatorActionType.decimal);
      case 'C':
      case 'Clear':
        return CalculatorAction(type: CalculatorActionType.clear);
      case 'AC':
      case 'Clear All':
        return CalculatorAction(type: CalculatorActionType.clearAll);
      case '⌫':
      case 'Backspace':
        return CalculatorAction(type: CalculatorActionType.backspace);
      case '%':
        return CalculatorAction(type: CalculatorActionType.percentage);
      case '±':
      case '+/-':
        return CalculatorAction(type: CalculatorActionType.negate);
      
      // 内存操作
      case 'MS':
      case 'MR':
      case 'MC':
      case 'M+':
      case 'M-':
        return CalculatorAction(type: CalculatorActionType.memory, value: label);
      
      // 默认情况：当作特殊按钮处理
      default:
        return CalculatorAction(type: CalculatorActionType.input, value: '0');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action': action.toJson(),
      'gridPosition': gridPosition.toJson(),
      'type': type.toString().split('.').last,
      if (customColor != null) 'customColor': customColor,
      if (customTextColor != null) 'customTextColor': customTextColor,
      if (icon != null) 'icon': icon,
      'isWide': isWide,
      'isHigh': isHigh,
    };
  }
}

/// 按钮类型
enum ButtonType {
  primary,    // 数字按钮
  secondary,  // 功能按钮 (C, ±, %)
  operator,   // 运算符按钮 (+, -, *, /, =)
  special,    // 特殊按钮
}

/// 网格位置
class GridPosition {
  final int row;
  final int column;
  final int? rowSpan;
  final int? columnSpan;

  const GridPosition({
    required this.row,
    required this.column,
    this.rowSpan,
    this.columnSpan,
  });

  factory GridPosition.fromJson(Map<String, dynamic> json) {
    return GridPosition(
      row: CalculatorTheme._parseInt(json['row']) ?? 0,
      column: CalculatorTheme._parseInt(json['column']) ?? 0,
      rowSpan: CalculatorTheme._parseInt(json['rowSpan']),
      columnSpan: CalculatorTheme._parseInt(json['columnSpan']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'column': column,
      if (rowSpan != null) 'rowSpan': rowSpan,
      if (columnSpan != null) 'columnSpan': columnSpan,
    };
  }
}

/// 计算器布局配置
class CalculatorLayout {
  final String name;
  final int rows;
  final int columns;
  final List<CalculatorButton> buttons;
  final bool hasDisplay;
  final int displayRowSpan;
  final String description;

  const CalculatorLayout({
    required this.name,
    required this.rows,
    required this.columns,
    required this.buttons,
    this.hasDisplay = true,
    this.displayRowSpan = 1,
    this.description = '',
  });

  factory CalculatorLayout.fromJson(Map<String, dynamic> json) {
    return CalculatorLayout(
      name: json['name']?.toString() ?? 'AI 布局',
      rows: CalculatorTheme._parseInt(json['rows']) ?? 6,
      columns: CalculatorTheme._parseInt(json['columns']) ?? 4,
      buttons: (json['buttons'] as List<dynamic>?)
              ?.map((e) => CalculatorButton.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasDisplay: json['hasDisplay'] ?? true,
      displayRowSpan: CalculatorTheme._parseInt(json['displayRowSpan']) ?? 1,
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rows': rows,
      'columns': columns,
      'buttons': buttons.map((e) => e.toJson()).toList(),
      'hasDisplay': hasDisplay,
      'displayRowSpan': displayRowSpan,
      'description': description,
    };
  }
}

/// 完整的计算器配置
class CalculatorConfig {
  final String id;
  final String name;
  final String? description;
  final int version;
  final CalculatorTheme theme;
  final CalculatorLayout layout;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final String? authorPrompt; // 用户的原始描述

  const CalculatorConfig({
    required this.id,
    required this.name,
    this.description,
    this.version = 1,
    required this.createdAt,
    this.authorPrompt,
    required this.theme,
    required this.layout,
    this.metadata,
  });

  factory CalculatorConfig.fromJson(Map<String, dynamic> json) {
    return CalculatorConfig(
      id: json['id']?.toString() ?? 'ai-config-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'AI 生成计算器',
      description: json['description']?.toString(),
      version: CalculatorTheme._parseInt(json['version']) ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorPrompt: json['authorPrompt']?.toString(),
      theme: CalculatorTheme.fromJson(json['theme'] as Map<String, dynamic>? ?? {}),
      layout: CalculatorLayout.fromJson(json['layout'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theme': theme.toJson(),
      'layout': layout.toJson(),
      if (metadata != null) 'metadata': metadata,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      if (authorPrompt != null) 'authorPrompt': authorPrompt,
    };
  }

  /// 创建默认的基础计算器配置
  static CalculatorConfig createDefault() {
    return CalculatorConfig(
      id: 'default',
      name: '经典计算器',
      description: '标准的基础计算器',
      createdAt: DateTime.now(),
      theme: const CalculatorTheme(
        name: '经典黑',
        backgroundColor: '#000000',
        displayBackgroundColor: '#1a1a1a',
        displayTextColor: '#ffffff',
        primaryButtonColor: '#333333',
        primaryButtonTextColor: '#ffffff',
        secondaryButtonColor: '#666666',
        secondaryButtonTextColor: '#ffffff',
        operatorButtonColor: '#ff9500',
        operatorButtonTextColor: '#ffffff',
      ),
      layout: CalculatorLayout(
        name: '标准布局',
        rows: 6,
        columns: 4,
        buttons: [
          // 第一行: C, ±, %, ÷
          CalculatorButton(
            id: 'clear',
            label: 'C',
            action: const CalculatorAction(type: CalculatorActionType.clearAll),
            gridPosition: const GridPosition(row: 1, column: 0),
            type: ButtonType.secondary,
          ),
          CalculatorButton(
            id: 'negate',
            label: '±',
            action: const CalculatorAction(type: CalculatorActionType.negate),
            gridPosition: const GridPosition(row: 1, column: 1),
            type: ButtonType.secondary,
          ),
          CalculatorButton(
            id: 'percentage',
            label: '%',
            action: const CalculatorAction(type: CalculatorActionType.percentage),
            gridPosition: const GridPosition(row: 1, column: 2),
            type: ButtonType.secondary,
          ),
          CalculatorButton(
            id: 'divide',
            label: '÷',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '/'),
            gridPosition: const GridPosition(row: 1, column: 3),
            type: ButtonType.operator,
          ),
          
          // 第二行: 7, 8, 9, ×
          CalculatorButton(
            id: 'seven',
            label: '7',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '7'),
            gridPosition: const GridPosition(row: 2, column: 0),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'eight',
            label: '8',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '8'),
            gridPosition: const GridPosition(row: 2, column: 1),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'nine',
            label: '9',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '9'),
            gridPosition: const GridPosition(row: 2, column: 2),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'multiply',
            label: '×',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '*'),
            gridPosition: const GridPosition(row: 2, column: 3),
            type: ButtonType.operator,
          ),
          
          // 第三行: 4, 5, 6, -
          CalculatorButton(
            id: 'four',
            label: '4',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '4'),
            gridPosition: const GridPosition(row: 3, column: 0),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'five',
            label: '5',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '5'),
            gridPosition: const GridPosition(row: 3, column: 1),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'six',
            label: '6',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '6'),
            gridPosition: const GridPosition(row: 3, column: 2),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'subtract',
            label: '-',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '-'),
            gridPosition: const GridPosition(row: 3, column: 3),
            type: ButtonType.operator,
          ),
          
          // 第四行: 1, 2, 3, +
          CalculatorButton(
            id: 'one',
            label: '1',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '1'),
            gridPosition: const GridPosition(row: 4, column: 0),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'two',
            label: '2',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '2'),
            gridPosition: const GridPosition(row: 4, column: 1),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'three',
            label: '3',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '3'),
            gridPosition: const GridPosition(row: 4, column: 2),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'add',
            label: '+',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '+'),
            gridPosition: const GridPosition(row: 4, column: 3),
            type: ButtonType.operator,
          ),
          
          // 第五行: 0 (宽按钮), ., =
          CalculatorButton(
            id: 'zero',
            label: '0',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '0'),
            gridPosition: const GridPosition(row: 5, column: 0, columnSpan: 2),
            type: ButtonType.primary,
            isWide: true,
          ),
          CalculatorButton(
            id: 'decimal',
            label: '.',
            action: const CalculatorAction(type: CalculatorActionType.decimal),
            gridPosition: const GridPosition(row: 5, column: 2),
            type: ButtonType.primary,
          ),
          CalculatorButton(
            id: 'equals',
            label: '=',
            action: const CalculatorAction(type: CalculatorActionType.equals),
            gridPosition: const GridPosition(row: 5, column: 3),
            type: ButtonType.operator,
          ),
        ],
      ),
    );
  }
} 