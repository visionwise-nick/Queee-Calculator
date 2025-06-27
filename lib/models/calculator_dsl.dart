import '../core/calculator_engine.dart';

/// 计算器主题配置 - 简化版
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
  final double fontSize;
  final double buttonBorderRadius;
  final bool hasGlowEffect;
  final String? shadowColor;

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
    this.fontSize = 24.0,
    this.buttonBorderRadius = 8.0,
    this.hasGlowEffect = false,
    this.shadowColor,
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
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      buttonBorderRadius: (json['buttonBorderRadius'] as num?)?.toDouble() ?? 8.0,
      hasGlowEffect: json['hasGlowEffect'] ?? false,
      shadowColor: json['shadowColor'],
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
      'fontSize': fontSize,
      'buttonBorderRadius': buttonBorderRadius,
      'hasGlowEffect': hasGlowEffect,
      if (shadowColor != null) 'shadowColor': shadowColor,
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
  final ButtonType type;
  final String? customColor;
  final bool isWide;

  const CalculatorButton({
    required this.id,
    required this.label,
    required this.action,
    required this.gridPosition,
    required this.type,
    this.customColor,
    this.isWide = false,
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
      isWide: json['isWide'] ?? false,
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
      'isWide': isWide,
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

  const CalculatorLayout({
    required this.name,
    required this.rows,
    required this.columns,
    required this.buttons,
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
      description: json['description']?.toString() ?? '由AI生成的计算器布局',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rows': rows,
      'columns': columns,
      'buttons': buttons.map((e) => e.toJson()).toList(),
      'description': description,
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
            id: 'percent',
            label: '%',
            action: const CalculatorAction(type: CalculatorActionType.expression, expression: 'x*0.01'),
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
          // 数字按钮 7-9
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
          // 数字按钮 4-6
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
          // 数字按钮 1-3
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
          // 最后一行：0, ., =
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