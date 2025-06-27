import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/calculator_screen.dart';
import 'providers/calculator_provider.dart';

void main() {
  runApp(const QueueCalculatorApp());
}

class QueueCalculatorApp extends StatelessWidget {
  const QueueCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CalculatorProvider()..initialize(),
      child: MaterialApp(
        title: 'Queee Calculator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: const CalculatorScreen(),
      ),
    );
  }
} 