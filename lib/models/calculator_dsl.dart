import '../core/calculator_engine.dart';

/// 计算器主题配置 - 简化版
class CalculatorTheme {
  final String name;
  final String backgroundColor;
  final List<String>? backgroundGradient; // 背景渐变色
  final String? backgroundImage; // 背景图片URL
  final String displayBackgroundColor;
  final List<String>? displayBackgroundGradient; // 显示区渐变
  final String displayTextColor;
  final double? displayWidth;
  final double? displayHeight;
  final double? displayBorderRadius;
  final String primaryButtonColor;
  final List<String>? primaryButtonGradient; // 主按钮渐变
  final String primaryButtonTextColor;
  final String secondaryButtonColor;
  final List<String>? secondaryButtonGradient; // 次按钮渐变
  final String secondaryButtonTextColor;
  final String operatorButtonColor;
  final List<String>? operatorButtonGradient; // 运算符渐变
  final String operatorButtonTextColor;
  final double fontSize;
  final double buttonBorderRadius;
  final bool hasGlowEffect;
  final String? shadowColor;
  final double? buttonElevation; // 按钮阴影高度
  final List<String>? buttonShadowColors; // 多层阴影颜色
  final double? buttonSpacing;
  final bool adaptiveLayout;

  const CalculatorTheme({
    required this.name,
    this.backgroundColor = '#000000',
    this.backgroundGradient,
    this.backgroundImage,
    this.displayBackgroundColor = '#222222',
    this.displayBackgroundGradient,
    this.displayTextColor = '#FFFFFF',
    this.displayWidth,
    this.displayHeight,
    this.displayBorderRadius,
    this.primaryButtonColor = '#333333',
    this.primaryButtonGradient,
    this.primaryButtonTextColor = '#FFFFFF',
    this.secondaryButtonColor = '#555555',
    this.secondaryButtonGradient,
    this.secondaryButtonTextColor = '#FFFFFF',
    this.operatorButtonColor = '#FF9F0A',
    this.operatorButtonGradient,
    this.operatorButtonTextColor = '#FFFFFF',
    this.fontSize = 24.0,
    this.buttonBorderRadius = 8.0,
    this.hasGlowEffect = false,
    this.shadowColor,
    this.buttonElevation,
    this.buttonShadowColors,
    this.buttonSpacing,
    this.adaptiveLayout = true,
  });

  factory CalculatorTheme.fromJson(Map<String, dynamic> json) {
    return CalculatorTheme(
      name: json['name'] as String,
      backgroundColor: json['backgroundColor'] as String? ?? '#000000',
      backgroundGradient: (json['backgroundGradient'] as List<dynamic>?)?.cast<String>(),
      backgroundImage: json['backgroundImage'] as String?,
      displayBackgroundColor: json['displayBackgroundColor'] as String? ?? '#222222',
      displayBackgroundGradient: (json['displayBackgroundGradient'] as List<dynamic>?)?.cast<String>(),
      displayTextColor: json['displayTextColor'] as String? ?? '#FFFFFF',
      displayWidth: (json['displayWidth'] as num?)?.toDouble(),
      displayHeight: (json['displayHeight'] as num?)?.toDouble(),
      displayBorderRadius: (json['displayBorderRadius'] as num?)?.toDouble(),
      primaryButtonColor: json['primaryButtonColor'] as String? ?? '#333333',
      primaryButtonGradient: (json['primaryButtonGradient'] as List<dynamic>?)?.cast<String>(),
      primaryButtonTextColor: json['primaryButtonTextColor'] as String? ?? '#FFFFFF',
      secondaryButtonColor: json['secondaryButtonColor'] as String? ?? '#555555',
      secondaryButtonGradient: (json['secondaryButtonGradient'] as List<dynamic>?)?.cast<String>(),
      secondaryButtonTextColor: json['secondaryButtonTextColor'] as String? ?? '#FFFFFF',
      operatorButtonColor: json['operatorButtonColor'] as String? ?? '#FF9F0A',
      operatorButtonGradient: (json['operatorButtonGradient'] as List<dynamic>?)?.cast<String>(),
      operatorButtonTextColor: json['operatorButtonTextColor'] as String? ?? '#FFFFFF',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      buttonBorderRadius: (json['buttonBorderRadius'] as num?)?.toDouble() ?? 8.0,
      hasGlowEffect: json['hasGlowEffect'] as bool? ?? false,
      shadowColor: json['shadowColor'] as String?,
      buttonElevation: (json['buttonElevation'] as num?)?.toDouble(),
      buttonShadowColors: (json['buttonShadowColors'] as List<dynamic>?)?.cast<String>(),
      buttonSpacing: (json['buttonSpacing'] as num?)?.toDouble(),
      adaptiveLayout: json['adaptiveLayout'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'backgroundColor': backgroundColor,
      'backgroundGradient': backgroundGradient,
      'backgroundImage': backgroundImage,
      'displayBackgroundColor': displayBackgroundColor,
      'displayBackgroundGradient': displayBackgroundGradient,
      'displayTextColor': displayTextColor,
      'displayWidth': displayWidth,
      'displayHeight': displayHeight,
      'displayBorderRadius': displayBorderRadius,
      'primaryButtonColor': primaryButtonColor,
      'primaryButtonGradient': primaryButtonGradient,
      'primaryButtonTextColor': primaryButtonTextColor,
      'secondaryButtonColor': secondaryButtonColor,
      'secondaryButtonGradient': secondaryButtonGradient,
      'secondaryButtonTextColor': secondaryButtonTextColor,
      'operatorButtonColor': operatorButtonColor,
      'operatorButtonGradient': operatorButtonGradient,
      'operatorButtonTextColor': operatorButtonTextColor,
      'fontSize': fontSize,
      'buttonBorderRadius': buttonBorderRadius,
      'hasGlowEffect': hasGlowEffect,
      'shadowColor': shadowColor,
      'buttonElevation': buttonElevation,
      'buttonShadowColors': buttonShadowColors,
      'buttonSpacing': buttonSpacing,
      'adaptiveLayout': adaptiveLayout,
    };
  }
}

/// 按钮类型
enum ButtonType {
  primary,    // 数字按钮
  secondary,  // 功能按钮 (C, ±)
  operator,   // 运算符按钮 (+, -, *, /, =)
  special,    // 特殊按钮 (自定义功能)
}

/// 网格位置
class GridPosition {
  final int row;
  final int column;
  final int? columnSpan;

