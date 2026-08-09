import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/repositories/search_repository.dart';
import 'package:episode/services/api_service.dart';

class MockApiService extends ApiService {
  final List<MediaItem> mockAnime;
  final List<MediaItem> mockManga;
  final List<MediaItem> mockSeries;
  final SearchFailure<List<MediaItem>>? mockFailure;

  MockApiService({
    this.mockAnime = const [],
    this.mockManga = const [],
    this.mockSeries = const [],
    this.mockFailure,
  });

  @override
  Future<SearchResult<List<MediaItem>>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    if (mockFailure != null) {
      return mockFailure!;
    }

    final catLower = category.toLowerCase();
    final List<MediaItem> results = [];

    if (catLower == 'all' || catLower == 'anime') {
      results.addAll(mockAnime);
    }
    if (catLower == 'all' || catLower == 'manga') {
      results.addAll(mockManga);
    }
    if (catLower == 'all' || catLower == 'series') {
      results.addAll(mockSeries);
    }

    return SearchSuccess(results);
  }
}

void main() {
  group('SearchRepository Tests', () {
    const animeItem = MediaItem(
      id: 'jikan_anime_1',
      title: 'Anime Test',
      coverUrl: 'https://example.com/anime.jpg',
      currentProgress: 0,
      totalCount: 12,
      mediaType: 'anime',
      status: 'Plan to Watch',
    );

    const mangaItem = MediaItem(
      id: 'jikan_manga_2',
      title: 'Manga Test',
      coverUrl: 'https://example.com/manga.jpg',
      currentProgress: 0,
      totalCount: 50,
      mediaType: 'manga',
      status: 'Plan to Watch',
    );

    const seriesItem = MediaItem(
      id: 'tvmaze_series_3',
      title: 'Series Test',
      coverUrl: 'https://example.com/series.jpg',
      currentProgress: 0,
      totalCount: 10,
      mediaType: 'series',
      status: 'Plan to Watch',
    );

    test('searchMedia returns all categories when category is All', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final result = await repository.searchMedia('test', category: 'All');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(3));
      expect(success.data, contains(animeItem));
      expect(success.data, contains(mangaItem));
      expect(success.data, contains(seriesItem));
    });

    test('searchMedia returns only Anime when category is Anime', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final result = await repository.searchMedia('test', category: 'Anime');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(1));
      expect(success.data.first.mediaType, equals('anime'));
    });

    test('searchMedia returns only Manga when category is Manga', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final result = await repository.searchMedia('test', category: 'Manga');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(1));
      expect(success.data.first.mediaType, equals('manga'));
    });

    test('searchMedia returns only Series when category is Series', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final result = await repository.searchMedia('test', category: 'Series');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(1));
      expect(success.data.first.mediaType, equals('series'));
    });

    test('searchMedia returns SearchFailure on network failure', () async {
      final mockService = MockApiService(
        mockFailure: const SearchFailure<List<MediaItem>>(
            type: SearchFailureType.network),
      );
      final repository = SearchRepository(apiService: mockService);

      final result = await repository.searchMedia('test');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.network));
    });
  });
}
