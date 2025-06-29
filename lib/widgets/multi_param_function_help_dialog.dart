import 'package:flutter/material.dart';

class MultiParamFunctionHelpDialog extends StatelessWidget {
  const MultiParamFunctionHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.indigo.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '多参数函数使用教程',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '🔢 基本操作流程',
                      [
                        '1. 输入第一个数字',
                        '2. 点击多参数函数按钮（如 x^y、复利等）',
                        '3. 输入第二个数字',
                        '4. 如需更多参数，点击 "," 继续输入',
                        '5. 点击 "执行" 完成计算',
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildSection(
                      '📊 金融函数示例',
                      [
                        '汇率转换：100 → 汇率 → 7.2 → 执行 = 720',
                        '复利计算：10000 → 复利 → 5 → , → 10 → 执行',
                        '贷款月供：500000 → 贷款 → 4.5 → , → 30 → 执行',
                        '投资回报：50000 → 投资 → 30000 → 执行 = 166.67%',
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildSection(
                      '🧮 数学函数示例',
                      [
                        '幂运算：2 → x^y → 8 → 执行 = 256',
                        '对数：100 → log → 10 → 执行 = 2',
                        '最大值：5 → max → 3 → , → 9 → , → 1 → 执行 = 9',
                        '平均值：10 → avg → 20 → , → 30 → 执行 = 20',
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTipBox(
                      '💡 使用技巧',
                      [
                        '• 显示屏会显示当前函数和参数',
                        '• 按 AC 键可以取消多参数函数输入',
                        '• 看到操作提示时按照提示操作',
                        '• 参数输入错误时会显示错误信息',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '我知道了',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTipBox(String title, List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.yellow.shade300,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                height: 1.3,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
