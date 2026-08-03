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
