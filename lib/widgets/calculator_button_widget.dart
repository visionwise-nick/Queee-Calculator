import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calculator_dsl.dart';
import '../providers/calculator_provider.dart';

class CalculatorButtonWidget extends StatelessWidget {
  final CalculatorButton button;

  const CalculatorButtonWidget({Key? key, required this.button}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context, listen: true);
    final theme = provider.getThemeForButton(button);
    final bool isLoading = provider.isButtonLoading(button.id);
    final String label = provider.getButtonLabel(button);

    return ElevatedButton(
      style: theme,
      onPressed: isLoading ? null : () {
        HapticFeedback.lightImpact();
        provider.executeAction(button.action, buttonId: button.id);
      },
      child: isLoading 
        ? CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.textStyle?.color ?? Colors.white),
          )
        : Text(label, textAlign: TextAlign.center),
    );
  }
} 