import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AyniPrimaryButton renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAyniTheme(),
        home: Scaffold(
          body: AyniPrimaryButton(label: 'Pedir ayuda', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Pedir ayuda'), findsOneWidget);
  });
}
