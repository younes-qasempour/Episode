import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/main.dart';

void main() {
  testWidgets('OtakuLogApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OtakuLogApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OtakuLogApp), findsOneWidget);
  });
}
