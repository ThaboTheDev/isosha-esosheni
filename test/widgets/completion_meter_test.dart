import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/widgets/completion_meter.dart';

void main() {
  testWidgets('shows percent label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CompletionMeter(82)),
    ));
    expect(find.text('82%'), findsOneWidget);
  });

  testWidgets('clamps to 0..100', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CompletionMeter(140)),
    ));
    expect(find.text('100%'), findsOneWidget);
  });
}
