import 'package:flutter/material.dart';
import 'dart:math' as math;

class AIGenerationProgressDialog extends StatefulWidget {
  final String title;
  final String description;
  final double progress;
  final String statusMessage;
  final String? taskType; // 任务类型：'customize', 'generate-image', 'generate-pattern', 'generate-app-background'
  final VoidCallback? onCancel;
  final bool allowCancel;

  const AIGenerationProgressDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.progress,
    required this.statusMessage,
    this.taskType,
    this.onCancel,
    this.allowCancel = false,
  }) : super(key: key);

  @override
  State<AIGenerationProgressDialog> createState() => _AIGenerationProgressDialogState();
}

class _AIGenerationProgressDialogState extends State<AIGenerationProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getTaskIcon() {
    switch (widget.taskType) {
      case 'customize':
        return Icons.psychology;
      case 'generate-image':
        return Icons.image;
      case 'generate-pattern':
        return Icons.texture;
      case 'generate-app-background':
        return Icons.wallpaper;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getTaskColor() {
    switch (widget.taskType) {
      case 'customize':
        return Colors.blue;
      case 'generate-image':
        return Colors.green;
      case 'generate-pattern':
        return Colors.orange;
      case 'generate-app-background':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.allowCancel,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部图标和标题
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTaskColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTaskIcon(),
                          color: _getTaskColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 中心动画区域
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _getTaskColor().withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getTaskColor().withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 旋转的外圈
                              AnimatedBuilder(
                                animation: _rotationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotationController.value * 2 * math.pi,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _getTaskColor(),
                                          width: 3,
                                        ),
                                        gradient: SweepGradient(
                                          colors: [
                                            _getTaskColor().withOpacity(0.1),
                                            _getTaskColor(),
                                            _getTaskColor().withOpacity(0.1),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // 中心图标
                              Icon(
                                _getTaskIcon(),
                                size: 40,
                                color: _getTaskColor(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 进度条
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '生成进度',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          Text(
                            '${(widget.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getTaskColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.progress,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(_getTaskColor()),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 状态消息
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getTaskColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.statusMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 取消按钮（如果允许）
                  if (widget.allowCancel) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '取消生成',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 用于显示进度弹窗的工具类
class AIGenerationProgressManager {
  static OverlayEntry? _currentOverlay;
  static BuildContext? _context;

  /// 显示进度弹窗
  static void show(
    BuildContext context, {
    required String title,
    required String description,
    String? taskType,
    bool allowCancel = false,
    VoidCallback? onCancel,
  }) {
    hide(); // 先隐藏已有的弹窗
    
    _context = context;
    _currentOverlay = OverlayEntry(
      builder: (context) => AIGenerationProgressDialog(
        title: title,
        description: description,
        progress: 0.0,
        statusMessage: '正在初始化...',
        taskType: taskType,
        allowCancel: allowCancel,
        onCancel: onCancel,
      ),
    );
    
    Overlay.of(context)?.insert(_currentOverlay!);
  }

  /// 更新进度
  static void updateProgress(double progress, String statusMessage) {
    if (_currentOverlay != null && _context != null) {
      _currentOverlay!.markNeedsBuild();
      // 通过重新构建来更新状态 - 这里需要一个状态管理方案
    }
  }

  /// 隐藏进度弹窗
  static void hide() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
    _context = null;
  }
}

// 有状态的进度弹窗管理器
class AIGenerationProgressController extends ChangeNotifier {
  double _progress = 0.0;
  String _statusMessage = '正在初始化...';
  String _title = '';
  String _description = '';
  String? _taskType;
  bool _isVisible = false;
  bool _allowCancel = false;
  VoidCallback? _onCancel;

  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String get title => _title;
  String get description => _description;
  String? get taskType => _taskType;
  bool get isVisible => _isVisible;
  bool get allowCancel => _allowCancel;
  VoidCallback? get onCancel => _onCancel;

  void show({
    required String title,
    required String description,
    String? taskType,
    bool allowCancel = false,
    VoidCallback? onCancel,
  }) {
    _title = title;
    _description = description;
    _taskType = taskType;
    _allowCancel = allowCancel;
    _onCancel = onCancel;
    _progress = 0.0;
    _statusMessage = '正在初始化...';
    _isVisible = true;
    notifyListeners();
  }

  void updateProgress(double progress, String statusMessage) {
    _progress = progress;
    _statusMessage = statusMessage;
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }
} 