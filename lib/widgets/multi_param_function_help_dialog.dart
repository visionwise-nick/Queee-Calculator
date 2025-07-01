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
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ 重要：多参数函数必须按正确顺序操作！',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildSection(
                      '🔢 正确操作流程（6步法）',
                      [
                        '1️⃣ 点击多参数函数按键（如"X^Y"、"平均值"等）',
                        '2️⃣ 界面会显示函数名和参数输入提示',
                        '3️⃣ 输入第一个参数（如底数、第一个数值等）',
                        '4️⃣ 按逗号","进入下一个参数输入',
                        '5️⃣ 输入第二个参数（如指数、第二个数值等）',
                        '6️⃣ 按等号"="执行计算并显示结果',
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
                      '🧮 数学函数示例（详细步骤）',
                      [
                        '【X^Y幂运算】计算2³：',
                        '  1️⃣点击"X^Y" → 2️⃣输入2 → 3️⃣按"," → 4️⃣输入3 → 5️⃣按"=" → 结果：8',
                        '',
                        '【平均值】计算10,20,30的平均值：',
                        '  1️⃣点击"平均值" → 2️⃣输入10 → 3️⃣按"," → 4️⃣输入20 → 5️⃣按"," → 6️⃣输入30 → 7️⃣按"=" → 结果：20',
                        '',
                        '【最大值】找出5,8,3中最大的：',
                        '  1️⃣点击"最大值" → 2️⃣输入5 → 3️⃣按"," → 4️⃣输入8 → 5️⃣按"," → 6️⃣输入3 → 7️⃣按"=" → 结果：8',
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTipBox(
                      '💡 重要使用技巧',
                      [
                        '✅ 显示屏会实时显示函数名和当前参数状态',
                        '✅ 界面显示进度指示器（●◐○）帮助跟踪输入进度',
                        '✅ 有实时预览功能，输入参数时可看到计算预览',
                        '✅ 按AC键可随时清除并退出多参数函数模式',
                        '⚠️ 必须按顺序操作：选择函数→输入参数→用逗号分隔→按等号',
                        '⚠️ 逗号","是关键！用来分隔不同的参数',
                        '⚠️ 如果操作错误，按AC重新开始',
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildTipBox(
                      '🔧 常见问题解决',
                      [
                        '❓ 点击按键没反应？→ 确保先点击多参数函数按键',
                        '❓ 不知道输入什么？→ 看屏幕提示，如"底数"、"指数"',
                        '❓ 输入错了怎么办？→ 按AC键清除重新开始',
                        '❓ 找不到逗号键？→ 数字键盘区，用来分隔参数',
                        '❓ 计算结果不对？→ 检查参数输入顺序和数值',
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
