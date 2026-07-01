import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carpool_app/screens/passenger/customer_request_screen.dart';

void main() {
  testWidgets('Customer request screen shows simple post form', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerRequestScreen()),
    );
    await tester.pump();

    expect(find.text('Post Ride Request'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Day and time'), findsOneWidget);
    expect(find.text('Post request'), findsOneWidget);
  });
}