  const GridPosition({
    required this.row,
    required this.column,
    this.columnSpan,
  });

  factory GridPosition.fromJson(Map<String, dynamic> json) {
    return GridPosition(
      row: (json['row'] as num?)?.toInt() ?? 0,
      column: (json['column'] as num?)?.toInt() ?? 0,
      columnSpan: (json['columnSpan'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'column': column,
      if (columnSpan != null) 'columnSpan': columnSpan,
    };
  }
}

/// 计算器按钮配置 - 简化版
class CalculatorButton {
  final String id;
  final String label;
  final CalculatorAction action;
  final GridPosition gridPosition;
  final String type;
  final double? widthMultiplier;
  final double? heightMultiplier;
  final String? backgroundColor;
  final String? textColor;
  final double? fontSize;
  final double? borderRadius;
  final double? elevation;
  final List<String>? gradientColors;
  final String? backgroundImage;
  final String? description;

  CalculatorButton({
    required this.id,
    required this.label,
    required this.action,
    required this.gridPosition,
    required this.type,
    this.widthMultiplier,
    this.heightMultiplier,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
    this.elevation,
    this.gradientColors,
    this.backgroundImage,
    this.description,
  });

  factory CalculatorButton.fromJson(Map<String, dynamic> json) {
    return CalculatorButton(
      id: json['id'],
      label: json['label'],
      action: CalculatorAction.fromJson(json['action']),
      gridPosition: GridPosition.fromJson(json['gridPosition']),
      type: json['type'],
      widthMultiplier: (json['widthMultiplier'] as num?)?.toDouble(),
      heightMultiplier: (json['heightMultiplier'] as num?)?.toDouble(),
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      borderRadius: (json['borderRadius'] as num?)?.toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble(),
      gradientColors: json['gradientColors'] != null
          ? List<String>.from(json['gradientColors'])
          : null,
      backgroundImage: json['backgroundImage'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action': action.toJson(),
      'gridPosition': gridPosition.toJson(),
      'type': type,
      'widthMultiplier': widthMultiplier,
      'heightMultiplier': heightMultiplier,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontSize': fontSize,
      'borderRadius': borderRadius,
      'elevation': elevation,
      'gradientColors': gradientColors,
      'backgroundImage': backgroundImage,
      'description': description,
    };
  }
}

/// 计算器布局配置
class CalculatorLayout {
  final String name;
  final int rows;
  final int columns;
  final List<CalculatorButton> buttons;
  final String description;
  final double? minButtonSize;
  final double? maxButtonSize;
  final double? gridSpacing;

  const CalculatorLayout({
    required this.name,
    required this.rows,
    required this.columns,
    required this.buttons,
    this.description = '',
    this.minButtonSize,
    this.maxButtonSize,
    this.gridSpacing,
  });

  factory CalculatorLayout.fromJson(Map<String, dynamic> json) {
    return CalculatorLayout(
      name: json['name'] as String,
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      buttons: (json['buttons'] as List<dynamic>)
          .map((button) => CalculatorButton.fromJson(button as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String? ?? '',
      minButtonSize: (json['minButtonSize'] as num?)?.toDouble(),
      maxButtonSize: (json['maxButtonSize'] as num?)?.toDouble(),
      gridSpacing: (json['gridSpacing'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rows': rows,
      'columns': columns,
      'buttons': buttons.map((button) => button.toJson()).toList(),
      'description': description,
      'minButtonSize': minButtonSize,
      'maxButtonSize': maxButtonSize,
      'gridSpacing': gridSpacing,
    };
  }
}

/// 完整的计算器配置 - 简化版
class CalculatorConfig {
  final String id;
  final String name;
  final String description;
  final CalculatorTheme theme;
  final CalculatorLayout layout;
  final String version;
  final DateTime createdAt;
  final String? authorPrompt;
  final String? thinkingProcess;
  final String? aiResponse;

  const CalculatorConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.layout,
    this.version = '1.0.0',
    required this.createdAt,
    this.authorPrompt,
    this.thinkingProcess,
    this.aiResponse,
  });

  factory CalculatorConfig.fromJson(Map<String, dynamic> json) {
    return CalculatorConfig(
      id: json['id']?.toString() ?? 'generated-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? '未命名计算器',
      description: json['description']?.toString() ?? '',
      theme: CalculatorTheme.fromJson(json['theme'] ?? {}),
      layout: CalculatorLayout.fromJson(json['layout'] ?? {}),
      version: json['version']?.toString() ?? '1.0.0',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorPrompt: json['authorPrompt']?.toString(),
      thinkingProcess: json['thinkingProcess']?.toString(),
      aiResponse: json['aiResponse']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theme': theme.toJson(),
      'layout': layout.toJson(),
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      if (authorPrompt != null) 'authorPrompt': authorPrompt,
      if (thinkingProcess != null) 'thinkingProcess': thinkingProcess,
      if (aiResponse != null) 'aiResponse': aiResponse,
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
          // 基础按钮配置
          CalculatorButton(
            id: 'clear',
            label: 'AC',
            action: const CalculatorAction(type: CalculatorActionType.clearAll),
            gridPosition: const GridPosition(row: 1, column: 0),
            type: 'secondary',
          ),
          CalculatorButton(
            id: 'negate',
            label: '±',
            action: const CalculatorAction(type: CalculatorActionType.negate),
            gridPosition: const GridPosition(row: 1, column: 1),
            type: 'secondary',
          ),
          CalculatorButton(
            id: 'percent',
            label: '%',
            action: const CalculatorAction(type: CalculatorActionType.expression, expression: 'x*0.01'),
            gridPosition: const GridPosition(row: 1, column: 2),
            type: 'secondary',
          ),
          CalculatorButton(
            id: 'divide',
            label: '÷',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '/'),
            gridPosition: const GridPosition(row: 1, column: 3),
            type: 'operator',
          ),
          // 数字按钮 7-9
          CalculatorButton(
            id: 'seven',
            label: '7',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '7'),
            gridPosition: const GridPosition(row: 2, column: 0),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'eight',
            label: '8',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '8'),
            gridPosition: const GridPosition(row: 2, column: 1),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'nine',
            label: '9',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '9'),
            gridPosition: const GridPosition(row: 2, column: 2),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'multiply',
            label: '×',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '*'),
            gridPosition: const GridPosition(row: 2, column: 3),
            type: 'operator',
          ),
          // 数字按钮 4-6
          CalculatorButton(
            id: 'four',
            label: '4',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '4'),
            gridPosition: const GridPosition(row: 3, column: 0),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'five',
            label: '5',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '5'),
            gridPosition: const GridPosition(row: 3, column: 1),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'six',
            label: '6',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '6'),
            gridPosition: const GridPosition(row: 3, column: 2),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'subtract',
            label: '-',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '-'),
            gridPosition: const GridPosition(row: 3, column: 3),
            type: 'operator',
          ),
          // 数字按钮 1-3
          CalculatorButton(
            id: 'one',
            label: '1',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '1'),
            gridPosition: const GridPosition(row: 4, column: 0),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'two',
            label: '2',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '2'),
            gridPosition: const GridPosition(row: 4, column: 1),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'three',
            label: '3',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '3'),
            gridPosition: const GridPosition(row: 4, column: 2),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'add',
            label: '+',
            action: const CalculatorAction(type: CalculatorActionType.operator, value: '+'),
            gridPosition: const GridPosition(row: 4, column: 3),
            type: 'operator',
          ),
          // 最后一行：0, ., =
          CalculatorButton(
            id: 'zero',
            label: '0',
            action: const CalculatorAction(type: CalculatorActionType.input, value: '0'),
            gridPosition: const GridPosition(row: 5, column: 0, columnSpan: 2),
            type: 'primary',
            widthMultiplier: 2.0,
          ),
          CalculatorButton(
            id: 'decimal',
            label: '.',
            action: const CalculatorAction(type: CalculatorActionType.decimal),
            gridPosition: const GridPosition(row: 5, column: 2),
            type: 'primary',
          ),
          CalculatorButton(
            id: 'equals',
            label: '=',
            action: const CalculatorAction(type: CalculatorActionType.equals),
            gridPosition: const GridPosition(row: 5, column: 3),
            type: 'operator',
          ),
        ],
      ),
    );
  }
} 