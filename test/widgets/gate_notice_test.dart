import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/widgets/gate_notice.dart';
import 'package:isosha_esosheni/data/models/member.dart';

void main() {
  testWidgets('stage gate exact copy', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GateNotice(
          gate: Gate.fromJson(const {
            'ok': false,
            'reason': 'stage',
            'status': 'married',
          }),
        ),
      ),
    ));
    expect(
      find.textContaining('Discovery is for members who are not married or '
          'preparing for marriage.'),
      findsOneWidget,
    );
    expect(find.textContaining('married'), findsWidgets);
  });

  testWidgets('inactive gate exact copy', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GateNotice(
          gate: Gate.fromJson(const {'ok': false, 'reason': 'inactive'}),
        ),
      ),
    ));
    expect(
      find.textContaining('Your account is not active, so discovery is '
          'closed.'),
      findsOneWidget,
    );
  });

  testWidgets('visibility banner with completion percentages',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GateNotice(
          gate: Gate.fromJson(const {
            'ok': false,
            'visible_to_others': false,
            'completion': 45,
            'min_completion': 60,
          }),
          onSeeMissing: () {},
        ),
      ),
    ));
    expect(
      find.textContaining(
          'Your profile is 45% complete. Other members see you once it '
          'reaches 60%.'),
      findsOneWidget,
    );
    expect(find.text('See what is missing'), findsOneWidget);
  });
}
