// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leftright/main.dart';

void main() {
  testWidgets('home screen renders game mode and button', (WidgetTester tester) async {
    await tester.pumpWidget(const LeftRightApp());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('LeftRight Rush'), findsOneWidget);
    expect(find.text('Object Side Sprint'), findsOneWidget);
    expect(find.text('Arrow Rush'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Play'), findsNWidgets(2));
  });
}
