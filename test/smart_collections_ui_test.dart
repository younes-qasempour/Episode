import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/screens/home_tab.dart';
import 'package:episode/theme/app_theme.dart';

void main() {
  group('BUG-001: Smart Collections UI in HomeTab', () {
    final now = DateTime.utc(2026, 8, 15);
    final items = [
      MediaItem(
        id: '1',
        title: 'Attack on Titan',
        mediaType: 'anime',
        coverUrl: '',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
        rating: 9.5,
        isFavorite: true,
        currentProgress: 25,
        totalCount: 75,
        tags: const ['Binge Worthy'],
        createdAt: now,
        updatedAt: now,
      ),
      MediaItem(
        id: '2',
        title: 'Dragon Ball Z',
        mediaType: 'anime',
        coverUrl: '',
        status: 'Completed',
        releaseStatus: ReleaseStatus.finished,
        rating: 8.5,
        isFavorite: false,
        currentProgress: 291,
        totalCount: 291,
        tags: const ['Classic'],
        createdAt: now,
        updatedAt: now,
      ),
      MediaItem(
        id: '3',
        title: 'Casual Series',
        mediaType: 'series',
        coverUrl: '',
        status: 'Plan to Watch',
        releaseStatus: ReleaseStatus.upcoming,
        rating: 6.0,
        isFavorite: false,
        currentProgress: 0,
        totalCount: 12,
        tags: const [],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    Widget createTestWidget({ThemeMode themeMode = ThemeMode.light}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: HomeTab(
            mediaItems: items,
            onIncrementProgress: (_) {},
            onToggleFavorite: (_) {},
          ),
        ),
      );
    }

    testWidgets('Smart Collection chips are rendered and filter items', (tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify all items are initially shown
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Dragon Ball Z'), findsOneWidget);
      expect(find.text('Casual Series'), findsOneWidget);

      // Verify Smart Collection chip exists
      final classicsChip = find.text('🏆 Classics');
      expect(classicsChip, findsOneWidget);

      // Tap on '🏆 Classics'
      await tester.tap(classicsChip);
      await tester.pumpAndSettle();

      // Only Dragon Ball Z (which has tag 'Classic') should remain
      expect(find.text('Dragon Ball Z'), findsOneWidget);
      expect(find.text('Attack on Titan'), findsNothing);
      expect(find.text('Casual Series'), findsNothing);

      // Tap on '🌟 Favorites'
      final favoritesChip = find.text('🌟 Favorites');
      expect(favoritesChip, findsOneWidget);
      await tester.tap(favoritesChip);
      await tester.pumpAndSettle();

      // Only Attack on Titan (isFavorite = true) should remain
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Dragon Ball Z'), findsNothing);
      expect(find.text('Casual Series'), findsNothing);

      // Tap on '⭐ Top Rated'
      final topRatedChip = find.text('⭐ Top Rated');
      expect(topRatedChip, findsOneWidget);
      await tester.tap(topRatedChip);
      await tester.pumpAndSettle();

      // Items with rating >= 8.0 (AoT: 9.5, DBZ: 8.5)
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Dragon Ball Z'), findsOneWidget);
      expect(find.text('Casual Series'), findsNothing);

      // Tap on 'All' collections chip to restore all items
      final allChip = find.text('All Collections');
      expect(allChip, findsOneWidget);
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Dragon Ball Z'), findsOneWidget);
      expect(find.text('Casual Series'), findsOneWidget);
    });

    testWidgets('Smart Collection chips render cleanly on 360px viewport in dark mode', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('All Collections'), findsOneWidget);
    });
  });
}
