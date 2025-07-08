import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import 'dart:convert';
import 'dart:math' as math;

// 🔧 新增：全局图片缓存，避免重复解码base64导致闪烁
class _ImageCache {
  static final Map<String, MemoryImage> _cache = {};
  
  static MemoryImage getMemoryImage(String base64Data) {
    if (_cache.containsKey(base64Data)) {
      return _cache[base64Data]!;
    }
    
    try {
      final bytes = base64Decode(base64Data.split(',').last);
      final memoryImage = MemoryImage(bytes);
      _cache[base64Data] = memoryImage;
      return memoryImage;
    } catch (e) {
      throw Exception('Failed to decode base64 image: $e');
    }
  }
  
  static void clearCache() {
    _cache.clear();
  }
}

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
  
  // 🔧 新增：缓存解码后的图片，避免重复解码
  MemoryImage? _cachedMemoryImage;
  String? _lastBackgroundImageData;

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
    
    // 🔧 预加载背景图片
    _preloadBackgroundImage();
  }

  @override
  void didUpdateWidget(CalculatorButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 🔧 检查背景图片是否发生变化，如有变化则重新加载
    if (oldWidget.button.backgroundImage != widget.button.backgroundImage) {
      _preloadBackgroundImage();
    }
  }

  /// 🔧 预加载背景图片，避免重复解码
  void _preloadBackgroundImage() {
    final backgroundImage = widget.button.backgroundImage;
    if (backgroundImage != null && backgroundImage.startsWith('data:image/')) {
      if (_lastBackgroundImageData != backgroundImage) {
        try {
          _cachedMemoryImage = _ImageCache.getMemoryImage(backgroundImage);
          _lastBackgroundImageData = backgroundImage;
        } catch (e) {
          print('Failed to preload background image: $e');
          _cachedMemoryImage = null;
          _lastBackgroundImageData = null;
        }
      }
    } else {
      _cachedMemoryImage = null;
      _lastBackgroundImageData = null;
    }
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
    
    // 新增：计算自适应大小
    final adaptiveSize = _calculateAdaptiveSize(theme);
    
    // 构建主容器
    Widget buttonWidget = Container(
      margin: widget.fixedSize != null ? EdgeInsets.zero : const EdgeInsets.all(2),
      width: adaptiveSize.width,
      height: adaptiveSize.height,
      constraints: _buildSizeConstraints(),
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
            padding: _getContentPadding(),
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

  /// 计算自适应大小
  Size _calculateAdaptiveSize(CalculatorTheme theme) {
    // 如果有固定大小，优先使用
    if (widget.fixedSize != null) {
      return widget.fixedSize!;
    }
    
    // 如果按钮指定了固定宽高，使用指定值
    if (widget.button.width != null && widget.button.height != null) {
      return Size(widget.button.width!, widget.button.height!);
    }
    
    // 获取屏幕信息
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // 默认基础大小（可根据屏幕大小调整）
    double baseWidth = screenWidth * 0.2; // 屏幕宽度的20%
    double baseHeight = screenHeight * 0.08; // 屏幕高度的8%
    
    // 根据按钮类型调整基础大小
    switch (widget.button.type) {
      case 'operator':
        baseWidth *= 0.9; // 运算符按钮稍小
        baseHeight *= 1.1; // 但稍高
        break;
      case 'special':
        baseWidth *= 1.2; // 特殊按钮稍大
        baseHeight *= 0.9;
        break;
      case 'secondary':
        baseWidth *= 0.8; // 次要按钮稍小
        baseHeight *= 0.9;
        break;
    }
    
    // 如果启用自适应大小
    if (widget.button.adaptiveSize == true) {
      final sizeMode = widget.button.sizeMode ?? 'adaptive';
      
      switch (sizeMode) {
        case 'content':
          return _calculateContentBasedSize(baseWidth, baseHeight, theme);
        case 'fill':
          return _calculateFillSize(screenWidth, screenHeight);
        case 'fixed':
          return Size(
            widget.button.width ?? baseWidth,
            widget.button.height ?? baseHeight,
          );
        case 'adaptive':
        default:
          return _calculateAdaptiveBasedSize(baseWidth, baseHeight, theme);
      }
    }
    
    // 应用宽高倍数
    final finalWidth = (widget.button.width ?? baseWidth) * widget.button.widthMultiplier;
    final finalHeight = (widget.button.height ?? baseHeight) * widget.button.heightMultiplier;
    
    // 应用宽高比约束
    if (widget.button.aspectRatio != null) {
      final aspectRatio = widget.button.aspectRatio!;
      if (finalWidth / finalHeight > aspectRatio) {
        // 宽度过大，调整宽度
        return Size(finalHeight * aspectRatio, finalHeight);
      } else {
        // 高度过大，调整高度
        return Size(finalWidth, finalWidth / aspectRatio);
      }
    }
    
    return Size(finalWidth, finalHeight);
  }

  /// 基于内容计算大小
  Size _calculateContentBasedSize(double baseWidth, double baseHeight, CalculatorTheme theme) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.button.label,
        style: TextStyle(
          fontSize: widget.button.fontSize ?? theme.fontSize,
          fontFamily: widget.button.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final contentPadding = _getContentPadding();
    final textWidth = textPainter.width + contentPadding.horizontal;
    final textHeight = textPainter.height + contentPadding.vertical;
    
    // 确保最小大小
    final minWidth = widget.button.minWidth ?? baseWidth * 0.6;
    final minHeight = widget.button.minHeight ?? baseHeight * 0.6;
    
    return Size(
      math.max(textWidth, minWidth),
      math.max(textHeight, minHeight),
    );
  }

  /// 计算填充大小
  Size _calculateFillSize(double screenWidth, double screenHeight) {
    return Size(
      widget.button.maxWidth ?? screenWidth * 0.8,
      widget.button.maxHeight ?? screenHeight * 0.12,
    );
  }

  /// 计算自适应大小
  Size _calculateAdaptiveBasedSize(double baseWidth, double baseHeight, CalculatorTheme theme) {
    // 结合内容和可用空间
    final contentSize = _calculateContentBasedSize(baseWidth, baseHeight, theme);
    
    // 应用最小最大限制
    final minWidth = widget.button.minWidth ?? baseWidth * 0.5;
    final maxWidth = widget.button.maxWidth ?? baseWidth * 2.0;
    final minHeight = widget.button.minHeight ?? baseHeight * 0.5;
    final maxHeight = widget.button.maxHeight ?? baseHeight * 2.0;
    
    return Size(
      contentSize.width.clamp(minWidth, maxWidth),
      contentSize.height.clamp(minHeight, maxHeight),
    );
  }

  /// 构建大小约束
  BoxConstraints _buildSizeConstraints() {
    return BoxConstraints(
      minWidth: widget.button.minWidth ?? 0,
      maxWidth: widget.button.maxWidth ?? double.infinity,
      minHeight: widget.button.minHeight ?? 0,
      maxHeight: widget.button.maxHeight ?? double.infinity,
    );
  }

  /// 获取内容边距
  EdgeInsets _getContentPadding() {
    return widget.button.contentPadding ?? 
           const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
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
        // 🔧 使用缓存的MemoryImage，避免重复解码导致闪烁
        if (_cachedMemoryImage != null && _lastBackgroundImageData == backgroundImage) {
          return DecorationImage(
            image: _cachedMemoryImage!,
            fit: BoxFit.cover, // 🔧 改为cover模式，完全覆盖按键区域
            opacity: 0.8, // 🔧 增加透明度，避免背景图片过于突出，保证文字可读性
          );
        } else {
          // 如果缓存不匹配，重新加载
          _preloadBackgroundImage();
          if (_cachedMemoryImage != null) {
            return DecorationImage(
              image: _cachedMemoryImage!,
              fit: BoxFit.cover, // 🔧 改为cover模式，完全覆盖按键区域
              opacity: 0.8, // 🔧 增加透明度，避免背景图片过于突出，保证文字可读性
            );
          }
          return null;
        }
      } else if (Uri.tryParse(backgroundImage)?.isAbsolute == true) {
        // 处理有效的URL格式
        return DecorationImage(
          image: NetworkImage(backgroundImage),
          fit: BoxFit.cover, // 🔧 改为cover模式，完全覆盖按键区域
          opacity: 0.8, // 🔧 增加透明度，避免背景图片过于突出，保证文字可读性
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
        fit: BoxFit.cover, // 🔧 改为cover模式，完全覆盖按键区域
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

  /// 构建按钮内容
  Widget _buildButtonContent(Color textColor, CalculatorTheme theme) {
    // 优先使用按钮独立的字体大小，否则使用主题的全局字体大小
    final fontSize = widget.button.fontSize ?? theme.fontSize;

    // 🔧 修复：有背景图片时，文字内容应该正常显示在背景图片上方
    // 检查是否有自定义图标
    if (widget.button.customIcon != null && widget.button.customIcon!.isNotEmpty) {
      // 在这里返回一个图标控件，或者其他你想要显示的自定义内容
      // 例如：
      return Icon(
        Icons.star, // 这是一个示例图标，你需要根据customIcon的值来决定显示哪个图标
        color: widget.button.iconColor != null ? _parseColor(widget.button.iconColor!) : textColor,
        size: widget.button.iconSize ?? fontSize,
      );
    } else {
      // 🔧 修复：无论是否有背景图片，都应该显示文字内容
      // 如果有背景图片，文字可能需要更好的对比度
      Color finalTextColor = textColor;
      
      // 如果有背景图片，增强文字对比度
      if (widget.button.backgroundImage != null && widget.button.backgroundImage!.isNotEmpty) {
        // 添加文字阴影效果，增强可读性
        return Container(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.button.label,
              style: TextStyle(
                color: finalTextColor,
                fontSize: fontSize, // 应用动态字体大小
                fontWeight: FontWeight.w600, // 🔧 增加字体粗细，提高可读性
                fontFamily: widget.button.fontFamily, // 应用字体
                shadows: [
                  // 🔧 添加文字阴影，增强背景图片上的文字可读性
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      
      // 默认显示文本（无背景图片）
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.button.label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize, // 应用动态字体大小
            fontWeight: FontWeight.w500,
            fontFamily: widget.button.fontFamily, // 应用字体
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
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