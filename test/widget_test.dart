import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nz_vege_garden/features/pests/pest_guide_screen.dart';

void main() {
  testWidgets('pest tracker shell renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PestTrackerScreen(),
      ),
    );

    expect(find.text('Pest pressure tracker'), findsOneWidget);
    expect(find.text('Location pest pressure notifier'), findsOneWidget);
  });
}
