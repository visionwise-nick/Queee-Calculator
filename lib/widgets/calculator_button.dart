import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import 'dart:convert';

class CalculatorButtonWidget extends StatefulWidget {
  final CalculatorButton button;
  final VoidCallback onPressed;
  final Size? fixedSize;

  const CalculatorButtonWidget({
    super.key,
    required this.button,
    required this.onPressed,
    this.fixedSize,
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
        final buttonColor = _getButtonColor(provider.config.theme);
        final textColor = _getButtonTextColor(provider.config.theme);
        final theme = provider.config.theme;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.fixedSize != null 
                ? SizedBox(
                    width: widget.fixedSize!.width,
                    height: widget.fixedSize!.height,
                    child: _buildButtonContainer(buttonColor, textColor, theme),
                  )
                : Container(
                    margin: const EdgeInsets.all(2),
                    child: _buildButtonContainer(buttonColor, textColor, theme),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildButtonContainer(Color buttonColor, Color textColor, CalculatorTheme theme) {
    final gradient = _getButtonGradient(theme);
    final backgroundImage = widget.button.backgroundImage;
    
    // 使用按钮独立属性或主题默认值
    final borderRadius = widget.button.borderRadius ?? theme.buttonBorderRadius;
    final elevation = widget.button.elevation ?? theme.buttonElevation ?? 2.0;
    
    // 新增：支持独立的背景色和文字颜色
    final finalButtonColor = widget.button.backgroundColor != null 
        ? _parseColor(widget.button.backgroundColor!) 
        : buttonColor;
    final finalTextColor = widget.button.textColor != null 
        ? _parseColor(widget.button.textColor!) 
        : textColor;
    
    // 构建主容器
    Widget buttonWidget = Container(
      margin: widget.fixedSize != null ? EdgeInsets.zero : const EdgeInsets.all(2),
      width: widget.button.width,
      height: widget.button.height,
      child: Material(
        color: Colors.transparent,
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
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
          onLongPress: () {
            _showButtonDescription(context);
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            decoration: _buildButtonDecoration(finalButtonColor, theme, gradient, backgroundImage, borderRadius, elevation),
            child: Center(
              child: _buildButtonContent(finalTextColor, theme),
            ),
          ),
        ),
      ),
    );

    // 应用变换效果
    if (widget.button.rotation != null || widget.button.scale != null) {
      buttonWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ((widget.button.rotation ?? 0) * 3.14159 / 180)
          ..scale(widget.button.scale ?? 1.0),
        child: buttonWidget,
      );
    }

    // 应用透明度
    if (widget.button.opacity != null) {
      buttonWidget = Opacity(
        opacity: widget.button.opacity!.clamp(0.0, 1.0),
        child: buttonWidget,
      );
    }

    // 应用动画效果
    if (widget.button.animation != null) {
      buttonWidget = _buildAnimatedButton(buttonWidget);
    }

    return buttonWidget;
  }

  /// 构建按钮装饰
  BoxDecoration _buildButtonDecoration(
    Color buttonColor, 
    CalculatorTheme theme, 
    List<String>? gradient, 
    String? backgroundImage, 
    double borderRadius, 
    double elevation
  ) {
    return BoxDecoration(
      color: gradient == null && backgroundImage == null ? buttonColor : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: widget.button.borderColor != null && widget.button.borderWidth != null
          ? Border.all(
              color: _parseColor(widget.button.borderColor!),
              width: widget.button.borderWidth!,
            )
          : null,
      boxShadow: _buildEnhancedBoxShadow(theme, buttonColor, elevation),
      gradient: gradient != null ? _buildGradient(gradient) : (_isPressed
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                buttonColor.withValues(alpha: 0.8),
                buttonColor,
              ],
            )
          : null),
      image: _buildBackgroundImage(backgroundImage),
    );
  }

  /// 构建增强的阴影效果
  List<BoxShadow> _buildEnhancedBoxShadow(CalculatorTheme theme, Color buttonColor, double elevation) {
    // 优先使用按钮独立的阴影设置
    if (widget.button.shadowColor != null && widget.button.shadowRadius != null) {
      return [
        BoxShadow(
          color: _parseColor(widget.button.shadowColor!),
          offset: Offset(
            widget.button.shadowOffset?['x'] ?? 0,
            widget.button.shadowOffset?['y'] ?? 2,
          ),
          blurRadius: widget.button.shadowRadius!,
        ),
      ];
    }
    
    // 使用原有的阴影逻辑
    if (theme.hasGlowEffect) {
      return [
        BoxShadow(
          color: buttonColor.withValues(alpha: 0.3),
          blurRadius: _isPressed ? 15 : 8,
          spreadRadius: _isPressed ? 3 : 1,
        ),
      ];
    } else if (theme.buttonShadowColors != null) {
      return theme.buttonShadowColors!.map((color) => BoxShadow(
        color: _parseColor(color),
        blurRadius: elevation,
        offset: const Offset(0, 2),
      )).toList();
    } else {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }

  /// 构建背景图像
  DecorationImage? _buildBackgroundImage(String? backgroundImage) {
    if (backgroundImage != null) {
      // 过滤掉明显无效的URL格式
      if (backgroundImage.startsWith('url(') && backgroundImage.endsWith(')')) {
        // 这是CSS样式的url()格式，不是有效的图片URL
        print('跳过无效的CSS格式按钮背景图片: $backgroundImage');
        return null;
      }

      if (backgroundImage.startsWith('data:image/')) {
        // 处理base64格式
        try {
          final base64Data = backgroundImage.split(',').last;
          final bytes = base64Decode(base64Data);
          return DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
          );
        } catch (e) {
          print('Failed to decode base64 button background image: $e');
          return null;
        }
      } else if (Uri.tryParse(backgroundImage)?.isAbsolute == true) {
        // 处理有效的URL格式
        return DecorationImage(
          image: NetworkImage(backgroundImage),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print('Failed to load button background image: $backgroundImage');
          },
        );
      } else {
        // 跳过无效格式
        print('跳过无效格式的按钮背景图片: $backgroundImage');
        return null;
      }
    }
    
    // 检查是否有背景图案
    if (widget.button.backgroundPattern != null) {
      return DecorationImage(
        image: _generatePatternImage(widget.button.backgroundPattern!),
        fit: BoxFit.cover,
        opacity: widget.button.patternOpacity ?? 0.3,
      );
    }
    
    return null;
  }

  /// 生成图案图像
  ImageProvider _generatePatternImage(String pattern) {
    // 根据图案类型生成相应的图案URL
    final patternColor = widget.button.patternColor ?? 'CCCCCC';
    final backgroundColor = 'FFFFFF';
    
    switch (pattern.toLowerCase()) {
      case 'dots':
        return NetworkImage('https://via.placeholder.com/100x100/$patternColor/$backgroundColor?text=•••');
      case 'stripes':
        return NetworkImage('https://via.placeholder.com/100x100/$patternColor/$backgroundColor?text=|||');
      case 'grid':
        return NetworkImage('https://via.placeholder.com/100x100/$patternColor/$backgroundColor?text=###');
      case 'waves':
        return NetworkImage('https://via.placeholder.com/100x100/$patternColor/$backgroundColor?text=~~~');
      default:
        return NetworkImage('https://via.placeholder.com/100x100/$patternColor/$backgroundColor?text=Pattern');
    }
  }

  /// 构建动画按钮
  Widget _buildAnimatedButton(Widget child) {
    if (widget.button.animation == null) return child;
    
    switch (widget.button.animation!.toLowerCase()) {
      case 'bounce':
        return _BounceAnimation(
          duration: Duration(milliseconds: ((widget.button.animationDuration ?? 1.0) * 1000).round()),
          child: child,
        );
      case 'pulse':
        return _PulseAnimation(
          duration: Duration(milliseconds: ((widget.button.animationDuration ?? 2.0) * 1000).round()),
          child: child,
        );
      case 'glow':
        return _GlowAnimation(
          duration: Duration(milliseconds: ((widget.button.animationDuration ?? 1.5) * 1000).round()),
          child: child,
        );
      default:
        return child;
    }
  }

  Widget _buildButtonContent(Color textColor, CalculatorTheme theme) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        // 使用按钮独立字体大小或根据布局动态调整
        final layout = provider.config.layout;
        double fontSize = widget.button.fontSize ?? _getButtonFontSize(theme.fontSize, layout.rows);
        
        // 显示文字
        return Text(
          widget.button.label,
          style: TextStyle(
            fontSize: fontSize,
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
      adjustedBase = adjustedBase.clamp(10.0, baseFontSize); // 最小10px
    }
    
    // 根据按钮类型进一步调整
    switch (widget.button.type) {
      case ButtonType.operator:
        return adjustedBase + 1; // 减少额外增量
      case ButtonType.secondary:
        return adjustedBase - 0.5; // 减少缩减量
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

  /// 获取按钮颜色
  Color _getButtonColor(CalculatorTheme theme) {
    // 如果按钮有自定义颜色，优先使用
    if (widget.button.customColor != null) {
      return _parseColor(widget.button.customColor!);
    }
    
    // 根据按钮类型获取颜色
    switch (widget.button.type) {
      case 'operator':
        return _parseColor(theme.operatorButtonColor);
      case 'secondary':
        return _parseColor(theme.secondaryButtonColor);
      default:
        return _parseColor(theme.primaryButtonColor);
    }
  }

  /// 获取按钮渐变色
  List<String>? _getButtonGradient(CalculatorTheme theme) {
    // 如果按钮有自定义渐变，优先使用
    if (widget.button.gradientColors != null) {
      return widget.button.gradientColors;
    }
    
    // 根据按钮类型获取渐变
    switch (widget.button.type) {
      case 'operator':
        return theme.operatorButtonGradient;
      case 'secondary':
        return theme.secondaryButtonGradient;
      default:
        return theme.primaryButtonGradient;
    }
  }

  /// 获取按钮文字颜色
  Color _getButtonTextColor(CalculatorTheme theme) {
    switch (widget.button.type) {
      case 'operator':
        return _parseColor(theme.operatorButtonTextColor);
      case 'secondary':
        return _parseColor(theme.secondaryButtonTextColor);
      default:
        return _parseColor(theme.primaryButtonTextColor);
    }
  }

  Color _parseColor(String colorString) {
    // 移除 # 号（如果存在）
    final cleanColor = colorString.replaceAll('#', '');
    
    // 支持 RGB 和 RGBA 格式
    if (cleanColor.length == 6) {
      return Color(int.parse('FF$cleanColor', radix: 16));
    } else if (cleanColor.length == 8) {
      return Color(int.parse(cleanColor, radix: 16));
    } else {
      // 返回默认颜色
      return Colors.grey;
    }
  }

  /// 构建渐变色
  LinearGradient _buildGradient(List<String> gradientColors) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors.map((color) => _parseColor(color)).toList(),
    );
  }

  /// 显示按钮功能介绍
  void _showButtonDescription(BuildContext context) {
    final description = _getButtonDescription(widget.button);
    if (description.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getButtonColor(Provider.of<CalculatorProvider>(context, listen: false).config.theme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.button.label,
                    style: TextStyle(
                      color: _getButtonTextColor(Provider.of<CalculatorProvider>(context, listen: false).config.theme),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '按键功能',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              if (widget.button.action.expression != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '表达式：',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.button.action.expression!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '知道了',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 获取按钮功能描述
  String _getButtonDescription(CalculatorButton button) {
    switch (button.action.type) {
      case 'input':
        return '输入数字 "${button.action.value}"';
      case 'operator':
        final operatorNames = {
          '+': '加法',
          '-': '减法',
          '*': '乘法',
          '/': '除法',
        };
        return '执行${operatorNames[button.action.value] ?? button.action.value}运算';
      case 'equals':
        return '计算并显示结果';
      case 'clear':
        return '清除当前显示的数字';
      case 'clearAll':
        return '清除所有数据，重置计算器';
      case 'backspace':
        return '删除最后输入的一位数字';
      case 'decimal':
        return '输入小数点';
      case 'negate':
        return '切换当前数字的正负号';
      case 'expression':
        if (button.action.expression != null) {
          return _getExpressionDescription(button.action.expression!);
        }
        return '执行特殊计算功能';
      default:
        return '执行 ${button.label} 功能';
    }
  }

  /// 获取表达式功能描述
  String _getExpressionDescription(String expression) {
    final descriptions = {
      'x*x': '计算当前数字的平方',
      'sqrt(x)': '计算当前数字的平方根',
      'pow(x,3)': '计算当前数字的立方',
      '1/x': '计算当前数字的倒数',
      'sin(x)': '计算当前数字的正弦值',
      'cos(x)': '计算当前数字的余弦值',
      'tan(x)': '计算当前数字的正切值',
      'log(x)': '计算当前数字的自然对数',
      'exp(x)': '计算e的当前数字次方',
      'x*0.15': '计算15%的小费',
      'x*0.18': '计算18%的小费',
      'x*0.20': '计算20%的小费',
      'x*1.13': '计算含税价格（13%税率）',
      'x*0.8': '计算80%折扣价',
      'x*9/5+32': '将摄氏度转换为华氏度',
      'x*2.54': '将英寸转换为厘米',
      'x*0.01': '计算百分比（除以100）',
    };
    
    return descriptions[expression] ?? '使用表达式 "$expression" 进行计算';
  }
}

/// 弹跳动画组件
class _BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _BounceAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<_BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 脉冲动画组件
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _PulseAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 发光动画组件
class _GlowAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _GlowAnimation({
    required this.child,
    required this.duration,
  });

  @override
  State<_GlowAnimation> createState() => _GlowAnimationState();
}

class _GlowAnimationState extends State<_GlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(_animation.value * 0.5),
                blurRadius: 10 + (_animation.value * 10),
                spreadRadius: _animation.value * 5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
} 