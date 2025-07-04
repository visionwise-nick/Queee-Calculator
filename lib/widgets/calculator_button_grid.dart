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
        final theme = provider.config.theme;
        final appBackground = provider.config.appBackground;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // 应用按键透明度
            final buttonOpacity = appBackground?.buttonOpacity ?? 1.0;
            
            return Opacity(
              opacity: buttonOpacity,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                padding: EdgeInsets.all(_calculatePadding(constraints)),
                child: _buildOptimizedGrid(layout, provider, constraints, theme),
              ),
            );
          },
        );
      },
    );
  }

  /// 计算合理的内边距
  double _calculatePadding(BoxConstraints constraints) {
    // 根据屏幕大小调整边距，保持美观但不浪费空间
    final screenArea = constraints.maxWidth * constraints.maxHeight;
    if (screenArea > 500000) return 12.0; // 大屏
    if (screenArea > 200000) return 8.0;  // 中屏
    return 6.0; // 小屏
  }

  /// 构建优化的网格布局
  Widget _buildOptimizedGrid(CalculatorLayout layout, CalculatorProvider provider, BoxConstraints constraints, CalculatorTheme theme) {
    final padding = _calculatePadding(constraints);
    final availableWidth = constraints.maxWidth - (padding * 2);
    final availableHeight = constraints.maxHeight - (padding * 2);
    
    // 按行分组按钮
    Map<int, List<CalculatorButton>> buttonsByRow = {};
    for (final button in layout.buttons) {
      final row = button.gridPosition.row;
      buttonsByRow.putIfAbsent(row, () => []).add(button);
    }
    
    final sortedRows = buttonsByRow.keys.toList()..sort();
    final rowCount = sortedRows.length;
    
    // 计算按钮间距 - 紧凑但美观
    final buttonGap = _calculateButtonGap(availableWidth, availableHeight);
    
    // 计算每行的高度 - 充分利用垂直空间
    final totalGapHeight = buttonGap * (rowCount - 1);
    final availableButtonHeight = availableHeight - totalGapHeight;
    final baseRowHeight = availableButtonHeight / rowCount;
    
    // 构建行
    List<Widget> rows = [];
    for (int i = 0; i < sortedRows.length; i++) {
      final rowIndex = sortedRows[i];
      final rowButtons = buttonsByRow[rowIndex] ?? [];
      
      if (rowButtons.isNotEmpty) {
        rows.add(_buildOptimizedRow(
          rowButtons, 
          layout, 
          provider, 
          availableWidth, 
          baseRowHeight, 
          buttonGap,
          theme
        ));
        
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

  /// 计算按钮间距
  double _calculateButtonGap(double width, double height) {
    // 根据屏幕大小计算合理的按钮间距
    final screenArea = width * height;
    if (screenArea > 500000) return 8.0;  // 大屏适中间距
    if (screenArea > 200000) return 6.0;  // 中屏紧凑间距
    return 4.0; // 小屏最紧凑
  }

  /// 构建优化的行布局
  Widget _buildOptimizedRow(
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
    
    final rowHeight = baseRowHeight * maxHeightMultiplier;
    
    // 计算按钮宽度 - 均匀分布
    final totalButtonGaps = buttonGap * (layout.columns - 1);
    final availableButtonWidth = availableWidth - totalButtonGaps;
    final baseButtonWidth = availableButtonWidth / layout.columns;
    
    // 创建完整的网格行
    List<Widget> rowWidgets = [];
    
    for (int col = 0; col < layout.columns; col++) {
      // 查找当前列的按钮
      CalculatorButton? button;
      for (final btn in rowButtons) {
        if (btn.gridPosition.column == col) {
          button = btn;
          break;
        }
      }
      
      if (button != null) {
        // 🔧 修复：正确计算跨列按键的宽度，包含间隙
        double buttonWidth;
        final columnSpan = button.gridPosition.columnSpan ?? 1;
        
        if (columnSpan > 1) {
          // 跨列按键：基础宽度×列数 + 间隙×(列数-1)
          buttonWidth = baseButtonWidth * columnSpan + buttonGap * (columnSpan - 1);
        } else {
          // 普通按键：使用宽度倍数，同时考虑间隙
          final widthMultiplier = button.widthMultiplier;
          if (widthMultiplier > 1) {
            // 多倍宽度按键：基础宽度×倍数 + 间隙×(倍数-1)
            buttonWidth = baseButtonWidth * widthMultiplier + buttonGap * (widthMultiplier - 1);
          } else {
            // 标准按键：基础宽度
            buttonWidth = baseButtonWidth * widthMultiplier;
          }
        }
        
        rowWidgets.add(
          SizedBox(
            width: buttonWidth,
            height: rowHeight,
            child: CalculatorButtonWidget(
              button: button,
              onPressed: () => provider.executeAction(button!.action),
              fixedSize: Size(buttonWidth, rowHeight),
            ),
          ),
        );
        
        // 🔧 跨列按键和多倍宽度按键跳过被占用的列位置
        if (columnSpan > 1) {
          col += columnSpan - 1; // 跳过被占用的列
        } else if (button.widthMultiplier > 1) {
          // 多倍宽度按键也需要跳过被占用的列
          col += (button.widthMultiplier - 1).round(); // 跳过被占用的列
        }
      } else {
        // 空位置
        rowWidgets.add(
          SizedBox(
            width: baseButtonWidth,
            height: rowHeight,
          ),
        );
      }
      
      // 添加列间距（除了最后一列）
      if (col < layout.columns - 1) {
        rowWidgets.add(SizedBox(width: buttonGap));
      }
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rowWidgets,
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