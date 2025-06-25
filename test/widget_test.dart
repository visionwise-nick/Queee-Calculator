// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:queee_calculator/main.dart';
import 'package:queee_calculator/providers/calculator_provider.dart';

void main() {
  testWidgets('Calculator app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QueueCalculatorApp());

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that our calculator display shows "0" initially  
    expect(find.text('0'), findsAtLeastNWidgets(1));

    // Verify that the calculator buttons exist
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    expect(find.text('='), findsOneWidget);

    // Test basic calculation: tap 1, then +, then 1, then =
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    // Verify that the result is 2
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Calculator provider initialization test', (WidgetTester tester) async {
    // Test that provider can be created without issues
    final provider = CalculatorProvider();
    await provider.initializeConfig();
    
    expect(provider.config, isNotNull);
    expect(provider.state.display, equals('0'));
  });
}
