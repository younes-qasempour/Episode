import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:episode/widgets/episode_brand.dart';

void main() {
  testWidgets('Episode brand asset resolves in light and dark themes', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(
            body: Center(child: EpisodeBrand(markSize: 48)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('episode-brand')), findsOneWidget);
      expect(find.text('Episode'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('Episode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
