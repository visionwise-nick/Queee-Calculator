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
            // 🔧 新增：严格边界检查
            final safeConstraints = BoxConstraints(
              maxWidth: math.max(constraints.maxWidth, 200), // 最小宽度保护
              maxHeight: math.max(constraints.maxHeight, 200), // 最小高度保护
            );
            
            return Container(
              width: safeConstraints.maxWidth,
              height: safeConstraints.maxHeight,
              padding: EdgeInsets.all(_calculateSafePadding(safeConstraints)),
              child: _buildSafeGrid(layout, provider, safeConstraints, theme),
            );
          },
        );
      },
    );
  }

  /// 🔧 改进：计算安全的内边距
  double _calculateSafePadding(BoxConstraints constraints) {
    // 根据屏幕大小调整边距，确保不会过大
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    final paddingRatio = screenArea > 500000 ? 0.02 : (screenArea > 200000 ? 0.015 : 0.01);
    final calculatedPadding = math.sqrt(screenArea) * paddingRatio;
    
    // 限制padding在合理范围内
    return calculatedPadding.clamp(4.0, 16.0);
  }

  /// 🔧 新增：构建安全的网格布局
  Widget _buildSafeGrid(CalculatorLayout layout, CalculatorProvider provider, BoxConstraints constraints, CalculatorTheme theme) {
    final padding = _calculateSafePadding(constraints);
    final availableWidth = constraints.maxWidth - (padding * 2);
    final availableHeight = constraints.maxHeight - (padding * 2);
    
    // 边界检查：确保有足够的空间
    if (availableWidth < 100 || availableHeight < 100) {
      return _buildFallbackGrid(layout, provider, theme);
    }
    
    // 按行分组按钮
    Map<int, List<CalculatorButton>> buttonsByRow = {};
    for (final button in layout.buttons) {
      final row = button.gridPosition.row;
      buttonsByRow.putIfAbsent(row, () => []).add(button);
    }
    
    final sortedRows = buttonsByRow.keys.toList()..sort();
    final rowCount = sortedRows.length;
    
    if (rowCount == 0) return Container();
    
    // 🔧 改进：计算安全的按钮间距
    final buttonGap = _calculateSafeButtonGap(availableWidth, availableHeight, layout.columns, rowCount);
    
    // 🔧 改进：计算安全的行高
    final totalGapHeight = buttonGap * math.max(0, rowCount - 1);
    final availableButtonHeight = availableHeight - totalGapHeight;
    final baseRowHeight = math.max(20.0, availableButtonHeight / rowCount); // 最小行高保护
    
    // 构建行
    List<Widget> rows = [];
    for (int i = 0; i < sortedRows.length; i++) {
      final rowIndex = sortedRows[i];
      final rowButtons = buttonsByRow[rowIndex] ?? [];
      
      if (rowButtons.isNotEmpty) {
        final rowWidget = _buildSafeRow(
          rowButtons, 
          layout, 
          provider, 
          availableWidth, 
          baseRowHeight, 
          buttonGap,
          theme
        );
        
        rows.add(rowWidget);
        
        // 添加行间距（除了最后一行）
        if (i < sortedRows.length - 1) {
          rows.add(SizedBox(height: buttonGap));
        }
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rows,
    );
  }

  /// 🔧 新增：计算安全的按钮间距
  double _calculateSafeButtonGap(double width, double height, int columns, int rows) {
    // 根据屏幕大小和按钮数量计算合理的间距
    final screenArea = width * height;
    final totalButtons = columns * rows;
    
    // 基础间距
    double baseGap = 4.0;
    if (screenArea > 500000) baseGap = 8.0;
    else if (screenArea > 200000) baseGap = 6.0;
    
    // 根据按钮密度调整
    if (totalButtons > 20) baseGap = math.max(2.0, baseGap * 0.7);
    else if (totalButtons > 15) baseGap = math.max(3.0, baseGap * 0.85);
    
    // 确保间距不会占用过多空间
    final maxGapWidth = width * 0.05; // 最多占用5%的宽度
    final maxGapHeight = height * 0.05; // 最多占用5%的高度
    
    return math.min(baseGap, math.min(maxGapWidth, maxGapHeight));
  }

  /// 🔧 新增：构建安全的行布局
  Widget _buildSafeRow(
    List<CalculatorButton> rowButtons,
    CalculatorLayout layout,
    CalculatorProvider provider,
    double availableWidth,
    double baseRowHeight,
    double buttonGap,
    CalculatorTheme theme
  ) {
    // 按列位置排序
    rowButtons.sort((a, b) => a.gridPosition.column.compareTo(b.gridPosition.column));
    
    // 计算这一行的最大高度倍数
    double maxHeightMultiplier = 1.0;
    for (final button in rowButtons) {
      if (button.heightMultiplier > maxHeightMultiplier) {
        maxHeightMultiplier = button.heightMultiplier;
      }
    }
    
    // 🔧 改进：限制行高，避免过高
    final rowHeight = math.min(
      baseRowHeight * maxHeightMultiplier,
      availableWidth * 0.3 // 行高不超过可用宽度的30%
    );
    
    // 🔧 改进：计算总的所需宽度并进行约束
    final totalRequiredWidth = _calculateTotalRequiredWidth(rowButtons, layout, buttonGap);
    
    // 如果总宽度超出可用宽度，需要缩放
    double widthScale = 1.0;
    if (totalRequiredWidth > availableWidth) {
      widthScale = availableWidth / totalRequiredWidth;
    }
    
    // 🔧 改进：安全的按钮宽度计算
    final scaledButtonGap = buttonGap * widthScale;
    final totalButtonGaps = scaledButtonGap * math.max(0, layout.columns - 1);
    final availableButtonWidth = availableWidth - totalButtonGaps;
    final baseButtonWidth = math.max(20.0, availableButtonWidth / layout.columns); // 最小按钮宽度保护
    
    // 构建按键
    List<Widget> rowWidgets = [];
    Map<int, CalculatorButton> buttonMap = {};
    for (final btn in rowButtons) {
      buttonMap[btn.gridPosition.column] = btn;
    }
    
    int currentColumn = 0;
    bool isFirstWidget = true;
    
    while (currentColumn < layout.columns) {
      final button = buttonMap[currentColumn];
      
      // 添加间距（除了第一个元素）
      if (!isFirstWidget) {
        rowWidgets.add(SizedBox(width: scaledButtonGap));
      }
      
      if (button != null) {
        // 🔧 改进：安全的按键宽度计算
        final columnSpan = button.gridPosition.columnSpan ?? 1;
        final widthMultiplier = button.widthMultiplier;
        
        double buttonWidth;
        
        if (columnSpan > 1) {
          // 跨列按键：基础宽度×列数 + 被跨越的间隙
          buttonWidth = baseButtonWidth * columnSpan + scaledButtonGap * (columnSpan - 1);
        } else {
          // 普通按键：使用宽度倍数
          buttonWidth = baseButtonWidth * widthMultiplier;
        }
        
        // 🔧 新增：按键尺寸最终约束
        buttonWidth = math.max(20.0, math.min(buttonWidth, availableWidth * 0.8));
        final constrainedRowHeight = math.max(20.0, math.min(rowHeight, availableWidth * 0.2));
        
        rowWidgets.add(
          SizedBox(
            width: buttonWidth,
            height: constrainedRowHeight,
            child: CalculatorButtonWidget(
              button: button,
              onPressed: () => provider.executeAction(button!.action),
              fixedSize: Size(buttonWidth, constrainedRowHeight),
            ),
          ),
        );
        
        // 跳过被跨列按键占用的列
        currentColumn += columnSpan;
      } else {
        // 空位置：添加空白占位符
        rowWidgets.add(
          SizedBox(
            width: baseButtonWidth,
            height: rowHeight,
          ),
        );
        currentColumn++;
      }
      
      isFirstWidget = false;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rowWidgets,
    );
  }

  /// 🔧 新增：计算总的所需宽度
  double _calculateTotalRequiredWidth(List<CalculatorButton> rowButtons, CalculatorLayout layout, double buttonGap) {
    // 简化计算：假设每个按钮占用平均宽度
    double totalWidth = 0.0;
    
    for (final button in rowButtons) {
      final columnSpan = button.gridPosition.columnSpan ?? 1;
      final widthMultiplier = button.widthMultiplier;
      totalWidth += columnSpan * widthMultiplier;
    }
    
    // 加上间距
    totalWidth += buttonGap * (layout.columns - 1);
    
    return totalWidth * 50; // 假设平均每个单位宽度为50像素
  }

  /// 🔧 新增：应急备用网格布局
  Widget _buildFallbackGrid(CalculatorLayout layout, CalculatorProvider provider, CalculatorTheme theme) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: layout.buttons.map((button) {
          return SizedBox(
            width: 60,
            height: 40,
            child: CalculatorButtonWidget(
              button: button,
              onPressed: () => provider.executeAction(button.action),
              fixedSize: const Size(60, 40),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 简化的按钮尺寸配置
class ButtonSizing {
  final double baseButtonWidth;
  final double baseButtonHeight; 
  final double gap;
  final double totalWidth;
  final double totalHeight;

  ButtonSizing({
    required this.baseButtonWidth,
    required this.baseButtonHeight,
    required this.gap,
    required this.totalWidth,
    required this.totalHeight,
  });
} 