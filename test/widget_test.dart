// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:myfeed/main.dart';

void main() {
  testWidgets('MyFeed app starts', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyFeedApp());

    // Verify that the app starts (we see the app bar title)
    expect(find.text('MyFeed'), findsOneWidget);
  });
}
