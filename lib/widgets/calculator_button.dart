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
        final buttonColor = provider.getButtonColor(widget.button);
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
    // 如果有图标，显示图标
    if (widget.button.icon != null) {
      return Icon(
        _getIconData(widget.button.icon!),
        color: textColor,
        size: theme.fontSize,
      );
    }

    // 否则显示文字
    return Text(
      widget.button.label,
      style: TextStyle(
        fontSize: _getButtonFontSize(theme.fontSize),
        fontWeight: _getButtonFontWeight(),
        color: textColor,
        fontFamily: theme.fontFamily,
      ),
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

  /// 获取按钮字体大小
  double _getButtonFontSize(double baseFontSize) {
    switch (widget.button.type) {
      case ButtonType.operator:
        return baseFontSize + 4;
      case ButtonType.secondary:
        return baseFontSize - 2;
      default:
        return baseFontSize;
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