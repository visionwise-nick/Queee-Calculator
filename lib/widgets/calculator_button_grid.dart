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
          child: _buildGrid(layout, provider),
        );
      },
    );
  }

  Widget _buildGrid(CalculatorLayout layout, CalculatorProvider provider) {
    // 创建网格
    List<List<Widget?>> grid = List.generate(
      layout.rows,
      (index) => List.filled(layout.columns, null),
    );

    // 将按钮放置到网格中
    for (final button in layout.buttons) {
      final position = button.gridPosition;
      
      // 检查位置是否有效
      if (position.row < layout.rows && position.column < layout.columns) {
        final buttonWidget = CalculatorButtonWidget(
          button: button,
          onPressed: () => provider.executeAction(button.action),
        );
        
        // 处理跨列的按钮（如 0 按钮）
        if (button.isWide && position.columnSpan != null) {
          // 占据多个列位置
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

    // 计算动态按钮高度 - 根据行数调整
    double buttonHeight = 70.0; // 基础高度
    if (layout.rows > 6) {
      // 如果超过6行，动态缩小按钮高度
      buttonHeight = 400.0 / (layout.rows - 1); // 减去显示屏行
      buttonHeight = buttonHeight.clamp(45.0, 70.0); // 最小45px，最大70px
    }

    return Column(
      children: List.generate(layout.rows, (rowIndex) {
        // 跳过显示区域占用的行
        if (rowIndex == 0) {
          return const SizedBox.shrink();
        }
        
        return Container(
          height: buttonHeight,
          child: Row(
            children: List.generate(layout.columns, (colIndex) {
              final widget = grid[rowIndex][colIndex];
              
              if (widget == null) {
                return const Expanded(child: SizedBox());
              }
              
              // 检查是否是宽按钮
              final button = _findButtonAt(layout.buttons, rowIndex, colIndex);
              if (button != null && button.isWide && button.gridPosition.columnSpan != null) {
                return Expanded(
                  flex: button.gridPosition.columnSpan!,
                  child: widget,
                );
              }
              
              return Expanded(child: widget);
            }),
          ),
        );
      }),
    );
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