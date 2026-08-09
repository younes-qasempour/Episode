import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/widgets/media_card.dart';

void main() {
  testWidgets('unknown totals display a question mark and can increment', (
    tester,
  ) async {
    var increments = 0;
    const item = MediaItem(
      id: 'unknown-card',
      title: 'Long Runner',
      coverUrl: '',
      currentProgress: 312,
      totalCount: null,
      mediaType: 'anime',
      status: 'Watching',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaCard(item: item, onIncrementProgress: () => increments++),
        ),
      ),
    );

    expect(find.text('312 / ? Ep'), findsOneWidget);
    await tester.tap(find.text('+1'));
    expect(increments, 1);
  });

  testWidgets(
    'progress beyond a known total remains visible and incrementable',
    (tester) async {
      var increments = 0;
      const item = MediaItem(
        id: 'beyond-card',
        title: 'New Episode',
        coverUrl: '',
        currentProgress: 25,
        totalCount: 24,
        mediaType: 'series',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaCard(
              item: item,
              onIncrementProgress: () => increments++,
            ),
          ),
        ),
      );

      expect(find.text('25 / 24 Ep'), findsOneWidget);
      await tester.tap(find.text('+1'));
      expect(increments, 1);
    },
  );

  testWidgets('seasonal card identifies the ongoing increment target', (
    tester,
  ) async {
    const item = MediaItem(
      id: 'season-card',
      title: 'Season Show',
      coverUrl: '',
      currentProgress: 0,
      totalCount: null,
      mediaType: 'anime',
      status: 'Watching',
      progressMode: ProgressMode.seasonal,
      seasons: [
        MediaSeason(
          id: 's3',
          seasonNumber: 3,
          currentProgress: 4,
          totalCount: 12,
          releaseStatus: ReleaseStatus.ongoing,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaCard(item: item, onIncrementProgress: () {}),
        ),
      ),
    );

    expect(find.text('Season 3 · 4 / 12 Ep'), findsOneWidget);
    expect(find.byTooltip('Add 1 episode to Season 3'), findsOneWidget);
  });

  testWidgets('movie card does not render progress or +1', (tester) async {
    const item = MediaItem(
      id: 'movie-card',
      title: 'Movie',
      coverUrl: '',
      currentProgress: 0,
      totalCount: null,
      mediaType: 'movie',
      status: 'Completed',
      releaseStatus: ReleaseStatus.finished,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaCard(item: item, onIncrementProgress: () {}),
        ),
      ),
    );

    expect(find.text('Finished release'), findsOneWidget);
    expect(find.text('+1'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
