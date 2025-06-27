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
  
  // 新增样式选项
  final double? buttonSpacing;        // 按钮间距
  final double? buttonElevation;      // 按钮阴影高度
  final String? buttonBorderColor;    // 按钮边框颜色
  final double? buttonBorderWidth;    // 按钮边框宽度
  final String? gradientStartColor;   // 渐变起始颜色
  final String? gradientEndColor;     // 渐变结束颜色
  final bool hasRippleEffect;         // 是否有水波纹效果
  final bool hasVibration;            // 是否有震动反馈
  final String? accentColor;          // 强调色
  final double displayFontSize;       // 显示屏字体大小
  final String? displayFontFamily;    // 显示屏字体
  final bool isDisplayBold;           // 显示屏字体是否加粗
  final double? containerPadding;     // 容器内边距
  final double? containerMargin;      // 容器外边距

  const CalculatorTheme({
    required this.name,
    this.backgroundColor = '#000000',
    this.displayBackgroundColor = '#222222',
    this.displayTextColor = '#FFFFFF',
    this.primaryButtonColor = '#333333',
    this.primaryButtonTextColor = '#FFFFFF',
    this.secondaryButtonColor = '#555555',
    this.secondaryButtonTextColor = '#FFFFFF',
    this.operatorButtonColor = '#FF9F0A',
    this.operatorButtonTextColor = '#FFFFFF',
    this.backgroundImage,
    this.fontFamily,
    this.fontSize = 24.0,
    this.buttonBorderRadius = 8.0,
    this.hasGlowEffect = false,
    this.shadowColor,
    this.soundEffects,
    // 新增字段
    this.buttonSpacing,
    this.buttonElevation,
    this.buttonBorderColor,
    this.buttonBorderWidth,
    this.gradientStartColor,
    this.gradientEndColor,
    this.hasRippleEffect = true,
    this.hasVibration = false,
    this.accentColor,
    this.displayFontSize = 32.0,
    this.displayFontFamily,
    this.isDisplayBold = false,
    this.containerPadding,
    this.containerMargin,
  });

  factory CalculatorTheme.fromJson(Map<String, dynamic> json) {
    return CalculatorTheme(
      name: json['name'] ?? '未命名主题',
      backgroundColor: json['backgroundColor'] ?? '#000000',
      displayBackgroundColor: json['displayBackgroundColor'] ?? '#222222',
      displayTextColor: json['displayTextColor'] ?? '#FFFFFF',
      primaryButtonColor: json['primaryButtonColor'] ?? '#333333',
      primaryButtonTextColor: json['primaryButtonTextColor'] ?? '#FFFFFF',
      secondaryButtonColor: json['secondaryButtonColor'] ?? '#555555',
      secondaryButtonTextColor: json['secondaryButtonTextColor'] ?? '#FFFFFF',
      operatorButtonColor: json['operatorButtonColor'] ?? '#FF9F0A',
      operatorButtonTextColor: json['operatorButtonTextColor'] ?? '#FFFFFF',
      backgroundImage: json['backgroundImage'],
      fontFamily: json['fontFamily'],
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      buttonBorderRadius: (json['buttonBorderRadius'] as num?)?.toDouble() ?? 8.0,
      hasGlowEffect: json['hasGlowEffect'] ?? false,
      shadowColor: json['shadowColor'],
      soundEffects: (json['soundEffects'] as List?)
          ?.map((e) => SoundEffect.fromJson(e))
          .toList(),
      // 新增字段解析
      buttonSpacing: (json['buttonSpacing'] as num?)?.toDouble(),
      buttonElevation: (json['buttonElevation'] as num?)?.toDouble(),
      buttonBorderColor: json['buttonBorderColor'],
      buttonBorderWidth: (json['buttonBorderWidth'] as num?)?.toDouble(),
      gradientStartColor: json['gradientStartColor'],
      gradientEndColor: json['gradientEndColor'],
      hasRippleEffect: json['hasRippleEffect'] ?? true,
      hasVibration: json['hasVibration'] ?? false,
      accentColor: json['accentColor'],
      displayFontSize: (json['displayFontSize'] as num?)?.toDouble() ?? 32.0,
      displayFontFamily: json['displayFontFamily'],
      isDisplayBold: json['isDisplayBold'] ?? false,
      containerPadding: (json['containerPadding'] as num?)?.toDouble(),
      containerMargin: (json['containerMargin'] as num?)?.toDouble(),
    );
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
      // 新增字段序列化
      if (buttonSpacing != null) 'buttonSpacing': buttonSpacing,
      if (buttonElevation != null) 'buttonElevation': buttonElevation,
      if (buttonBorderColor != null) 'buttonBorderColor': buttonBorderColor,
      if (buttonBorderWidth != null) 'buttonBorderWidth': buttonBorderWidth,
      if (gradientStartColor != null) 'gradientStartColor': gradientStartColor,
      if (gradientEndColor != null) 'gradientEndColor': gradientEndColor,
      'hasRippleEffect': hasRippleEffect,
      'hasVibration': hasVibration,
      if (accentColor != null) 'accentColor': accentColor,
      'displayFontSize': displayFontSize,
      if (displayFontFamily != null) 'displayFontFamily': displayFontFamily,
      'isDisplayBold': isDisplayBold,
      if (containerPadding != null) 'containerPadding': containerPadding,
      if (containerMargin != null) 'containerMargin': containerMargin,
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
      trigger: json['trigger'],
      soundUrl: json['soundUrl'],
      volume: json['volume']?.toDouble() ?? 1.0,
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
    return CalculatorButton(
      id: json['id']?.toString() ?? 'unknown',
      label: json['label']?.toString() ?? '',
      action: CalculatorAction.fromJson(json['action'] ?? {}),
      gridPosition: GridPosition.fromJson(json['gridPosition'] ?? {}),
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
      row: (json['row'] as num?)?.toInt() ?? 0,
      column: (json['column'] as num?)?.toInt() ?? 0,
      rowSpan: (json['rowSpan'] as num?)?.toInt(),
      columnSpan: (json['columnSpan'] as num?)?.toInt(),
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
      name: json['name']?.toString() ?? '标准布局',
      rows: (json['rows'] as num?)?.toInt() ?? 6,
      columns: (json['columns'] as num?)?.toInt() ?? 4,
      buttons: (json['buttons'] as List?)
          ?.map((e) => CalculatorButton.fromJson(e))
          .toList() ?? [],
      hasDisplay: json['hasDisplay'] ?? true,
      displayRowSpan: (json['displayRowSpan'] as num?)?.toInt() ?? 1,
      description: json['description']?.toString() ?? '由AI生成的计算器布局',
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
  final String description;
  final CalculatorTheme theme;
  final CalculatorLayout layout;
  final Map<String, dynamic>? metadata;
  final String version;
  final DateTime createdAt;
  final String? authorPrompt; // 用户的原始描述

  const CalculatorConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.layout,
    this.metadata,
    this.version = '1.0.0',
    required this.createdAt,
    this.authorPrompt,
  });

  factory CalculatorConfig.fromJson(Map<String, dynamic> json) {
    return CalculatorConfig(
      id: json['id']?.toString() ?? 'generated-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? '未命名计算器',
      description: json['description']?.toString() ?? '',
      theme: CalculatorTheme.fromJson(json['theme'] ?? {}),
      layout: CalculatorLayout.fromJson(json['layout'] ?? {}),
      metadata: json['metadata'],
      version: json['version']?.toString() ?? '1.0.0',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorPrompt: json['authorPrompt']?.toString(),
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