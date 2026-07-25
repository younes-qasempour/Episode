import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/screens/media_detail_screen.dart';

void main() {
  testWidgets(
    'MediaDetailScreen renders title, status, and allows save action',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testItem = MediaItem(
        id: 'detail_test_1',
        title: 'Fullmetal Alchemist',
        coverUrl: 'https://example.com/fma.jpg',
        currentProgress: 10,
        totalCount: 64,
        mediaType: 'anime',
        status: 'Watching',
        synopsis: 'Two brothers search for Philosopher Stone.',
        rating: 9.5,
      );

      MediaItem? savedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaDetailScreen(
            item: testItem,
            onSave: (item) {
              savedItem = item;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Fullmetal Alchemist'),
        findsNWidgets(2),
      ); // AppBar & Header
      expect(find.text('Watching'), findsWidgets);
      expect(find.text('Synopsis or personal description'), findsOneWidget);

      final saveButton = find.text('Save Changes');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedItem, isNotNull);
      expect(savedItem!.title, equals('Fullmetal Alchemist'));
    },
  );

  testWidgets('MediaDetailScreen triggers onDelete when delete confirmed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testItem = MediaItem(
      id: 'detail_test_2',
      title: 'Item To Delete',
      coverUrl: 'https://example.com/cover.jpg',
      currentProgress: 0,
      totalCount: 10,
      mediaType: 'series',
      status: 'Plan to Watch',
    );

    String? deletedId;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaDetailScreen(
          item: testItem,
          onDelete: (id) {
            deletedId = id;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Delete Media'), findsOneWidget);
    final confirmDeleteButton = find.text('Delete');
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    expect(deletedId, equals('detail_test_2'));
  });

  testWidgets(
    'progress can exceed total and is saved without auto-completion',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const testItem = MediaItem(
        id: 'beyond-detail',
        title: 'Ongoing Detail',
        coverUrl: '',
        currentProgress: 24,
        totalCount: 24,
        mediaType: 'anime',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
      );
      MediaItem? savedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaDetailScreen(
            item: testItem,
            onSave: (item) => savedItem = item,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('detail-increment-progress-button')),
      );
      await tester.pump();
      expect(
        find.text(
          'Progress exceeds the current total. It will be saved as entered.',
        ),
        findsOneWidget,
      );

      final saveButton = find.byKey(const Key('save-media-details-button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(savedItem?.currentProgress, 25);
      expect(savedItem?.trackingStatus, TrackingStatus.watching);
    },
  );

  testWidgets('unknown total renders as a question mark', (
    WidgetTester tester,
  ) async {
    const testItem = MediaItem(
      id: 'unknown-detail',
      title: 'Unknown Total',
      coverUrl: '',
      currentProgress: 18,
      totalCount: null,
      mediaType: 'manga',
      status: 'Reading',
    );

    await tester.pumpWidget(
      const MaterialApp(home: MediaDetailScreen(item: testItem)),
    );

    expect(find.text('18 / ? Ch'), findsOneWidget);
    final knownTotalSwitch = tester.widget<SwitchListTile>(
      find.byKey(const Key('detail-known-total-switch')),
    );
    expect(knownTotalSwitch.value, isFalse);
  });

  testWidgets('season can be added and edited', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const testItem = MediaItem(
      id: 'season-detail',
      title: 'Season Detail',
      coverUrl: '',
      currentProgress: 0,
      totalCount: null,
      mediaType: 'series',
      status: 'Watching',
      progressMode: ProgressMode.seasonal,
      seasons: [
        MediaSeason(
          id: 'season-1',
          seasonNumber: 1,
          currentProgress: 10,
          totalCount: 10,
          releaseStatus: ReleaseStatus.finished,
        ),
      ],
    );
    MediaItem? savedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaDetailScreen(
          item: testItem,
          onSave: (item) => savedItem = item,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('detail-add-season-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('season-progress-field')), '4');
    await tester.tap(find.byKey(const Key('save-season-button')));
    await tester.pumpAndSettle();
    expect(find.text('Season 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Season actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('season-title-field')),
      'Second Arc',
    );
    await tester.enterText(find.byKey(const Key('season-progress-field')), '5');
    await tester.tap(find.byKey(const Key('save-season-button')));
    await tester.pumpAndSettle();
    expect(find.text('Second Arc'), findsOneWidget);

    final saveButton = find.byKey(const Key('save-media-details-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(savedItem?.seasons, hasLength(2));
    expect(savedItem?.seasons.last.title, 'Second Arc');
    expect(savedItem?.seasons.last.currentProgress, 5);
  });

  testWidgets('movie detail hides episode controls', (
    WidgetTester tester,
  ) async {
    const testItem = MediaItem(
      id: 'movie-detail',
      title: 'Manual Movie',
      coverUrl: '',
      currentProgress: 0,
      totalCount: null,
      mediaType: 'movie',
      status: 'Completed',
      releaseStatus: ReleaseStatus.finished,
      isManual: true,
    );

    await tester.pumpWidget(
      const MaterialApp(home: MediaDetailScreen(item: testItem)),
    );

    expect(find.byKey(const Key('detail-progress-field')), findsNothing);
    expect(
      find.text(
        'Movies use tracking status and rating without an episode counter.',
      ),
      findsOneWidget,
    );
  });
}
