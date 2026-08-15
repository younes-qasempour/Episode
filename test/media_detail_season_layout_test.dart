import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/screens/media_detail_screen.dart';
import 'package:episode/theme/app_theme.dart';

void main() {
  group('BUG-010: MediaDetailScreen Season Item Layout on 360px Viewport', () {
    const seasonItem = MediaItem(
      id: 'season_show_1',
      title: 'Attack on Titan Long Running Show',
      coverUrl: '',
      currentProgress: 25,
      totalCount: 50,
      mediaType: 'series',
      status: 'Watching',
      releaseStatus: ReleaseStatus.ongoing,
      progressMode: ProgressMode.seasonal,
      seasons: [
        MediaSeason(
          id: 'season_1',
          seasonNumber: 1,
          title: 'Season 1 Shingeki no Kyojin Deluxe',
          currentProgress: 25,
          totalCount: 25,
          releaseStatus: ReleaseStatus.finished,
        ),
        MediaSeason(
          id: 'season_2',
          seasonNumber: 2,
          title: 'Season 2 Return to Shiganshina',
          currentProgress: 0,
          totalCount: 12,
          releaseStatus: ReleaseStatus.ongoing,
        ),
      ],
    );

    testWidgets('Renders season controls cleanly on 360px viewport without squeezing title or overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaDetailScreen(
            item: seasonItem,
            onSave: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      for (final err in errors) {
        debugPrint('FULL FLUTTER ERROR: ${err.exceptionAsString()} \n ${err.context} \n ${err.summary}');
      }
      expect(errors, isEmpty);

      // Verify season titles are fully visible
      expect(find.text('Season 1 Shingeki no Kyojin Deluxe'), findsOneWidget);
      expect(find.text('Season 2 Return to Shiganshina'), findsOneWidget);

      // Verify Completed badge and Complete Season button
      expect(find.text('Completed ✓'), findsOneWidget);
      expect(find.byKey(const Key('complete-season-season_2')), findsOneWidget);

      // Scroll and tap complete season 2
      await tester.ensureVisible(find.byKey(const Key('complete-season-season_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('complete-season-season_2')));
      await tester.pumpAndSettle();

      // Now season 2 should also be completed
      expect(find.text('Completed ✓'), findsNWidgets(2));
    });
  });
}
