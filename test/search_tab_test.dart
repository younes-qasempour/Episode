import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/repositories/search_repository.dart';
import 'package:episode/screens/search_tab.dart';
import 'package:episode/services/api_service.dart';

class TestApiService extends ApiService {
  final List<MediaItem> items;
  final SearchFailure<List<MediaItem>>? failure;

  TestApiService(this.items, {this.failure});

  @override
  Future<SearchResult<List<MediaItem>>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    if (failure != null) {
      return failure!;
    }
    final catLower = category.toLowerCase();
    if (catLower == 'all') return SearchSuccess(items);
    final filtered =
        items.where((i) => i.mediaType.toLowerCase() == catLower).toList();
    return SearchSuccess(filtered);
  }
}

void main() {
  testWidgets(
    'SearchTab renders search input, category chips, and search results',
    (WidgetTester tester) async {
      const mockItem = MediaItem(
        id: 'jikan_anime_999',
        title: 'Steins;Gate',
        coverUrl: 'https://example.com/steinsgate.jpg',
        currentProgress: 0,
        totalCount: 24,
        mediaType: 'anime',
        status: 'Plan to Watch',
      );

      final repository = SearchRepository(
        apiService: TestApiService([mockItem]),
      );

      await tester.pumpWidget(
        MaterialApp(home: SearchTab(searchRepository: repository)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Live Media Search'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text("Can't find it? Add manually"), findsOneWidget);
      expect(find.text('Steins;Gate'), findsOneWidget);
      expect(find.text('Add to Library'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchTab displays "In Library" when item is already in existingItems',
    (WidgetTester tester) async {
      const mockItem = MediaItem(
        id: 'jikan_anime_999',
        title: 'Steins;Gate',
        coverUrl: 'https://example.com/steinsgate.jpg',
        currentProgress: 0,
        totalCount: 24,
        mediaType: 'anime',
        status: 'Plan to Watch',
      );

      final repository = SearchRepository(
        apiService: TestApiService([mockItem]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SearchTab(
            searchRepository: repository,
            existingItems: const [mockItem],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('In Library'), findsOneWidget);
    },
  );

  testWidgets('Tapping Add to Library triggers onAddToLibrary callback', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const mockItem = MediaItem(
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

  testWidgets(
    'SearchTab displays Empty State on empty SearchSuccess',
    (WidgetTester tester) async {
      final repository = SearchRepository(apiService: TestApiService([]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.manage_search_rounded), findsOneWidget);
      expect(find.text('No results found for ""'), findsOneWidget);
      expect(find.byKey(const Key('search-retry-button')), findsNothing);
    },
  );

  testWidgets(
    'SearchTab displays Network Error UI on SearchFailure.network',
    (WidgetTester tester) async {
      final repository = SearchRepository(
        apiService: TestApiService(
          [],
          failure: const SearchFailure<List<MediaItem>>(
            type: SearchFailureType.network,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text('Please check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('search-retry-button')), findsOneWidget);
    },
  );

  testWidgets(
    'SearchTab displays Rate Limit UI on SearchFailure.rateLimited',
    (WidgetTester tester) async {
      final repository = SearchRepository(
        apiService: TestApiService(
          [],
          failure: const SearchFailure<List<MediaItem>>(
            type: SearchFailureType.rateLimited,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate Limit Exceeded'), findsOneWidget);
      expect(
        find.text('Too many requests. Please wait a moment and try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('search-retry-button')), findsOneWidget);
    },
  );

  testWidgets(
    'Retry button re-sends query and category and updates UI on success',
    (WidgetTester tester) async {
      final controlledApi = ControlledApiService();
      final repository = SearchRepository(apiService: controlledApi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );

      const initialKey = ':All';
      controlledApi.completers[initialKey]!.complete(
        const SearchFailure<List<MediaItem>>(
          type: SearchFailureType.network,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);

      final retryButton = find.byKey(const Key('search-retry-button'));
      expect(retryButton, findsOneWidget);

      // Tap Retry
      await tester.tap(retryButton);
      await tester.pump();

      // Ensure a new request was dispatched with the same key
      const retryKey = ':All';
      expect(controlledApi.completers.containsKey(retryKey), isTrue);

      const item = MediaItem(
        id: 'jikan_anime_500',
        title: 'Retried Item',
        coverUrl: 'https://example.com/item.jpg',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Plan to Watch',
      );

      controlledApi.completers[retryKey]!.complete(const SearchSuccess([item]));
      await tester.pumpAndSettle();

      // Error state must be cleared and item displayed
      expect(find.text('No Internet Connection'), findsNothing);
      expect(find.text('Retried Item'), findsOneWidget);
    },
  );

  testWidgets(
    'SearchTab discards out-of-order failure from older request',
    (WidgetTester tester) async {
      final controlledApi = ControlledApiService();
      final repository = SearchRepository(apiService: controlledApi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );

      const initialKey = ':All';
      controlledApi.completers[initialKey]!.complete(const SearchSuccess([]));
      await tester.pumpAndSettle();

      // Query 1: Naruto
      await tester.enterText(find.byType(TextField), 'Naruto');
      await tester.pump(const Duration(milliseconds: 600));

      // Query 2: One Piece
      await tester.enterText(find.byType(TextField), 'One Piece');
      await tester.pump(const Duration(milliseconds: 600));

      const newerItem = MediaItem(
        id: 'jikan_anime_1002',
        title: 'One Piece',
        coverUrl: 'https://example.com/onepiece.jpg',
        currentProgress: 0,
        totalCount: 1000,
        mediaType: 'anime',
        status: 'Watching',
      );

      // Complete newer request with success
      controlledApi.completers['One Piece:All']!
          .complete(const SearchSuccess([newerItem]));
      await tester.pumpAndSettle();

      // Complete older request with failure
      controlledApi.completers['Naruto:All']!.complete(
        const SearchFailure<List<MediaItem>>(
          type: SearchFailureType.network,
        ),
      );
      await tester.pumpAndSettle();

      // Newer success must remain displayed; older failure must not be shown
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'One Piece'),
        findsOneWidget,
      );
      expect(find.text('No Internet Connection'), findsNothing);
    },
  );

  testWidgets(
    'SearchTab discards out-of-order success from older request over newer failure',
    (WidgetTester tester) async {
      final controlledApi = ControlledApiService();
      final repository = SearchRepository(apiService: controlledApi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );

      const initialKey = ':All';
      controlledApi.completers[initialKey]!.complete(const SearchSuccess([]));
      await tester.pumpAndSettle();

      // Query 1: Naruto
      await tester.enterText(find.byType(TextField), 'Naruto');
      await tester.pump(const Duration(milliseconds: 600));

      // Query 2: One Piece
      await tester.enterText(find.byType(TextField), 'One Piece');
      await tester.pump(const Duration(milliseconds: 600));

      // Complete newer request with Network Failure
      controlledApi.completers['One Piece:All']!.complete(
        const SearchFailure<List<MediaItem>>(
          type: SearchFailureType.network,
        ),
      );
      await tester.pumpAndSettle();

      // Complete older request with Success
      const olderItem = MediaItem(
        id: 'jikan_anime_1001',
        title: 'Naruto',
        coverUrl: 'https://example.com/naruto.jpg',
        currentProgress: 0,
        totalCount: 220,
        mediaType: 'anime',
        status: 'Completed',
      );
      controlledApi.completers['Naruto:All']!
          .complete(const SearchSuccess([olderItem]));
      await tester.pumpAndSettle();

      // Newer failure must remain displayed; older delayed success must not overwrite it
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Naruto'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SearchTab discards out-of-order responses from older requests',
    (WidgetTester tester) async {
      final controlledApi = ControlledApiService();
      final repository = SearchRepository(apiService: controlledApi);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTab(searchRepository: repository),
          ),
        ),
      );

      // Initial empty search was triggered in initState
      const initialKey = ':All';
      expect(controlledApi.completers.containsKey(initialKey), isTrue);
      controlledApi.completers[initialKey]!.complete(const SearchSuccess([]));
      await tester.pumpAndSettle();

      // Trigger first query "Naruto"
      await tester.enterText(find.byType(TextField), 'Naruto');
      await tester.pump(
          const Duration(milliseconds: 600)); // advance past debounce timer

      const firstKey = 'Naruto:All';
      expect(controlledApi.completers.containsKey(firstKey), isTrue);

      // Trigger second query "One Piece"
      await tester.enterText(find.byType(TextField), 'One Piece');
      await tester.pump(
          const Duration(milliseconds: 600)); // advance past debounce timer

      const secondKey = 'One Piece:All';
      expect(controlledApi.completers.containsKey(secondKey), isTrue);

      const newerItem = MediaItem(
        id: 'jikan_anime_1002',
        title: 'One Piece',
        coverUrl: 'https://example.com/onepiece.jpg',
        currentProgress: 0,
        totalCount: 1000,
        mediaType: 'anime',
        status: 'Watching',
      );

      const olderItem = MediaItem(
        id: 'jikan_anime_1001',
        title: 'Naruto',
        coverUrl: 'https://example.com/naruto.jpg',
        currentProgress: 0,
        totalCount: 220,
        mediaType: 'anime',
        status: 'Completed',
      );

      // Complete the SECOND (newer) request first
      controlledApi.completers[secondKey]!
          .complete(const SearchSuccess([newerItem]));
      await tester.pumpAndSettle();

      final onePieceCardTitle = find.byWidgetPredicate(
        (w) => w is Text && w.data == 'One Piece',
      );
      expect(onePieceCardTitle, findsOneWidget);

      // Now complete the FIRST (older, delayed) request
      controlledApi.completers[firstKey]!
          .complete(const SearchSuccess([olderItem]));
      await tester.pumpAndSettle();

      // Newer result must remain displayed; older delayed result must be discarded
      expect(onePieceCardTitle, findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Naruto'),
        findsNothing,
      );
    },
  );
}

class ControlledApiService extends ApiService {
  final Map<String, Completer<SearchResult<List<MediaItem>>>> completers = {};

  @override
  Future<SearchResult<List<MediaItem>>> searchMedia(
    String query, {
    String category = 'All',
  }) {
    final key = '$query:$category';
    final completer = Completer<SearchResult<List<MediaItem>>>();
    completers[key] = completer;
    return completer.future;
  }
}
