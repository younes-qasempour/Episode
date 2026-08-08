import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/repositories/search_repository.dart';
import 'package:episode/services/api_service.dart';

class MockApiService extends ApiService {
  final List<MediaItem> mockAnime;
  final List<MediaItem> mockManga;
  final List<MediaItem> mockSeries;
  final bool shouldThrow;

  MockApiService({
    this.mockAnime = const [],
    this.mockManga = const [],
    this.mockSeries = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<MediaItem>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
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

    return results;
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

      final results = await repository.searchMedia('test', category: 'All');

      expect(results.length, equals(3));
      expect(results, contains(animeItem));
      expect(results, contains(mangaItem));
      expect(results, contains(seriesItem));
    });

    test('searchMedia returns only Anime when category is Anime', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final results = await repository.searchMedia('test', category: 'Anime');

      expect(results.length, equals(1));
      expect(results.first.mediaType, equals('anime'));
    });

    test('searchMedia returns only Manga when category is Manga', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final results = await repository.searchMedia('test', category: 'Manga');

      expect(results.length, equals(1));
      expect(results.first.mediaType, equals('manga'));
    });

    test('searchMedia returns only Series when category is Series', () async {
      final mockService = MockApiService(
        mockAnime: [animeItem],
        mockManga: [mangaItem],
        mockSeries: [seriesItem],
      );
      final repository = SearchRepository(apiService: mockService);

      final results = await repository.searchMedia('test', category: 'Series');

      expect(results.length, equals(1));
      expect(results.first.mediaType, equals('series'));
    });

    test('searchMedia throws exception on network failure', () async {
      final mockService = MockApiService(shouldThrow: true);
      final repository = SearchRepository(apiService: mockService);

      expect(() => repository.searchMedia('test'), throwsA(isA<Exception>()));
    });
  });
}
