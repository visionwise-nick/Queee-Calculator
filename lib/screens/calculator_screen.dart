import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button_grid.dart';
import 'theme_settings_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculatorProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: provider.getBackgroundColor(),
          body: SafeArea(
            child: Column(
              children: [
                // 顶部标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Queee Calculator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: provider.getDisplayTextColor(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: provider.getDisplayTextColor(),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThemeSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // 计算器显示屏
                Expanded(
                  flex: 2,
                  child: CalculatorDisplay(),
                ),
                
                // 按钮网格
                Expanded(
                  flex: 4,
                  child: CalculatorButtonGrid(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on CalculatorProvider {
  Color getBackgroundColor() {
    return _parseColor(config.theme.backgroundColor);
  }
  
  Color getDisplayTextColor() {
    return _parseColor(config.theme.displayTextColor);
  }
  
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) | 0xFF000000);
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }
} 