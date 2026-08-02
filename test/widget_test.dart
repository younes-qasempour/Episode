// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:otaku_log/main.dart';

void main() {
  testWidgets('OtakuLog app starts at the library shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'otaku_log_media_items': '[]',
    });
    await tester.pumpWidget(const OtakuLogApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
