import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import 'calculator_button.dart';
import 'dart:math' as math;

class CalculatorButtonGrid extends StatelessWidget {
  const CalculatorButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final layout = provider.config.layout;
        final theme = provider.config.theme;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: EdgeInsets.all(_calculatePadding(constraints, theme)),
              child: _buildDynamicGrid(layout, provider, constraints, theme),
            );
          },
        );
      },
    );
  }

  /// 计算网格内边距
  double _calculatePadding(BoxConstraints constraints, CalculatorTheme theme) {
    if (theme.buttonSpacing != null) {
      return theme.buttonSpacing! * 2;
    }
    
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    if (screenArea > 300000) return 16.0; // 大屏
    if (screenArea > 150000) return 12.0; // 中屏
    return 8.0; // 小屏
  }

  /// 构建动态自适应网格
  Widget _buildDynamicGrid(CalculatorLayout layout, CalculatorProvider provider, BoxConstraints constraints, CalculatorTheme theme) {
    // 计算可用空间
    final padding = _calculatePadding(constraints, theme);
    final availableWidth = constraints.maxWidth - (padding * 2);
    final availableHeight = constraints.maxHeight - (padding * 2);
    
    // 计算最优按钮尺寸
    final buttonSizing = _calculateDynamicButtonSize(
      layout, 
      availableWidth, 
      availableHeight,
      theme
    );
    
    // 如果启用自适应布局，使用新的动态布局
    if (theme.adaptiveLayout) {
      return _buildAdaptiveFlexGrid(layout, provider, buttonSizing, theme);
    } else {
      // 使用传统固定网格
      return _buildFixedGrid(layout, provider, buttonSizing, theme);
    }
  }

  /// 计算动态按钮尺寸
  ButtonSizing _calculateDynamicButtonSize(CalculatorLayout layout, double availableWidth, double availableHeight, CalculatorTheme theme) {
    // 计算按钮间距
    final gap = layout.gridSpacing ?? theme.buttonSpacing ?? _calculateGap(availableWidth, availableHeight);
    
    // 计算基础按钮尺寸
    final baseButtonWidth = (availableWidth - (gap * (layout.columns - 1))) / layout.columns;
    final baseButtonHeight = (availableHeight - (gap * (layout.rows - 1))) / layout.rows;
    
    // 应用尺寸限制
    final minSize = layout.minButtonSize ?? 25.0;
    final maxSize = layout.maxButtonSize ?? 120.0;
    
    // 确保按钮比例合理
    final optimalSize = math.min(baseButtonWidth, baseButtonHeight);
    final finalSize = optimalSize.clamp(minSize, maxSize);
    
    return ButtonSizing(
      baseButtonWidth: math.max(finalSize, baseButtonWidth.clamp(minSize, maxSize)),
      baseButtonHeight: math.max(finalSize, baseButtonHeight.clamp(minSize, maxSize)),
      gap: gap,
      totalWidth: availableWidth,
      totalHeight: availableHeight,
    );
  }

  /// 计算按钮间距
  double _calculateGap(double width, double height) {
    final area = width * height;
    if (area > 300000) return 8.0; // 大屏更大间距
    if (area > 150000) return 6.0; // 中屏中等间距
    return 4.0; // 小屏紧凑间距
  }

  /// 构建自适应弹性网格（新方法）
  Widget _buildAdaptiveFlexGrid(CalculatorLayout layout, CalculatorProvider provider, ButtonSizing sizing, CalculatorTheme theme) {
    // 按行分组按钮
    Map<int, List<CalculatorButton>> buttonsByRow = {};
    for (final button in layout.buttons) {
      final row = button.gridPosition.row;
      if (!buttonsByRow.containsKey(row)) {
        buttonsByRow[row] = [];
      }
      buttonsByRow[row]!.add(button);
    }

    // 构建行列表
    List<Widget> rows = [];
    for (int rowIndex = 0; rowIndex < layout.rows; rowIndex++) {
      final rowButtons = buttonsByRow[rowIndex] ?? [];
      if (rowButtons.isNotEmpty) {
        rows.add(_buildAdaptiveRow(rowButtons, layout, provider, sizing, theme, rowIndex));
        
        // 添加行间距（除了最后一行）
        if (rowIndex < layout.rows - 1) {
          rows.add(SizedBox(height: sizing.gap));
        }
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rows,
    );
  }

  /// 构建自适应行
  Widget _buildAdaptiveRow(List<CalculatorButton> rowButtons, CalculatorLayout layout, CalculatorProvider provider, ButtonSizing sizing, CalculatorTheme theme, int rowIndex) {
    // 按列位置排序
    rowButtons.sort((a, b) => a.gridPosition.column.compareTo(b.gridPosition.column));
    
    // 计算这一行的最大高度倍数
    double maxHeightMultiplier = 1.0;
    for (final button in rowButtons) {
      if (button.heightMultiplier > maxHeightMultiplier) {
        maxHeightMultiplier = button.heightMultiplier;
      }
    }
    
    final rowHeight = sizing.baseButtonHeight * maxHeightMultiplier;
    
    List<Widget> rowWidgets = [];
    int currentColumn = 0;
    
    for (final button in rowButtons) {
      // 添加空白填充（如果有跳跃的列）
      while (currentColumn < button.gridPosition.column) {
        rowWidgets.add(SizedBox(width: sizing.baseButtonWidth));
        if (currentColumn < layout.columns - 1) {
          rowWidgets.add(SizedBox(width: sizing.gap));
        }
        currentColumn++;
      }
      
      // 计算按钮实际尺寸
      final buttonWidth = sizing.baseButtonWidth * button.widthMultiplier;
      final buttonHeight = sizing.baseButtonHeight * button.heightMultiplier;
      
      // 创建按钮
      rowWidgets.add(
        SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: CalculatorButtonWidget(
            button: button,
            onPressed: () => provider.executeAction(button.action),
            fixedSize: Size(buttonWidth, buttonHeight),
          ),
        ),
      );
      
      currentColumn++;
      
      // 添加列间距（除了最后一列）
      if (currentColumn < layout.columns) {
        rowWidgets.add(SizedBox(width: sizing.gap));
      }
    }
    
    // 填充剩余空间
    while (currentColumn < layout.columns) {
      rowWidgets.add(SizedBox(width: sizing.baseButtonWidth));
      if (currentColumn < layout.columns - 1) {
        rowWidgets.add(SizedBox(width: sizing.gap));
      }
      currentColumn++;
    }

    return SizedBox(
      height: rowHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rowWidgets,
      ),
    );
  }

  /// 构建固定网格（传统方法）
  Widget _buildFixedGrid(CalculatorLayout layout, CalculatorProvider provider, ButtonSizing sizing, CalculatorTheme theme) {
    // 创建网格
    List<List<Widget?>> grid = List.generate(
      layout.rows,
      (index) => List.filled(layout.columns, null),
    );

    // 将按钮放置到网格中
    for (final button in layout.buttons) {
      final position = button.gridPosition;
      
      if (position.row < layout.rows && position.column < layout.columns) {
        final buttonWidth = sizing.baseButtonWidth * button.widthMultiplier;
        final buttonHeight = sizing.baseButtonHeight * button.heightMultiplier;
        
        final buttonWidget = CalculatorButtonWidget(
          button: button,
          onPressed: () => provider.executeAction(button.action),
          fixedSize: Size(buttonWidth, buttonHeight),
        );
        
        grid[position.row][position.column] = buttonWidget;
      }
    }

    // 构建网格布局
    return Column(
      children: List.generate(layout.rows, (rowIndex) {
        return Container(
          height: sizing.baseButtonHeight,
          margin: EdgeInsets.only(
            bottom: rowIndex < layout.rows - 1 ? sizing.gap : 0,
          ),
          child: Row(
            children: List.generate(layout.columns, (colIndex) {
              final widget = grid[rowIndex][colIndex];
              return Container(
                width: sizing.baseButtonWidth,
                margin: EdgeInsets.only(
                  right: colIndex < layout.columns - 1 ? sizing.gap : 0,
                ),
                child: widget ?? const SizedBox.shrink(),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// 按钮尺寸配置（升级版）
class ButtonSizing {
  final double baseButtonWidth;
  final double baseButtonHeight; 
  final double gap;
  final double totalWidth;
  final double totalHeight;

  const ButtonSizing({
    required this.baseButtonWidth,
    required this.baseButtonHeight,
    required this.gap,
    required this.totalWidth,
    required this.totalHeight,
  });
} 