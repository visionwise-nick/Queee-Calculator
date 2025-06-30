import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculationStep {
  final String expression;
  final String description;
  final double input;
  final double result;
  final DateTime timestamp;

  CalculationStep({
    required this.expression,
    required this.description,
    required this.input,
    required this.result,
    required this.timestamp,
  });
}

class CalculationHistoryDialog extends StatefulWidget {
  final List<CalculationStep> steps;

  const CalculationHistoryDialog({
    super.key,
    required this.steps,
  });

  @override
  State<CalculationHistoryDialog> createState() => _CalculationHistoryDialogState();
}

class _CalculationHistoryDialogState extends State<CalculationHistoryDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.indigo.shade900,
                  Colors.purple.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // 增强的标题栏
                _buildEnhancedTitleBar(),
                
                // 搜索和筛选栏
                _buildSearchAndFilterBar(),
                
                // 统计信息栏
                _buildStatisticsBar(),
                
                // 运算步骤内容
                Expanded(
                  child: _buildEnhancedHistoryContent(),
                ),
                
                // 底部操作栏
                _buildBottomActionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建增强的标题栏
  Widget _buildEnhancedTitleBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.red.shade500,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.history,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '运算历史',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '共 ${widget.steps.length} 条记录',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // 切换详细信息显示
          IconButton(
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            icon: Icon(
              _showDetails ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            tooltip: _showDetails ? '隐藏详细信息' : '显示详细信息',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// 构建搜索和筛选栏
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '搜索运算...',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white60, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 筛选下拉框
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  dropdownColor: Colors.indigo.shade800,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  icon: Icon(Icons.filter_list, color: Colors.white60, size: 20),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: 'basic', child: Text('基础运算')),
                    DropdownMenuItem(value: 'function', child: Text('函数运算')),
                    DropdownMenuItem(value: 'recent', child: Text('最近使用')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息栏
  Widget _buildStatisticsBar() {
    final filteredSteps = _getFilteredSteps();
    final totalOperations = filteredSteps.length;
    final avgResult = totalOperations > 0 
        ? filteredSteps.map((s) => s.result).reduce((a, b) => a + b) / totalOperations
        : 0.0;
    final maxResult = totalOperations > 0 
        ? filteredSteps.map((s) => s.result).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总计', '$totalOperations', Icons.calculate),
          _buildStatItem('平均值', _formatNumber(avgResult), Icons.trending_flat),
          _buildStatItem('最大值', _formatNumber(maxResult), Icons.trending_up),
          _buildStatItem('今日', '${_getTodayCount()}', Icons.today),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade300, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// 构建增强的历史内容
  Widget _buildEnhancedHistoryContent() {
    final filteredSteps = _getFilteredSteps();
    
    if (filteredSteps.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: filteredSteps.length,
        itemBuilder: (context, index) {
          final step = filteredSteps[index];
          final isEven = index % 2 == 0;
          
          return _buildEnhancedHistoryItem(step, index, isEven);
        },
      ),
    );
  }

  /// 构建增强的历史项
  Widget _buildEnhancedHistoryItem(CalculationStep step, int index, bool isEven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEven 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showDetails)
                    Text(
                      step.expression,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatNumber(step.result),
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (_showDetails)
                    Text(
                      _formatTime(step.timestamp),
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 复制按钮
            IconButton(
              onPressed: () => _copyToClipboard(step),
              icon: Icon(Icons.copy, color: Colors.white60, size: 16),
              iconSize: 16,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Icon(
              Icons.expand_more,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
        children: [
          _buildDetailedStepInfo(step),
        ],
      ),
    );
  }

  /// 构建详细步骤信息
  Widget _buildDetailedStepInfo(CalculationStep step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('表达式', step.expression, Icons.functions),
          const SizedBox(height: 8),
          _buildDetailRow('输入值', _formatNumber(step.input), Icons.input),
          const SizedBox(height: 8),
          _buildDetailRow('结果', _formatNumber(step.result), Icons.output),
          const SizedBox(height: 8),
          _buildDetailRow('时间', _formatFullTime(step.timestamp), Icons.access_time),
          const SizedBox(height: 8),
          _buildDetailRow('精度', '${step.result.toString().length} 位', Icons.precision_manufacturing),
        ],
      ),
    );
  }

  /// 构建详细信息行
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade300, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无运算记录',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始使用计算器来查看运算历史',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            '导出',
            Icons.download,
            () => _exportHistory(),
            Colors.blue,
          ),
          _buildActionButton(
            '清除',
            Icons.delete_outline,
            () => _showClearConfirmation(),
            Colors.red,
          ),
          _buildActionButton(
            '统计',
            Icons.analytics,
            () => _showStatistics(),
            Colors.green,
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// 获取筛选后的步骤
  List<CalculationStep> _getFilteredSteps() {
    var steps = widget.steps.reversed.toList(); // 最新的在前
    
    // 应用搜索筛选
    if (_searchQuery.isNotEmpty) {
      steps = steps.where((step) =>
        step.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        step.expression.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // 应用类型筛选
    switch (_selectedFilter) {
      case 'basic':
        steps = steps.where((step) => 
          step.expression.contains('+') || 
          step.expression.contains('-') || 
          step.expression.contains('*') || 
          step.expression.contains('/')
        ).toList();
        break;
      case 'function':
        steps = steps.where((step) => 
          step.expression.contains('(') && step.expression.contains(')')
        ).toList();
        break;
      case 'recent':
        final now = DateTime.now();
        steps = steps.where((step) => 
          now.difference(step.timestamp).inHours < 24
        ).toList();
        break;
    }
    
    return steps;
  }

  /// 获取今日运算次数
  int _getTodayCount() {
    final today = DateTime.now();
    return widget.steps.where((step) {
      final stepDate = step.timestamp;
      return stepDate.year == today.year &&
             stepDate.month == today.month &&
             stepDate.day == today.day;
    }).length;
  }

  /// 格式化数字
  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    } else {
      String formatted = number.toStringAsFixed(6);
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化完整时间
  String _formatFullTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${_formatTime(time)}';
  }

  /// 复制到剪贴板
  void _copyToClipboard(CalculationStep step) {
    final text = '${step.description}: ${step.expression} = ${_formatNumber(step.result)}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 导出历史
  void _exportHistory() {
    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('导出功能开发中...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 显示清除确认
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('清除历史记录'),
        content: Text('确定要清除所有运算历史吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实现清除功能
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示统计信息
  void _showStatistics() {
    // TODO: 实现统计功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('统计功能开发中...'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 