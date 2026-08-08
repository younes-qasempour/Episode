import 'package:episode/models/library_stats.dart';
import 'package:episode/models/media_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryStats Calculations', () {
    test('calculates correct stats for an empty library', () {
      final stats = LibraryStats.fromItems([]);

      expect(stats.totalItems, 0);
      expect(stats.totalEpisodesWatched, 0);
      expect(stats.totalChaptersRead, 0);
      expect(stats.totalMoviesWatched, 0);
      expect(stats.meanScore, 0.0);
      expect(stats.ratedItemCount, 0);
      expect(stats.mediaTypeSegments, isEmpty);
      expect(stats.statusSegments, isEmpty);
      expect(stats.topGenres, isEmpty);
    });

    test('calculates episodes, chapters, movies, and mean score correctly', () {
      final items = <MediaItem>[
        const MediaItem(
          id: '1',
          title: 'Naruto',
          coverUrl: '',
          currentProgress: 100,
          totalCount: 220,
          mediaType: 'anime',
          status: 'Watching',
          rating: 8.0,
          tags: ['Action', 'Ninja', 'Shounen'],
        ),
        const MediaItem(
          id: '2',
          title: 'One Piece Manga',
          coverUrl: '',
          currentProgress: 500,
          totalCount: 1000,
          mediaType: 'manga',
          status: 'Reading',
          rating: 9.0,
          tags: ['Action', 'Adventure'],
        ),
        const MediaItem(
          id: '3',
          title: 'Your Name Movie',
          coverUrl: '',
          currentProgress: 1,
          totalCount: 1,
          mediaType: 'movie',
          status: 'Completed',
          rating: 10.0,
          tags: ['Drama', 'Romance'],
        ),
        const MediaItem(
          id: '4',
          title: 'Breaking Bad',
          coverUrl: '',
          currentProgress: 62,
          totalCount: 62,
          mediaType: 'series',
          status: 'Completed',
          rating: 9.0,
          tags: ['Drama', 'Crime'],
        ),
        const MediaItem(
          id: '5',
          title: 'Unrated Anime',
          coverUrl: '',
          currentProgress: 10,
          totalCount: 12,
          mediaType: 'anime',
          status: 'Plan to Watch',
          rating: 0.0,
          tags: ['Action'],
        ),
      ];

      final stats = LibraryStats.fromItems(items);

      expect(stats.totalItems, 5);
      expect(stats.totalEpisodesWatched, 172); // 100 + 62 + 10
      expect(stats.totalChaptersRead, 500);
      expect(stats.totalMoviesWatched, 1);
      expect(stats.ratedItemCount, 4);
      // (8 + 9 + 10 + 9) / 4 = 36 / 4 = 9.0
      expect(stats.meanScore, 9.0);
      expect(stats.topGenres.first, 'Action');
      expect(stats.mediaTypeSegments.length, 4);
      expect(stats.statusSegments.length, 4);
    });
  });
}
