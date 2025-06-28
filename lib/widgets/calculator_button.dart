import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../providers/calculator_provider.dart';

class CalculatorButtonWidget extends StatelessWidget {
  final CalculatorButton button;
  final VoidCallback onPressed;
  final Size? fixedSize;

  const CalculatorButtonWidget({
    super.key,
    required this.button,
    required this.onPressed,
    this.fixedSize,
  });

  Color _parseColor(String? hexColor, [Color defaultColor = Colors.grey]) {
    if (hexColor == null || hexColor.isEmpty) return defaultColor;
    final cleanColor = hexColor.replaceAll('#', '');
    try {
      if (cleanColor.length == 6) {
        return Color(int.parse('FF$cleanColor', radix: 16));
      } else if (cleanColor.length == 8) {
        return Color(int.parse(cleanColor, radix: 16));
      }
    } catch (e) {
      // Ignore parsing errors and return default color
    }
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context, listen: false);
    final theme = provider.config.theme;

    // --- Button Property Determination ---

    Color getButtonColor() {
      if (button.backgroundColor != null) {
        return _parseColor(button.backgroundColor, Colors.grey.shade700);
      }
      switch (button.type) {
        case 'operator':
          return _parseColor(theme.operatorButtonColor, Colors.orange);
        case 'secondary':
          return _parseColor(theme.secondaryButtonColor, Colors.grey.shade400);
        default:
          return _parseColor(theme.primaryButtonColor, Colors.grey.shade800);
      }
    }

    final Color textColor = button.textColor != null
        ? _parseColor(button.textColor!)
        : _parseColor(
            button.type == 'operator' ? theme.operatorButtonTextColor : theme.primaryButtonTextColor,
            button.type == 'secondary' ? Colors.black : Colors.white,
          );

    final double fontSize = button.fontSize ?? 28.0;
    final double borderRadius = button.borderRadius ?? theme.buttonBorderRadius;

    // --- Button Style and Content ---

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: getButtonColor(),
      elevation: button.elevation ?? theme.buttonElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.zero,
      fixedSize: fixedSize,
    );

    Widget buttonContent = Center(
      child: Text(
        button.label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (button.backgroundImage != null && button.backgroundImage!.isNotEmpty) {
      buttonContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.network(
              button.backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            buttonContent,
          ],
        ),
      );
    }

    // --- Final Widget Assembly ---

    Widget finalButton = ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: buttonContent,
    );

    if (button.description != null && button.description!.isNotEmpty) {
      return Tooltip(
        message: button.description!,
        child: finalButton,
        padding: const EdgeInsets.all(10),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        waitDuration: const Duration(milliseconds: 500),
      );
    }

    return finalButton;
  }
}