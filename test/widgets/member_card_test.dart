import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/widgets/member_card.dart';
import 'package:isosha_esosheni/data/models/member.dart';

MemberCardData _data({
  bool matched = false,
  String? interestReceived,
  bool interestSent = false,
}) =>
    MemberCardData(
      id: 'u-1',
      displayName: 'Thabo Nkosi',
      age: 31,
      city: 'Johannesburg',
      province: 'Gauteng',
      profession: 'Engineer',
      intentions: const ['serious_relationship', 'marriage'],
      relationshipStatus: 'single',
      score: 86,
      reasons: const ['Same province'],
      matched: matched,
      interestReceived: interestReceived,
      interestSent: interestSent,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('discover variant shows name, score and Send interest',
      (tester) async {
    await tester.pumpWidget(_wrap(MemberCard(data: _data())));
    expect(find.text('Thabo Nkosi'), findsOneWidget);
    expect(find.text('86% compatible'), findsOneWidget);
    expect(find.text('Send interest'), findsOneWidget);
    expect(find.text('Serious relationship'), findsOneWidget);
    expect(find.text('Same province'), findsOneWidget);
  });

  testWidgets('matched variant shows the sage Matched pill', (tester) async {
    await tester.pumpWidget(_wrap(MemberCard(data: _data(matched: true))));
    expect(find.text('Matched'), findsOneWidget);
    expect(find.text('Send interest'), findsNothing);
  });

  testWidgets('received variant offers accept/decline', (tester) async {
    await tester.pumpWidget(_wrap(MemberCard(
      data: _data(interestReceived: 'i-2'),
      variant: CardActionVariant.received,
    )));
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('interest-sent state pill', (tester) async {
    await tester.pumpWidget(
        _wrap(MemberCard(data: _data(interestSent: true))));
    expect(find.text('Interest sent'), findsOneWidget);
  });

  testWidgets('household banner copy', (tester) async {
    await tester.pumpWidget(_wrap(MemberCard(
      data: MemberCardData(
        id: 'u-3',
        displayName: 'Sipho',
        relationshipStatus: 'married',
        household: const HouseholdInfo(wives: 2),
      ),
    )));
    expect(
      find.textContaining(
          'This household is seeking an additional wife, with each '
          "wife's consent."),
      findsOneWidget,
    );
  });
}
