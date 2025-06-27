import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import 'calculator_button.dart';

class CalculatorButtonGrid extends StatelessWidget {
  const CalculatorButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final layout = provider.config.layout;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: EdgeInsets.all(_calculatePadding(constraints)),
              child: _buildAdaptiveGrid(layout, provider, constraints),
            );
          },
        );
      },
    );
  }

  /// 计算网格内边距
  double _calculatePadding(BoxConstraints constraints) {
    // 根据屏幕尺寸动态计算padding
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    if (screenArea > 200000) return 12.0; // 大屏
    if (screenArea > 100000) return 8.0;  // 中屏
    return 4.0; // 小屏
  }

  /// 构建自适应网格
  Widget _buildAdaptiveGrid(CalculatorLayout layout, CalculatorProvider provider, BoxConstraints constraints) {
    // 计算可用空间
    final padding = _calculatePadding(constraints);
    final availableWidth = constraints.maxWidth - (padding * 2);
    final availableHeight = constraints.maxHeight - (padding * 2);
    
    // 计算最优按钮尺寸
    final buttonSizing = _calculateOptimalButtonSize(
      layout, 
      availableWidth, 
      availableHeight
    );
    
    // 创建网格
    List<List<Widget?>> grid = List.generate(
      layout.rows,
      (index) => List.filled(layout.columns, null),
    );

    // 将按钮放置到网格中
    for (final button in layout.buttons) {
      final position = button.gridPosition;
      
      if (position.row < layout.rows && position.column < layout.columns) {
        final buttonWidget = CalculatorButtonWidget(
          button: button,
          onPressed: () => provider.executeAction(button.action),
          fixedSize: Size(buttonSizing.buttonWidth, buttonSizing.buttonHeight),
        );
        
        // 处理跨列按钮
        if (button.isWide && position.columnSpan != null) {
          for (int i = 0; i < position.columnSpan!; i++) {
            if (position.column + i < layout.columns) {
              grid[position.row][position.column + i] = i == 0 ? buttonWidget : Container();
            }
          }
        } else {
          grid[position.row][position.column] = buttonWidget;
        }
      }
    }

    // 构建灵活的网格布局
    return _buildFlexibleGrid(grid, layout, buttonSizing);
  }

  /// 计算最优按钮尺寸
  ButtonSizing _calculateOptimalButtonSize(CalculatorLayout layout, double availableWidth, double availableHeight) {
    // 计算按钮间距
    final gap = _calculateGap(availableWidth, availableHeight);
    
    // 计算单个按钮的可用空间
    final buttonWidth = (availableWidth - (gap * (layout.columns - 1))) / layout.columns;
    
    // 跳过显示行（第0行）
    final buttonRows = layout.rows - 1;
    final buttonHeight = (availableHeight - (gap * (buttonRows - 1))) / buttonRows;
    
    // 确保按钮不会太小或太大
    final minSize = 30.0;
    final maxSize = 80.0;
    
    return ButtonSizing(
      buttonWidth: buttonWidth.clamp(minSize, maxSize),
      buttonHeight: buttonHeight.clamp(minSize, maxSize),
      gap: gap,
    );
  }

  /// 计算按钮间距
  double _calculateGap(double width, double height) {
    final area = width * height;
    if (area > 200000) return 6.0; // 大屏更大间距
    if (area > 100000) return 4.0; // 中屏中等间距
    return 2.0; // 小屏紧凑间距
  }

  /// 构建灵活的网格
  Widget _buildFlexibleGrid(List<List<Widget?>> grid, CalculatorLayout layout, ButtonSizing sizing) {
    return Column(
      children: List.generate(layout.rows, (rowIndex) {
        // 跳过显示区域行
        if (rowIndex == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: sizing.buttonHeight,
          margin: EdgeInsets.only(
            bottom: rowIndex < layout.rows - 1 ? sizing.gap : 0,
          ),
          child: Row(
            children: _buildRowWidgets(grid[rowIndex], layout, sizing),
          ),
        );
      }),
    );
  }

  /// 构建行内组件
  List<Widget> _buildRowWidgets(List<Widget?> rowWidgets, CalculatorLayout layout, ButtonSizing sizing) {
    List<Widget> widgets = [];
    
    for (int colIndex = 0; colIndex < layout.columns; colIndex++) {
      final widget = rowWidgets[colIndex];
      
      if (widget == null) {
        // 空位置
        widgets.add(SizedBox(width: sizing.buttonWidth));
      } else if (widget is Container && widget.child == null) {
        // 跨列按钮的占位符，跳过
        continue;
      } else {
        // 检查是否是跨列按钮
        final button = _findButtonAt(layout, colIndex, rowWidgets);
        if (button != null && button.isWide && button.gridPosition.columnSpan != null) {
          final spanWidth = (sizing.buttonWidth * button.gridPosition.columnSpan!) + 
                           (sizing.gap * (button.gridPosition.columnSpan! - 1));
          widgets.add(SizedBox(width: spanWidth, child: widget));
        } else {
          widgets.add(SizedBox(width: sizing.buttonWidth, child: widget));
        }
      }
      
      // 添加列间距（除了最后一列）
      if (colIndex < layout.columns - 1) {
        widgets.add(SizedBox(width: sizing.gap));
      }
    }
    
    return widgets;
  }

  /// 查找指定位置的按钮
  CalculatorButton? _findButtonAt(CalculatorLayout layout, int col, List<Widget?> rowWidgets) {
    // 这里需要根据具体实现来查找按钮
    // 简化版本：通过按钮位置查找
    for (final button in layout.buttons) {
      if (button.gridPosition.column == col) {
        return button;
      }
    }
    return null;
  }
}

/// 按钮尺寸配置
class ButtonSizing {
  final double buttonWidth;
  final double buttonHeight; 
  final double gap;

  const ButtonSizing({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.gap,
  });
} 