import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/theme/app_theme.dart';
import 'package:episode/widgets/media_card.dart';

void main() {
  group('BUG-002: MediaCard Adaptive Layout & Text Scale Tests', () {
    const baseItem = MediaItem(
      id: 'test_card_1',
      title: 'Attack on Titan: The Final Season Part 3 Very Long Title That Wraps Around Multi Lines',
      coverUrl: '',
      currentProgress: 12,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Watching',
      releaseStatus: ReleaseStatus.ongoing,
      progressMode: ProgressMode.flat,
      rating: 9.5,
      isFavorite: true,
    );

    Widget buildCardWidget({
      required MediaItem item,
      double textScaleFactor = 1.0,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: Center(
              child: SizedBox(
                width: 360,
                child: MediaCard(
                  item: item,
                  onTap: () {},
                  onIncrementProgress: () {},
                  onToggleFavorite: () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    final testCases = [
      ('Short Title at 1.0x', 'Bleach', 1.0),
      ('2-Line Title at 1.0x', 'Attack on Titan: The Final Season Part 3 Very Long Title', 1.0),
      ('2-Line Title at 1.3x Scale', 'Attack on Titan: The Final Season Part 3 Very Long Title', 1.3),
      ('2-Line Title at 1.5x Scale', 'Attack on Titan: The Final Season Part 3 Very Long Title', 1.5),
      ('2-Line Title at 2.0x Scale', 'Attack on Titan: The Final Season Part 3 Very Long Title', 2.0),
      ('Seasonal Progress at 1.5x Scale', 'Vinland Saga Season 2 Deluxe Edition', 1.5),
    ];

    for (final (label, title, scale) in testCases) {
      testWidgets('MediaCard renders with $label without any RenderFlex overflow', (tester) async {
        final item = baseItem.copyWith(title: title);
        await tester.pumpWidget(buildCardWidget(item: item, textScaleFactor: scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('MediaCard renders cleanly on ultra-narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaCard(
                item: baseItem,
                onTap: () {},
                onIncrementProgress: () {},
                onToggleFavorite: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
