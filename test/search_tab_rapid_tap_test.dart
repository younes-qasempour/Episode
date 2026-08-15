import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/repositories/search_repository.dart';
import 'package:episode/screens/search_tab.dart';
import 'package:episode/services/api_service.dart';
import 'package:episode/theme/app_theme.dart';

class _TestApiService extends ApiService {
  final List<MediaItem> items;
  _TestApiService(this.items);

  @override
  Future<SearchResult<List<MediaItem>>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    return SearchSuccess(items);
  }
}

void main() {
  group('BUG-005: SearchTab Rapid Tap Debounce & Deduplication Tests', () {
    const searchResultItem = MediaItem(
      id: 'search_item_1',
      title: 'Steins;Gate',
      coverUrl: '',
      currentProgress: 0,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Plan to Watch',
    );

    testWidgets('Rapid multiple taps on Add to Library trigger callback exactly once', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int addCallCount = 0;
      final existingItems = <MediaItem>[];

      final repo = SearchRepository(apiService: _TestApiService([searchResultItem]));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SearchTab(
              searchRepository: repo,
              existingItems: existingItems,
              onAddToLibrary: (item) {
                addCallCount++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Add to Library button
      final addBtn = find.widgetWithText(ElevatedButton, 'Add to Library');
      expect(addBtn, findsOneWidget);

      // Perform 3 rapid taps
      await tester.tap(addBtn);
      await tester.tap(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Must have only been called once!
      expect(addCallCount, 1);

      // Button must now show 'In Library'
      expect(find.text('In Library'), findsOneWidget);
    });
  });
}
