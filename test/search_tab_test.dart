import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/search_repository.dart';
import 'package:otaku_log/screens/search_tab.dart';
import 'package:otaku_log/services/api_service.dart';

class TestApiService extends ApiService {
  final List<MediaItem> items;

  TestApiService(this.items);

  @override
  Future<List<MediaItem>> searchMedia(String query, {String category = 'All'}) async {
    final catLower = category.toLowerCase();
    if (catLower == 'all') return items;
    return items.where((i) => i.mediaType.toLowerCase() == catLower).toList();
  }
}

void main() {
  testWidgets('SearchTab renders search input, category chips, and search results', (WidgetTester tester) async {
    final mockItem = const MediaItem(
      id: 'jikan_anime_999',
      title: 'Steins;Gate',
      coverUrl: 'https://example.com/steinsgate.jpg',
      currentProgress: 0,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Plan to Watch',
    );

    final repository = SearchRepository(apiService: TestApiService([mockItem]));

    await tester.pumpWidget(
      MaterialApp(
        home: SearchTab(
          searchRepository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Live Media Search'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Steins;Gate'), findsOneWidget);
    expect(find.text('Add to Library'), findsOneWidget);
  });

  testWidgets('SearchTab displays "In Library" when item is already in existingItems', (WidgetTester tester) async {
    final mockItem = const MediaItem(
      id: 'jikan_anime_999',
      title: 'Steins;Gate',
      coverUrl: 'https://example.com/steinsgate.jpg',
      currentProgress: 0,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Plan to Watch',
    );

    final repository = SearchRepository(apiService: TestApiService([mockItem]));

    await tester.pumpWidget(
      MaterialApp(
        home: SearchTab(
          searchRepository: repository,
          existingItems: [mockItem],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('In Library'), findsOneWidget);
  });

  testWidgets('Tapping Add to Library triggers onAddToLibrary callback', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockItem = const MediaItem(
      id: 'jikan_anime_999',
      title: 'Steins;Gate',
      coverUrl: 'https://example.com/steinsgate.jpg',
      currentProgress: 0,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Plan to Watch',
    );

    MediaItem? addedItem;
    final repository = SearchRepository(apiService: TestApiService([mockItem]));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchTab(
            searchRepository: repository,
            onAddToLibrary: (item) {
              addedItem = item;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = find.byType(ElevatedButton);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pump();

    expect(addedItem, equals(mockItem));
  });
}
