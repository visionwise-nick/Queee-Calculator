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
      return theme.buttonSpacing! * 1.5; // 减少边距倍数
    }
    
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    if (screenArea > 300000) return 8.0; // 大屏减少边距
    if (screenArea > 150000) return 6.0; // 中屏减少边距
    return 4.0; // 小屏减少边距
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
    
    // 计算实际使用的行数（只计算有按钮的行）
    final usedRows = _getUsedRows(layout);
    final actualRows = math.max(usedRows, 1);
    
    // 计算基础按钮尺寸，预留更多空间给间距
    final totalHorizontalGap = gap * (layout.columns - 1);
    final totalVerticalGap = gap * (actualRows - 1);
    
    final baseButtonWidth = (availableWidth - totalHorizontalGap) / layout.columns;
    final baseButtonHeight = (availableHeight - totalVerticalGap) / actualRows;
    
    // 应用尺寸限制
    final minSize = layout.minButtonSize ?? 20.0; // 降低最小尺寸
    final maxSize = layout.maxButtonSize ?? 100.0; // 降低最大尺寸
    
    // 确保按钮不会太大导致溢出
    final safeWidth = baseButtonWidth.clamp(minSize, math.min(maxSize, availableWidth / layout.columns * 0.9));
    final safeHeight = baseButtonHeight.clamp(minSize, math.min(maxSize, availableHeight / actualRows * 0.9));
    
    // 选择更小的尺寸以确保适配
    final finalSize = math.min(safeWidth, safeHeight).toDouble();
    
    return ButtonSizing(
      baseButtonWidth: finalSize,
      baseButtonHeight: finalSize,
      gap: gap,
      totalWidth: availableWidth,
      totalHeight: availableHeight,
    );
  }

  /// 获取实际使用的行数
  int _getUsedRows(CalculatorLayout layout) {
    Set<int> usedRows = {};
    for (final button in layout.buttons) {
      usedRows.add(button.gridPosition.row);
    }
    return usedRows.length;
  }

  /// 计算按钮间距
  double _calculateGap(double width, double height) {
    final area = width * height;
    if (area > 300000) return 4.0; // 进一步减小间距
    if (area > 150000) return 3.0; 
    return 2.0; // 小屏使用更紧凑间距
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
    final sortedRowIndices = buttonsByRow.keys.toList()..sort();
    
    for (int i = 0; i < sortedRowIndices.length; i++) {
      final rowIndex = sortedRowIndices[i];
      final rowButtons = buttonsByRow[rowIndex] ?? [];
      
      if (rowButtons.isNotEmpty) {
        rows.add(_buildAdaptiveRow(rowButtons, layout, provider, sizing, theme, rowIndex));
        
        // 添加行间距（除了最后一行）
        if (i < sortedRowIndices.length - 1) {
          rows.add(SizedBox(height: sizing.gap));
        }
      }
    }

    // 使用安全的布局，防止溢出，增加滚动支持
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = rows.length > 0 
            ? (sizing.baseButtonHeight * rows.length) + (sizing.gap * (rows.length - 1))
            : sizing.baseButtonHeight;
            
        // 增强滚动支持，提供更好的用户体验
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (totalHeight > constraints.maxHeight) ...[
              // 如果内容超出高度，使用滚动视图
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), // 弹性滚动效果
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: rows,
                  ),
                ),
              ),
            ] else ...[
              // 如果内容适合，仍然提供滚动能力以防万一
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // 限制滚动范围
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rows,
                  ),
                ),
              ),
            ],
          ],
        );
      },
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
        rowWidgets.add(
          Flexible(
            child: SizedBox(
              width: sizing.baseButtonWidth,
              height: rowHeight,
            ),
          ),
        );
        currentColumn++;
      }
      
      // 计算按钮实际尺寸，确保不超出可用空间
      final buttonWidth = math.min(
        sizing.baseButtonWidth * button.widthMultiplier,
        sizing.totalWidth / layout.columns * 0.95, // 限制最大宽度
      );
      final buttonHeight = math.min(
        sizing.baseButtonHeight * button.heightMultiplier,
        rowHeight,
      );
      
      // 创建按钮
      rowWidgets.add(
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: buttonWidth,
              maxHeight: buttonHeight,
              minWidth: sizing.baseButtonWidth * 0.8, // 最小宽度
              minHeight: sizing.baseButtonHeight * 0.8, // 最小高度
            ),
            child: CalculatorButtonWidget(
              button: button,
              onPressed: () => provider.executeAction(button.action),
              fixedSize: Size(buttonWidth, buttonHeight),
            ),
          ),
        ),
      );
      
      currentColumn++;
    }
    
    // 填充剩余空间
    while (currentColumn < layout.columns) {
      rowWidgets.add(
        Flexible(
          child: SizedBox(
            width: sizing.baseButtonWidth,
            height: rowHeight,
          ),
        ),
      );
      currentColumn++;
    }

    return Container(
      height: rowHeight,
      margin: EdgeInsets.symmetric(horizontal: 4.0), // 添加水平边距
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