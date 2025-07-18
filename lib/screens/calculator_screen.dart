import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculator_dsl.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button_grid.dart';
import '../widgets/calculation_history_dialog.dart';
import '../widgets/multi_param_function_help_dialog.dart';
import 'ai_customize_screen.dart';
import 'image_generation_screen.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import '../l10n/app_localizations.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});
  
  // 添加背景图缓存，避免重复解码造成闪烁
  static final Map<String, MemoryImage> _backgroundImageCache = <String, MemoryImage>{};

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        final theme = provider.config.theme;
        
        return Scaffold(
          body: Container(
            decoration: _buildBackgroundDecoration(provider.config),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildAdaptiveLayout(context, provider, constraints);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建自适应布局
  Widget _buildAdaptiveLayout(BuildContext context, CalculatorProvider provider, BoxConstraints constraints) {
    final layout = provider.config.layout;
    final screenHeight = constraints.maxHeight;
    
    // 计算最优的显示区域高度
    final displayHeight = _calculateOptimalDisplayHeight(context, layout, screenHeight);
    final titleBarHeight = 60.0; // 更新为新的标题栏高度
    final availableHeight = screenHeight - titleBarHeight;
    
    // 确保按钮区域有足够空间，至少占60%的可用高度
    final minButtonAreaHeight = availableHeight * 0.6;
    final adjustedDisplayHeight = math.min(displayHeight, availableHeight - minButtonAreaHeight);
    final buttonAreaHeight = availableHeight - adjustedDisplayHeight;
    
    return Column(
      children: [
        // 顶部标题栏 - 固定高度
        _buildTitleBar(context, provider),
        
        // 计算器显示屏 - 动态高度
        Container(
          height: adjustedDisplayHeight,
          child: CalculatorDisplay(
            state: provider.state,
            theme: provider.config.theme,
            appBackground: provider.config.appBackground, // 🔧 传递APP背景配置，用于透明度控制
            onParameterInput: (paramId) {
              _handleParameterInput(context, provider, paramId);
            },
          ),
        ),
        
        // 按钮网格 - 剩余空间，使用Expanded确保不溢出
        Expanded(
          child: Container(
            height: buttonAreaHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // 减少边距
            child: CalculatorButtonGrid(),
          ),
        ),
      ],
    );
  }

  /// 计算最优显示屏高度
  double _calculateOptimalDisplayHeight(BuildContext context, CalculatorLayout layout, double screenHeight) {
    final theme = layout.buttons.isNotEmpty ? 
        Provider.of<CalculatorProvider>(context, listen: false).config.theme : null;
    
    // 如果主题指定了AI可调节的显示区高度比例，优先使用
    if (theme?.displayHeightRatio != null) {
      return screenHeight * theme!.displayHeightRatio!;
    }
    
    // 如果主题指定了固定显示区高度比例，使用它
    if (theme?.displayHeight != null) {
      return screenHeight * theme!.displayHeight!;
    }
    
    // 默认增加显示区域高度（增加一半）
    double baseHeight = 120.0; // 从80增加到120
    
    // 根据布局复杂度调整，但限制最大高度
    final buttonCount = layout.buttons.length;
    final totalCells = layout.rows * layout.columns;
    final density = totalCells > 0 ? buttonCount / totalCells : 0.5;
    
    // 按钮越多，显示区域相对越小，但不能太小，增加基础比例
    if (density > 0.8 || buttonCount > 25) {
      baseHeight = screenHeight * 0.18; // 高密度：从12%增加到18%
    } else if (density > 0.6 || buttonCount > 20) {
      baseHeight = screenHeight * 0.22;  // 中密度：从15%增加到22%
    } else {
      baseHeight = screenHeight * 0.3; // 低密度：从20%增加到30%
    }
    
    // 确保最小和最大值，为按钮区域预留更多空间
    // 桌面端需要更多的显示空间
    final minHeight = MediaQuery.of(context).size.width > 600 ? 120.0 : 90.0; // 增加最小高度
    return baseHeight.clamp(minHeight, screenHeight * 0.4); // 增加最大比例到40%
  }

  /// 构建标题栏
  Widget _buildTitleBar(BuildContext context, CalculatorProvider provider) {
    return Container(
      height: 60, // 减少标题栏高度
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  const Color(0xFF6C63FF), // 紫色
                  const Color(0xFF3B82F6), // 蓝色
                  const Color(0xFF06B6D4), // 青色
                  const Color(0xFF10B981), // 绿色
                  const Color(0xFFF59E0B), // 橙色
                  const Color(0xFFEF4444), // 红色
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)!.appTitle,
                style: TextStyle(
                  fontSize: 16, // 🔧 减小字体确保完整显示
                  fontWeight: FontWeight.w800, // 稍微减轻字体粗细
                  color: Colors.white, // 必须是白色才能显示渐变
                  letterSpacing: 0.8, // 🔧 减少字符间距节省空间
                  shadows: [
                    // 添加阴影效果增强视觉冲击
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 1), // 🔧 减小阴影偏移
                      blurRadius: 3, // 🔧 减小模糊半径
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 按钮组 - 使用更紧凑的布局
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 运算历史按钮
              _buildCompactIconButton(
                icon: Icons.history,
                colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                shadowColor: Colors.orange,
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierColor: Colors.black.withOpacity(0.7),
                    builder: (context) => CalculationHistoryDialog(
                      steps: provider.calculationHistory,
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.history,
              ),
              const SizedBox(width: 4),
              // 多参数函数帮助按钮
              _buildCompactIconButton(
                icon: Icons.help_outline,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                shadowColor: Colors.green,
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierColor: Colors.black.withOpacity(0.7),
                    builder: (context) => const MultiParamFunctionHelpDialog(),
                  );
                },
                tooltip: AppLocalizations.of(context)!.multiParamHelp,
              ),
              const SizedBox(width: 4),
              // AI设计师按钮
              _buildCompactIconButton(
                icon: Icons.chat_bubble_outline,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                shadowColor: Colors.purple,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AICustomizeScreen(),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.aiDesigner,
              ),
              const SizedBox(width: 4),
              // 图像生成工坊按钮
              _buildCompactIconButton(
                icon: Icons.palette,
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                shadowColor: Colors.pink,
                onPressed: () {
                  final provider = Provider.of<CalculatorProvider>(context, listen: false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageGenerationScreen(
                        currentConfig: provider.config,
                        onConfigUpdated: (config) {
                          provider.applyConfig(config);
                        },
                      ),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.imageWorkshop,
              ),

            ],
          ),
        ],
      ),
    );
  }

  /// 构建背景装饰
  BoxDecoration _buildBackgroundDecoration(CalculatorConfig config) {
    final theme = config.theme;
    final appBackground = config.appBackground;
    
    // 🔧 添加调试信息
    print('🔧 构建背景装饰：');
    print('  - APP背景配置: ${appBackground != null ? "存在" : "无"}');
    if (appBackground != null) {
      print('  - 背景图URL: ${appBackground.backgroundImageUrl != null ? "存在(${appBackground.backgroundImageUrl!.length}字符)" : "无"}');
      print('  - 背景透明度: ${appBackground.backgroundOpacity ?? 1.0}');
      print('  - 按键透明度: ${appBackground.buttonOpacity ?? 1.0}');
      print('  - 显示区域透明度: ${appBackground.displayOpacity ?? 1.0}');
    }
    
    // 优先使用APP背景配置
    if (appBackground?.backgroundImageUrl != null) {
      print('🔧 使用APP背景图');
      return BoxDecoration(
        image: DecorationImage(
          image: _getCachedBackgroundImage(appBackground!.backgroundImageUrl!),
          fit: BoxFit.cover,
          colorFilter: appBackground.backgroundOpacity != null && appBackground.backgroundOpacity! < 1.0
              ? ColorFilter.mode(
                  Colors.black.withValues(alpha: 1.0 - appBackground.backgroundOpacity!),
                  BlendMode.darken,
                )
              : null,
        ),
      );
    }
    
    print('🔧 使用主题背景');
    // 回退到主题背景
    return BoxDecoration(
      color: theme.backgroundGradient == null && theme.backgroundImage == null 
          ? _parseColor(theme.backgroundColor) 
          : null,
      gradient: theme.backgroundGradient != null 
          ? _buildGradient(theme.backgroundGradient!) 
          : null,
      image: _buildThemeBackgroundImage(theme.backgroundImage),
    );
  }

  /// 构建主题背景图像
  DecorationImage? _buildThemeBackgroundImage(String? backgroundImage) {
    if (backgroundImage == null) {
      return null;
    }

    // 过滤掉明显无效的URL格式
    if (backgroundImage.startsWith('url(') && backgroundImage.endsWith(')')) {
      // 这是CSS样式的url()格式，不是有效的图片URL
      print('跳过无效的CSS格式主题背景图片: $backgroundImage');
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
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3),
            BlendMode.darken,
          ),
        );
      } catch (e) {
        print('Failed to decode base64 theme background image: $e');
        return null;
      }
    } else if (Uri.tryParse(backgroundImage)?.isAbsolute == true) {
      // 处理有效的URL格式
      return DecorationImage(
        image: NetworkImage(backgroundImage),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.3),
          BlendMode.darken,
        ),
      );
    } else {
      // 跳过无效格式
      print('跳过无效格式的主题背景图片: $backgroundImage');
      return null;
    }
  }

  /// 获取缓存的背景图片，避免重复解码造成闪烁
  MemoryImage _getCachedBackgroundImage(String base64String) {
    // 🔧 添加调试信息
    print('🔧 获取缓存背景图，URL长度：${base64String.length}');
    
    if (!_backgroundImageCache.containsKey(base64String)) {
      print('🔧 背景图不在缓存中，开始解码...');
      try {
        final bytes = _base64ToBytes(base64String);
        _backgroundImageCache[base64String] = MemoryImage(bytes);
        print('🔧 背景图解码成功，字节数：${bytes.length}');
      } catch (e) {
        print('🔧 背景图解码失败：$e');
        // 如果解码失败，返回一个默认图片或抛出异常
        rethrow;
      }
    } else {
      print('🔧 使用缓存的背景图');
    }
    return _backgroundImageCache[base64String]!;
  }

  /// 将base64字符串转换为字节数组
  Uint8List _base64ToBytes(String base64String) {
    // 🔧 添加调试信息
    print('🔧 转换base64字符串，原始长度：${base64String.length}');
    
    if (base64String.startsWith('data:')) {
      base64String = base64String.split(',')[1];
      print('🔧 移除data前缀后长度：${base64String.length}');
    }
    
    try {
      final bytes = base64Decode(base64String);
      print('🔧 base64解码成功，字节数：${bytes.length}');
      return bytes;
    } catch (e) {
      print('🔧 base64解码失败：$e');
      rethrow;
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

  /// 解析颜色字符串
  Color _parseColor(String colorString) {
    final cleanColor = colorString.replaceAll('#', '');
    
    if (cleanColor.length == 6) {
      return Color(int.parse('FF$cleanColor', radix: 16));
    } else if (cleanColor.length == 8) {
      return Color(int.parse(cleanColor, radix: 16));
    } else {
      return Colors.grey;
    }
  }

  /// 处理参数输入
  void _handleParameterInput(BuildContext context, CalculatorProvider provider, String paramId) {
    // 显示参数输入对话框
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('参数输入'),
        content: Text('请使用计算器按钮输入参数值，然后按逗号(,)分隔参数，最后按等号(=)执行计算。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 构建紧凑的图标按钮
  Widget _buildCompactIconButton({
    required IconData icon,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

 