import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nz_vege_garden/features/pests/pest_guide_screen.dart';

void main() {
  testWidgets('pest tracker and weather shell renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PestTrackerScreen(),
      ),
    );

    expect(find.text('Pest tracker'), findsOneWidget);
    expect(find.text('Weather information'), findsOneWidget);
  });
}
