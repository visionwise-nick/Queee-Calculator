import 'package:flutter/material.dart';
import 'dart:async'; // 🔧 新增：导入Timer
import '../services/task_service.dart';

/// 生成状态显示组件
class GenerationStatusWidget extends StatefulWidget {
  final String taskId;
  final Function(GenerationTask)? onTaskCompleted;
  final Function(GenerationTask)? onTaskFailed;
  final bool showDetails;

  const GenerationStatusWidget({
    Key? key,
    required this.taskId,
    this.onTaskCompleted,
    this.onTaskFailed,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<GenerationStatusWidget> createState() => _GenerationStatusWidgetState();
}

class _GenerationStatusWidgetState extends State<GenerationStatusWidget>
    with TickerProviderStateMixin {
  GenerationTask? _task;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 注册任务状态回调
    TaskService.registerTaskCallback(widget.taskId, _onTaskUpdate);
    
    // 立即查询一次任务状态
    _queryTaskStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    TaskService.removeTaskCallback(widget.taskId, _onTaskUpdate);
    super.dispose();
  }

  void _queryTaskStatus() async {
    final task = await TaskService.getTaskStatus(widget.taskId);
    if (mounted && task != null) {
      setState(() {
        _task = task;
      });
    }
  }

  void _onTaskUpdate(GenerationTask task) {
    if (!mounted) return;
    
    setState(() {
      _task = task;
    });

    // 根据任务状态执行不同动作
    switch (task.status) {
      case TaskStatus.running:
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        break;
      case TaskStatus.completed:
        _pulseController.stop();
        widget.onTaskCompleted?.call(task);
        break;
      case TaskStatus.failed:
        _pulseController.stop();
        widget.onTaskFailed?.call(task);
        break;
      case TaskStatus.cancelled:
        _pulseController.stop();
        break;
      case TaskStatus.pending:
        // 保持等待状态
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // 状态图标
                _buildStatusIcon(),
                const SizedBox(width: 12),
                
                // 任务信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTaskTitle(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 取消按钮
                if (_task!.status == TaskStatus.pending || 
                    _task!.status == TaskStatus.running)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelTask,
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            
            // 进度条
            if (_task!.status == TaskStatus.running && _task!.progress > 0)
              ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _task!.progress / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_task!.progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            
            // 详细信息（可选）
            if (widget.showDetails && _task!.prompt != null)
              ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _task!.prompt!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            
            // 错误信息
            if (_task!.status == TaskStatus.failed && _task!.error != null)
              ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, 
                          size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _task!.error!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_task!.status) {
      case TaskStatus.pending:
        return Icon(
          Icons.schedule,
          color: Colors.orange.shade600,
          size: 20,
        );
      case TaskStatus.running:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Icon(
                Icons.autorenew,
                color: Colors.blue.shade600,
                size: 20,
              ),
            );
          },
        );
      case TaskStatus.completed:
        return Icon(
          Icons.check_circle,
          color: Colors.green.shade600,
          size: 20,
        );
      case TaskStatus.failed:
        return Icon(
          Icons.error,
          color: Colors.red.shade600,
          size: 20,
        );
      case TaskStatus.cancelled:
        return Icon(
          Icons.cancel,
          color: Colors.grey.shade600,
          size: 20,
        );
    }
  }

  String _getTaskTitle() {
    switch (_task!.type) {
      case TaskType.aiDesigner:
        return 'AI设计师';
      case TaskType.appBackground:
        return 'APP背景图生成';
      case TaskType.buttonPattern:
        return '按键背景图生成';
    }
  }

  String _getStatusText() {
    switch (_task!.status) {
      case TaskStatus.pending:
        return '等待处理中...';
      case TaskStatus.running:
        return '正在生成中...';
      case TaskStatus.completed:
        return '生成完成！';
      case TaskStatus.failed:
        return '生成失败';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }

  void _cancelTask() async {
    final success = await TaskService.cancelTask(widget.taskId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('取消任务失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 全局生成状态显示器
class GlobalGenerationStatusBar extends StatefulWidget {
  const GlobalGenerationStatusBar({Key? key}) : super(key: key);

  @override
  State<GlobalGenerationStatusBar> createState() => _GlobalGenerationStatusBarState();
}

class _GlobalGenerationStatusBarState extends State<GlobalGenerationStatusBar> {
  List<GenerationTask> _activeTasks = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshActiveTasks();
    
    // 定期刷新活跃任务列表
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _refreshActiveTasks();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshActiveTasks() {
    final tasks = TaskService.getActiveTasks()
        .where((task) => task.status != TaskStatus.completed && 
                        task.status != TaskStatus.failed &&
                        task.status != TaskStatus.cancelled)
        .toList();
    
    if (tasks.length != _activeTasks.length) {
      setState(() {
        _activeTasks = tasks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _activeTasks.map((task) => 
          GenerationStatusWidget(
            key: ValueKey(task.id),
            taskId: task.id,
            showDetails: false,
          )
        ).toList(),
      ),
    );
  }
} 