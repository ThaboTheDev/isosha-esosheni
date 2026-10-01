import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/widgets/report_sheet.dart';

void main() {
  testWidgets('requires a category before submitting', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReportSheet(onSubmit: (c, d) async => null),
      ),
    ));
    expect(find.text('Harassment'), findsOneWidget);
    expect(find.text('Something else'), findsOneWidget);
    await tester.tap(find.text('Send report'));
    await tester.pump();
    expect(find.text('Choose a reason for this report.'), findsOneWidget);
  });

  testWidgets('submits the exact category key', (tester) async {
    String? sent;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReportSheet(onSubmit: (c, d) async {
          sent = c;
          return null;
        }),
      ),
    ));
    await tester.tap(find.text('Fake identity'));
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(sent, 'fake_identity');
  });
}
