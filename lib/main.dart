import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queee_calculator/providers/calculator_provider.dart';
import 'package:queee_calculator/screens/calculator_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QueueCalculatorApp());
}

class QueueCalculatorApp extends StatelessWidget {
  const QueueCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CalculatorProvider(),
      child: MaterialApp(
        onGenerateTitle: (context) {
          return AppLocalizations.of(context)!.appTitle;
        },
        theme: ThemeData(
          brightness: Brightness.dark,
          // primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'SF Pro Display',
        ),
        darkTheme: ThemeData.dark(),
        // 国际化支持
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorScreen(),
      ),
    );
  }
} 