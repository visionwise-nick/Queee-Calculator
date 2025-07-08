import 'package:flutter/material.dart';
import '../core/calculator_engine.dart';

/// APP背景图配置
class AppBackgroundConfig {
  final String? backgroundImageUrl;
  final String? backgroundType; // 'color', 'gradient', 'image', 'pattern'
  final String? backgroundColor;
  final List<String>? backgroundGradient;
  final String? backgroundPattern;
  final double? backgroundOpacity;
  final double? buttonOpacity; // �� 新增：按键透明度控制
  final double? displayOpacity; // 🔧 新增：显示区域透明度控制
  final String? backgroundBlendMode; // multiply, overlay, screen, etc.
  final bool? parallaxEffect;
  final double? parallaxIntensity;
  
  const AppBackgroundConfig({
    this.backgroundImageUrl,
    this.backgroundType = 'color',
    this.backgroundColor = '#000000',
    this.backgroundGradient,
    this.backgroundPattern,
    this.backgroundOpacity = 1.0,
    this.buttonOpacity = 1.0, // 🔧 新增：默认按键透明度为100%
    this.displayOpacity = 1.0, // 🔧 新增：默认显示区域透明度为100%
    this.backgroundBlendMode,
    this.parallaxEffect = false,
    this.parallaxIntensity = 0.1,
  });

  factory AppBackgroundConfig.fromJson(Map<String, dynamic> json) {
    return AppBackgroundConfig(
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      backgroundType: json['backgroundType'] as String? ?? 'color',
      backgroundColor: json['backgroundColor'] as String? ?? '#000000',
      backgroundGradient: (json['backgroundGradient'] as List<dynamic>?)?.cast<String>(),
      backgroundPattern: json['backgroundPattern'] as String?,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      buttonOpacity: (json['buttonOpacity'] as num?)?.toDouble() ?? 1.0, // 🔧 新增
      displayOpacity: (json['displayOpacity'] as num?)?.toDouble() ?? 1.0, // 🔧 新增
      backgroundBlendMode: json['backgroundBlendMode'] as String?,
      parallaxEffect: json['parallaxEffect'] as bool? ?? false,
      parallaxIntensity: (json['parallaxIntensity'] as num?)?.toDouble() ?? 0.1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundImageUrl': backgroundImageUrl,
      'backgroundType': backgroundType,
      'backgroundColor': backgroundColor,
      'backgroundGradient': backgroundGradient,
      'backgroundPattern': backgroundPattern,
      'backgroundOpacity': backgroundOpacity,
      'buttonOpacity': buttonOpacity, // 🔧 新增
      'displayOpacity': displayOpacity, // 🔧 新增
      'backgroundBlendMode': backgroundBlendMode,
      'parallaxEffect': parallaxEffect,
      'parallaxIntensity': parallaxIntensity,
    };
  }

