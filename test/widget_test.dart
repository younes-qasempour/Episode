import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:episode/main.dart';

void main() {
  testWidgets('Episode app starts at the library shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'episode_media_items': '[]',
    });
    await tester.pumpWidget(const EpisodeApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const Key('episode-brand')), findsWidgets);
    expect(find.text('Episode'), findsWidgets);
  });
}
