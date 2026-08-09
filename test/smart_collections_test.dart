import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';

void main() {
  group('Smart Collections Filtering Logic', () {
    final now = DateTime.utc(2026, 8, 8);
    final items = [
      MediaItem(
        id: '1',
        title: 'Attack on Titan',
        mediaType: 'anime',
        coverUrl: '',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
        rating: 9.5,
        isFavorite: true,
        currentProgress: 25,
        totalCount: 75,
        tags: const ['Binge Worthy'],
        createdAt: now,
        updatedAt: now,
      ),
      MediaItem(
        id: '2',
        title: 'Dragon Ball Z',
        mediaType: 'anime',
        coverUrl: '',
        status: 'Completed',
        releaseStatus: ReleaseStatus.finished,
        rating: 8.5,
        isFavorite: false,
        currentProgress: 291,
        totalCount: 291,
        tags: const ['Classic'],
        createdAt: now,
        updatedAt: now,
      ),
      MediaItem(
        id: '3',
        title: 'Casual Series',
        mediaType: 'series',
        coverUrl: '',
        status: 'Plan to Watch',
        releaseStatus: ReleaseStatus.upcoming,
        rating: 6.0,
        isFavorite: false,
        currentProgress: 0,
        totalCount: 12,
        tags: const [],
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('filters Favorites correctly', () {
      final favorites = items.where((i) => i.isFavorite).toList();
      expect(favorites.length, 1);
      expect(favorites.first.title, 'Attack on Titan');
    });

    test('filters Top Rated items (rating >= 8.0) correctly', () {
      final topRated = items.where((i) => i.rating >= 8.0).toList();
      expect(topRated.length, 2);
    });

    test('filters Binge Worthy items correctly', () {
      final bingeWorthy = items
          .where(
              (i) => i.tags.contains('Binge Worthy') || i.currentProgress > 10)
          .toList();
      expect(bingeWorthy.length, 2);
    });

    test('filters On-Going items correctly', () {
      final ongoing =
          items.where((i) => i.releaseStatus == ReleaseStatus.ongoing).toList();
      expect(ongoing.length, 1);
      expect(ongoing.first.title, 'Attack on Titan');
    });

    test('filters Classics correctly', () {
      final classics = items.where((i) => i.tags.contains('Classic')).toList();
      expect(classics.length, 1);
      expect(classics.first.title, 'Dragon Ball Z');
    });
  });
}