  AppBackgroundConfig copyWith({
    String? backgroundImageUrl,
    String? backgroundType,
    String? backgroundColor,
    List<String>? backgroundGradient,
    String? backgroundPattern,
    double? backgroundOpacity,
    double? buttonOpacity, // 🔧 新增
    double? displayOpacity, // 🔧 新增
    String? backgroundBlendMode,
    bool? parallaxEffect,
    double? parallaxIntensity,
  }) {
    return AppBackgroundConfig(
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundPattern: backgroundPattern ?? this.backgroundPattern,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      buttonOpacity: buttonOpacity ?? this.buttonOpacity, // 🔧 新增
      displayOpacity: displayOpacity ?? this.displayOpacity, // 🔧 新增
      backgroundBlendMode: backgroundBlendMode ?? this.backgroundBlendMode,
      parallaxEffect: parallaxEffect ?? this.parallaxEffect,
      parallaxIntensity: parallaxIntensity ?? this.parallaxIntensity,
    );
  }
}

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
  final double? displayHeightRatio; // AI可调节的显示区域高度比例
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
    this.displayHeightRatio,
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
      displayHeightRatio: (json['displayHeightRatio'] as num?)?.toDouble(),
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
      'displayHeightRatio': displayHeightRatio,
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
  final String type; // primary, secondary, operator, special
  final String? customColor;
  final bool isWide;
  final double widthMultiplier;
  final double heightMultiplier;
  final List<String>? gradientColors;
  final String? backgroundImage;
  final double? fontSize;
  final String? fontFamily;
  final double? borderRadius;
  final double? elevation;
  final double? width;
  final double? height;
  final String? backgroundColor;
  final String? textColor;
  final String? borderColor;
  final double? borderWidth;
  final String? shadowColor;
  final Map<String, double>? shadowOffset;
  final double? shadowRadius;
  final double? opacity;
  final double? rotation;
  final double? scale;
  final String? backgroundPattern;
  final String? patternColor;
  final double? patternOpacity;
  final String? animation;
  final double? animationDuration;
  final String? customIcon;
  final double? iconSize;
  final String? iconColor;
  
  // 新增：自适应大小相关属性
  final bool? adaptiveSize; // 是否启用自适应大小
  final double? minWidth; // 最小宽度
  final double? maxWidth; // 最大宽度
  final double? minHeight; // 最小高度
  final double? maxHeight; // 最大高度
  final double? aspectRatio; // 宽高比，null表示不限制
  final String? sizeMode; // 'content', 'fill', 'fixed', 'adaptive'
  final EdgeInsets? contentPadding; // 内容边距
  final bool? autoShrink; // 内容过长时是否自动缩小
  final double? textScaleFactor; // 文字缩放因子

  const CalculatorButton({
    required this.id,
    required this.label,
    required this.action,
    required this.gridPosition,
    required this.type,
    this.customColor,
    this.isWide = false,
    this.widthMultiplier = 1.0,
    this.heightMultiplier = 1.0,
    this.gradientColors,
    this.backgroundImage,
    this.fontSize,
    this.fontFamily,
    this.borderRadius,
    this.elevation,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.shadowColor,
    this.shadowOffset,
    this.shadowRadius,
    this.opacity,
    this.rotation,
    this.scale,
    this.backgroundPattern,
    this.patternColor,
    this.patternOpacity,
    this.animation,
    this.animationDuration,
    this.customIcon,
    this.iconSize,
    this.iconColor,
    // 新增属性
    this.adaptiveSize,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.aspectRatio,
    this.sizeMode,
    this.contentPadding,
    this.autoShrink,
    this.textScaleFactor,
  });

  factory CalculatorButton.fromJson(Map<String, dynamic> json) {
    return CalculatorButton(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      action: CalculatorAction.fromJson(json['action'] ?? {}),
      gridPosition: GridPosition.fromJson(json['gridPosition'] ?? {}),
      type: json['type'] ?? 'primary',
      customColor: json['customColor'],
      isWide: json['isWide'] ?? false,
      widthMultiplier: (json['widthMultiplier'] ?? 1.0).toDouble(),
      heightMultiplier: (json['heightMultiplier'] ?? 1.0).toDouble(),
      gradientColors: json['gradientColors']?.cast<String>(),
      backgroundImage: json['backgroundImage'],
      fontSize: json['fontSize']?.toDouble(),
      fontFamily: json['fontFamily'] as String?,
      borderRadius: json['borderRadius']?.toDouble(),
      elevation: json['elevation']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
      borderColor: json['borderColor'],
      borderWidth: json['borderWidth']?.toDouble(),
      shadowColor: json['shadowColor'],
      shadowOffset: json['shadowOffset'] != null 
          ? Map<String, double>.from(json['shadowOffset'].map((k, v) => MapEntry(k, v.toDouble())))
          : null,
      shadowRadius: json['shadowRadius']?.toDouble(),
      opacity: json['opacity']?.toDouble(),
      rotation: json['rotation']?.toDouble(),
      scale: json['scale']?.toDouble(),
      backgroundPattern: json['backgroundPattern'],
      patternColor: json['patternColor'],
      patternOpacity: json['patternOpacity']?.toDouble(),
      animation: json['animation'],
      animationDuration: json['animationDuration']?.toDouble(),
      customIcon: json['customIcon'],
      iconSize: json['iconSize']?.toDouble(),
      iconColor: json['iconColor'],
      // 新增属性解析
      adaptiveSize: json['adaptiveSize'] as bool?,
      minWidth: json['minWidth']?.toDouble(),
      maxWidth: json['maxWidth']?.toDouble(),
      minHeight: json['minHeight']?.toDouble(),
      maxHeight: json['maxHeight']?.toDouble(),
      aspectRatio: json['aspectRatio']?.toDouble(),
      sizeMode: json['sizeMode'] as String?,
      contentPadding: json['contentPadding'] != null 
          ? EdgeInsets.fromLTRB(
              json['contentPadding']['left']?.toDouble() ?? 0,
              json['contentPadding']['top']?.toDouble() ?? 0,
              json['contentPadding']['right']?.toDouble() ?? 0,
              json['contentPadding']['bottom']?.toDouble() ?? 0,
            )
          : null,
      autoShrink: json['autoShrink'] as bool?,
      textScaleFactor: json['textScaleFactor']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action': action.toJson(),
      'gridPosition': gridPosition.toJson(),
      'type': type,
      'customColor': customColor,
      'isWide': isWide,
      'widthMultiplier': widthMultiplier,
      'heightMultiplier': heightMultiplier,
      'gradientColors': gradientColors,
      'backgroundImage': backgroundImage,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'borderRadius': borderRadius,
      'elevation': elevation,
      'width': width,
      'height': height,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'shadowColor': shadowColor,
      'shadowOffset': shadowOffset,
      'shadowRadius': shadowRadius,
      'opacity': opacity,
      'rotation': rotation,
      'scale': scale,
      'backgroundPattern': backgroundPattern,
      'patternColor': patternColor,
      'patternOpacity': patternOpacity,
      'animation': animation,
      'animationDuration': animationDuration,
      'customIcon': customIcon,
      'iconSize': iconSize,
      'iconColor': iconColor,
      // 新增属性序列化
      'adaptiveSize': adaptiveSize,
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'aspectRatio': aspectRatio,
      'sizeMode': sizeMode,
      'contentPadding': contentPadding != null 
          ? {
              'left': contentPadding!.left,
              'top': contentPadding!.top,
              'right': contentPadding!.right,
              'bottom': contentPadding!.bottom,
            }
          : null,
      'autoShrink': autoShrink,
      'textScaleFactor': textScaleFactor,
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
  final AppBackgroundConfig? appBackground; // 新增：APP背景配置
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
    this.appBackground,
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
      appBackground: json['appBackground'] != null 
          ? AppBackgroundConfig.fromJson(json['appBackground'])
          : null,
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
      if (appBackground != null) 'appBackground': appBackground!.toJson(),
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
            isWide: true,
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