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
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: _buildFlexibleGrid(layout, provider),
        );
      },
    );
  }

  /// 构建灵活的网格布局
  Widget _buildFlexibleGrid(CalculatorLayout layout, CalculatorProvider provider) {
    // 如果布局很简单，使用传统网格
    if (_isSimpleGrid(layout)) {
      return _buildTraditionalGrid(layout, provider);
    }
    
    // 否则使用更灵活的Stack+Positioned布局
    return _buildStackLayout(layout, provider);
  }
  
  /// 判断是否为简单网格布局
  bool _isSimpleGrid(CalculatorLayout layout) {
    // 检查是否所有按钮都在标准网格位置
    for (final button in layout.buttons) {
      final pos = button.gridPosition;
      if (pos.row >= layout.rows || pos.column >= layout.columns) {
        return false;
      }
      // 如果有复杂的跨行跨列，使用Stack布局
      if ((pos.rowSpan != null && pos.rowSpan! > 1) ||
          (pos.columnSpan != null && pos.columnSpan! > 2)) {
        return false;
      }
    }
    return true;
  }
  
  /// 构建传统网格布局（优化版）
  Widget _buildTraditionalGrid(CalculatorLayout layout, CalculatorProvider provider) {
    // 创建网格矩阵
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
          onPressed: () => provider.executeButtonAction(button.id),
        );
        
        // 处理跨列按钮
        if (button.isWide && position.columnSpan != null && position.columnSpan! > 1) {
          grid[position.row][position.column] = buttonWidget;
          for (int i = 1; i < position.columnSpan!; i++) {
            if (position.column + i < layout.columns) {
              grid[position.row][position.column + i] = const SizedBox.shrink();
            }
          }
        } else {
          grid[position.row][position.column] = buttonWidget;
        }
      }
    }

    return Column(
      children: _buildGridRows(grid, layout, provider),
    );
  }
  
  /// 构建Stack布局（支持任意位置）
  Widget _buildStackLayout(CalculatorLayout layout, CalculatorProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / layout.columns;
        final cellHeight = (constraints.maxHeight - 
            (layout.hasDisplay ? 100 : 0)) / (layout.rows - (layout.hasDisplay ? 1 : 0));
        
        List<Widget> stackChildren = [];
        
        for (final button in layout.buttons) {
          final pos = button.gridPosition;
          
          // 计算按钮的实际位置和尺寸
          final left = pos.column * cellWidth;
          final top = (pos.row - (layout.hasDisplay ? 1 : 0)) * cellHeight;
          final width = cellWidth * (pos.columnSpan ?? 1);
          final height = cellHeight * (pos.rowSpan ?? 1);
          
          stackChildren.add(
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CalculatorButtonWidget(
                  button: button,
                  onPressed: () => provider.executeButtonAction(button.id),
                ),
              ),
            ),
          );
        }
        
        return Stack(children: stackChildren);
      },
    );
  }
  
  /// 构建网格行
  List<Widget> _buildGridRows(List<List<Widget?>> grid, CalculatorLayout layout, CalculatorProvider provider) {
    List<Widget> rows = [];
    
    for (int rowIndex = 0; rowIndex < layout.rows; rowIndex++) {
      // 跳过显示区域
      if (rowIndex == 0 && layout.hasDisplay) {
        continue;
      }
      
      rows.add(
        Expanded(
          child: Row(
            children: _buildRowWidgets(grid[rowIndex], layout.buttons, rowIndex),
          ),
        ),
      );
    }
    
    return rows;
  }

  /// 构建行的小部件列表，正确处理跨列按钮
  List<Widget> _buildRowWidgets(List<Widget?> rowWidgets, List<CalculatorButton> buttons, int rowIndex) {
    List<Widget> result = [];
    
    for (int colIndex = 0; colIndex < rowWidgets.length; colIndex++) {
      final widget = rowWidgets[colIndex];
      
      if (widget == null) {
        result.add(const Expanded(child: SizedBox()));
        continue;
      }
      
      // 检查是否是 SizedBox.shrink（被跨列按钮占用的位置）
      if (widget is SizedBox && widget.width == 0.0 && widget.height == 0.0) {
        continue;
      }
      
      // 检查是否是宽按钮
      final button = _findButtonAt(buttons, rowIndex, colIndex);
      if (button != null && button.isWide && button.gridPosition.columnSpan != null && button.gridPosition.columnSpan! > 1) {
        result.add(Expanded(
          flex: button.gridPosition.columnSpan!,
          child: widget,
        ));
      } else {
        result.add(Expanded(child: widget));
      }
    }
    
    return result;
  }

  /// 查找指定位置的按钮
  CalculatorButton? _findButtonAt(List<CalculatorButton> buttons, int row, int col) {
    for (final button in buttons) {
      if (button.gridPosition.row == row && button.gridPosition.column == col) {
        return button;
      }
    }
    return null;
  }
} 