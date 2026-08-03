import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/screens/home_tab.dart';
import 'package:otaku_log/widgets/media_card.dart';

void main() {
  final sampleItems = [
    MediaItem(
      id: '1',
      title: 'Attack on Titan',
      coverUrl: '',
      currentProgress: 24,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Completed',
      rating: 9.5,
      isFavorite: true,
      updatedAt: DateTime(2026, 7, 28),
    ),
    MediaItem(
      id: '2',
      title: 'One Piece',
      coverUrl: '',
      currentProgress: 100,
      totalCount: 1000,
      mediaType: 'manga',
      status: 'Watching',
      rating: 9.0,
      isFavorite: false,
      updatedAt: DateTime(2026, 7, 29),
    ),
    MediaItem(
      id: '3',
      title: 'Breaking Bad',
      coverUrl: '',
      currentProgress: 5,
      totalCount: 62,
      mediaType: 'series',
      status: 'Watching',
      rating: 8.5,
      isFavorite: false,
      updatedAt: DateTime(2026, 7, 27),
    ),
  ];

  Widget buildHomeTab({
    List<MediaItem>? items,
    Function(String id)? onIncrement,
    Function(String id)? onToggleFavorite,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeTab(
          mediaItems: items ?? sampleItems,
          onIncrementProgress: onIncrement ?? (_) {},
          onToggleFavorite: onToggleFavorite,
        ),
      ),
    );
  }

  testWidgets('filters items by in-library title search', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    expect(find.byType(MediaCard), findsNWidgets(3));

    await tester.enterText(find.byType(TextField), 'titan');
    await tester.pumpAndSettle();

    expect(find.byType(MediaCard), findsOneWidget);
    expect(find.text('Attack on Titan'), findsOneWidget);
    expect(find.text('One Piece'), findsNothing);
  });

  testWidgets('clear search button clears search text', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.enterText(find.byType(TextField), 'titan');
    await tester.pumpAndSettle();
    expect(find.byType(MediaCard), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byType(MediaCard), findsNWidgets(3));
  });

  testWidgets('filters items by Media Type filter chips', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.tap(find.widgetWithText(ChoiceChip, 'Manga'));
    await tester.pumpAndSettle();

    expect(find.byType(MediaCard), findsOneWidget);
    expect(find.text('One Piece'), findsOneWidget);
  });

  testWidgets('filters items by Status filter chips (Favorites)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.tap(find.widgetWithText(ChoiceChip, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(MediaCard), findsOneWidget);
    expect(find.text('Attack on Titan'), findsOneWidget);
  });

  testWidgets('sorts library by Title (A-Z)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.tap(find.byTooltip('Sort Options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Title (A-Z)').last);
    await tester.pumpAndSettle();

    final cardTitles = tester
        .widgetList<MediaCard>(find.byType(MediaCard))
        .map((c) => c.item.title)
        .toList();

    expect(cardTitles, ['Attack on Titan', 'Breaking Bad', 'One Piece']);
  });

  testWidgets('sorts library by Rating (High → Low)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.tap(find.byTooltip('Sort Options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rating (High → Low)').last);
    await tester.pumpAndSettle();

    final cardTitles = tester
        .widgetList<MediaCard>(find.byType(MediaCard))
        .map((c) => c.item.title)
        .toList();

    expect(cardTitles, ['Attack on Titan', 'One Piece', 'Breaking Bad']);
  });

  testWidgets('toggles favorite on card tap', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? favoritedId;
    await tester.pumpWidget(
      buildHomeTab(onToggleFavorite: (id) => favoritedId = id),
    );

    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();

    expect(favoritedId, '2');
  });

  testWidgets('shows empty state with reset button when no filters match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeTab());

    await tester.enterText(find.byType(TextField), 'nonexistent title');
    await tester.pumpAndSettle();

    expect(find.text('No media items match your filter'), findsOneWidget);
    final resetButton = find.text('Reset filters & search');
    expect(resetButton, findsOneWidget);

    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(find.byType(MediaCard), findsNWidgets(3));
  });
}
