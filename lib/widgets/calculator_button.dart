import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';

class CalculatorButtonWidget extends StatefulWidget {
  final CalculatorButton button;
  final VoidCallback onPressed;

  const CalculatorButtonWidget({
    super.key,
    required this.button,
    required this.onPressed,
  });

  @override
  State<CalculatorButtonWidget> createState() => _CalculatorButtonWidgetState();
}

class _CalculatorButtonWidgetState extends State<CalculatorButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final buttonColor = provider.getButtonBackgroundColor(widget.button);
        final textColor = provider.getButtonTextColor(widget.button);
        final theme = provider.config.theme;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTapDown: (_) {
                      setState(() => _isPressed = true);
                      _animationController.forward();
                    },
                    onTapUp: (_) {
                      setState(() => _isPressed = false);
                      _animationController.reverse();
                      widget.onPressed();
                    },
                    onTapCancel: () {
                      setState(() => _isPressed = false);
                      _animationController.reverse();
                    },
                    borderRadius: BorderRadius.circular(theme.buttonBorderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(theme.buttonBorderRadius),
                        boxShadow: theme.hasGlowEffect
                            ? [
                                BoxShadow(
                                                                     color: buttonColor.withValues(alpha: 0.3),
                                  blurRadius: _isPressed ? 15 : 8,
                                  spreadRadius: _isPressed ? 3 : 1,
                                ),
                              ]
                            : [
                                BoxShadow(
                                                                     color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                        gradient: _isPressed
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                                                     buttonColor.withValues(alpha: 0.8),
                                  buttonColor,
                                ],
                              )
                            : null,
                      ),
                      child: Center(
                        child: _buildButtonContent(textColor, theme),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButtonContent(Color textColor, CalculatorTheme theme) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        // 根据布局行数动态调整字体大小
        final layout = provider.config.layout;
        double adjustedFontSize = _getButtonFontSize(theme.fontSize, layout.rows);
        
        // 显示文字
        return Text(
          widget.button.label,
          style: TextStyle(
            fontSize: adjustedFontSize,
            fontWeight: _getButtonFontWeight(),
            color: textColor,
            // fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  /// 获取图标数据
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'backspace':
        return Icons.backspace_outlined;
      case 'clear':
        return Icons.clear;
      case 'equals':
        return Icons.drag_handle;
      default:
        return Icons.help_outline;
    }
  }

  /// 获取按钮字体大小 - 根据行数动态调整
  double _getButtonFontSize(double baseFontSize, int totalRows) {
    // 根据总行数调整基础字体大小
    double adjustedBase = baseFontSize;
    if (totalRows > 6) {
      // 当行数超过6时，缩小字体
      double scaleFactor = 6.0 / totalRows;
      adjustedBase = baseFontSize * scaleFactor;
      adjustedBase = adjustedBase.clamp(12.0, baseFontSize); // 最小12px
    }
    
    // 根据按钮类型进一步调整
    switch (widget.button.type) {
      case ButtonType.operator:
        return adjustedBase + 2; // 减少额外增量
      case ButtonType.secondary:
        return adjustedBase - 1; // 减少缩减量
      default:
        return adjustedBase;
    }
  }

  /// 获取按钮字体粗细
  FontWeight _getButtonFontWeight() {
    switch (widget.button.type) {
      case ButtonType.operator:
        return FontWeight.w400;
      case ButtonType.secondary:
        return FontWeight.w500;
      default:
        return FontWeight.w300;
    }
  }
} 