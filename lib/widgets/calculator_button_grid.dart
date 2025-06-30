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
              child: _buildScrollableGrid(layout, provider, constraints, theme),
            );
          },
        );
      },
    );
  }

  /// 计算网格内边距
  double _calculatePadding(BoxConstraints constraints, CalculatorTheme theme) {
    if (theme.buttonSpacing != null) {
      return theme.buttonSpacing! * 1.5;
    }
    
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    if (screenArea > 300000) return 8.0;
    if (screenArea > 150000) return 6.0;
    return 4.0;
  }

  /// 构建可滚动的网格
  Widget _buildScrollableGrid(CalculatorLayout layout, CalculatorProvider provider, BoxConstraints constraints, CalculatorTheme theme) {
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
        rows.add(_buildScrollableRow(rowButtons, layout, provider, buttonSizing, theme, rowIndex, availableWidth));
        
        // 添加行间距（除了最后一行）
        if (i < sortedRowIndices.length - 1) {
          rows.add(SizedBox(height: buttonSizing.gap));
        }
      }
    }

    // 计算总内容高度
    final totalContentHeight = _calculateTotalContentHeight(rows, buttonSizing);
    
    // 如果内容高度超过可用高度，使用垂直滚动
    if (totalContentHeight > availableHeight) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      );
    } else {
      // 如果内容适合，使用普通布局
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rows.map((row) => Expanded(child: row)).toList(),
      );
    }
  }

  /// 构建可滚动的行
  Widget _buildScrollableRow(
    List<CalculatorButton> rowButtons, 
    CalculatorLayout layout, 
    CalculatorProvider provider, 
    ButtonSizing sizing, 
    CalculatorTheme theme, 
    int rowIndex,
    double availableWidth
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
    
    final rowHeight = sizing.baseButtonHeight * maxHeightMultiplier;
    
    // 计算行的总宽度需求
    double totalRowWidth = 0;
    for (final button in rowButtons) {
      totalRowWidth += sizing.baseButtonWidth * button.widthMultiplier;
      if (button != rowButtons.last) {
        totalRowWidth += sizing.gap;
      }
    }
    
    // 构建按钮列表
    List<Widget> rowWidgets = [];
    int currentColumn = 0;
    
    for (final button in rowButtons) {
      // 添加空隙填充
      while (currentColumn < button.gridPosition.column) {
        rowWidgets.add(SizedBox(width: sizing.baseButtonWidth));
        if (currentColumn < button.gridPosition.column - 1 || rowWidgets.isNotEmpty) {
          rowWidgets.add(SizedBox(width: sizing.gap));
        }
        currentColumn++;
      }
      
      // 添加按钮
      final buttonWidth = sizing.baseButtonWidth * button.widthMultiplier;
      final buttonHeight = sizing.baseButtonHeight * button.heightMultiplier;
      
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
      
      // 添加间距（除了最后一个按钮）
      if (button != rowButtons.last) {
        rowWidgets.add(SizedBox(width: sizing.gap));
      }
      
      currentColumn += button.widthMultiplier.toInt();
    }
    
    // 如果行宽度超过可用宽度，使用水平滚动
    if (totalRowWidth > availableWidth) {
      return Container(
        height: rowHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: rowWidgets,
          ),
        ),
      );
    } else {
      // 如果行适合，使用普通布局
      return Container(
        height: rowHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowWidgets.map((widget) => 
            widget is SizedBox && widget.child is CalculatorButton 
              ? Expanded(child: widget) 
              : widget
          ).toList(),
        ),
      );
    }
  }

  /// 计算总内容高度
  double _calculateTotalContentHeight(List<Widget> rows, ButtonSizing sizing) {
    double totalHeight = 0;
    for (int i = 0; i < rows.length; i++) {
      totalHeight += sizing.baseButtonHeight;
      if (i < rows.length - 1) {
        totalHeight += sizing.gap;
      }
    }
    return totalHeight;
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
    final minSize = layout.minButtonSize ?? 20.0;
    final maxSize = layout.maxButtonSize ?? 100.0;
    
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
    if (area > 300000) return 4.0;
    if (area > 150000) return 3.0; 
    return 2.0;
  }

  /// 构建固定网格（保留原有逻辑作为备用）
  Widget _buildFixedGrid(CalculatorLayout layout, CalculatorProvider provider, ButtonSizing sizing, CalculatorTheme theme) {
    // 原有的固定网格实现...
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.columns,
        childAspectRatio: 1.0,
        crossAxisSpacing: sizing.gap,
        mainAxisSpacing: sizing.gap,
      ),
      itemCount: layout.buttons.length,
             itemBuilder: (context, index) {
         final button = layout.buttons[index];
         return CalculatorButtonWidget(
           button: button,
           onPressed: () => provider.executeAction(button.action),
         );
       },
    );
  }
}

/// 按钮尺寸信息类
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