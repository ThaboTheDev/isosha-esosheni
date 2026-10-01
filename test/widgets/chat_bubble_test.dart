import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isosha_esosheni/core/widgets/chat_bubble.dart';

const _at = '2026-10-01T10:00:00.000Z';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('mine bubble shows body and Sent', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBubble(createdAt: _at, mine: true, body: 'Hello there'),
      ),
    ));
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
  });

  testWidgets('read receipt on my last message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBubble(
          createdAt: _at,
          mine: true,
          body: 'Hello',
          isLast: true,
          read: true,
        ),
      ),
    ));
    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('deleted bubble shows Message deleted', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBubble(createdAt: _at, mine: false, deleted: true),
      ),
    ));
    expect(find.text('Message deleted'), findsOneWidget);
  });

  testWidgets('system bubble is centred', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBubble(
          createdAt: _at,
          mine: false,
          kind: 'system',
          body: 'You are both in the Talking Stage.',
        ),
      ),
    ));
    expect(find.text('You are both in the Talking Stage.'), findsOneWidget);
    final align = tester.widgetList<Align>(find.byType(Align));
    expect(
      align.any((a) => a.alignment == Alignment.center),
      isTrue,
    );
  });

  testWidgets('reactions row renders counts', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatBubble(
          createdAt: _at,
          mine: false,
          body: 'Blessed',
          reactions: {'🙏': ['u-1', 'u-2']},
        ),
      ),
    ));
    expect(find.text('🙏 2'), findsOneWidget);
  });
}
