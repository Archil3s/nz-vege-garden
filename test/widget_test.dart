import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic smoke test renders MaterialApp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('NZ Vege Garden'),
        ),
      ),
    );

    expect(find.text('NZ Vege Garden'), findsOneWidget);
  });
}
