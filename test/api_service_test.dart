import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/services/api_service.dart';

void main() {
  group('ApiService Data Mapping Tests', () {
    test('mapJikanAnimeToMediaItem correctly maps fields', () {
      final json = {
        'mal_id': 101,
        'title': 'Naruto Original',
        'title_english': 'Naruto',
        'images': {
          'jpg': {
            'large_image_url': 'https://example.com/naruto_large.jpg',
            'image_url': 'https://example.com/naruto.jpg',
          }
        },
        'episodes': 220,
        'synopsis': 'A young ninja seeks recognition.',
      };

      final item = ApiService.mapJikanAnimeToMediaItem(json);

      expect(item.id, equals('jikan_anime_101'));
      expect(item.title, equals('Naruto'));
      expect(item.coverUrl, equals('https://example.com/naruto_large.jpg'));
      expect(item.totalCount, equals(220));
      expect(item.mediaType, equals('anime'));
      expect(item.status, equals('Plan to Watch'));
      expect(item.synopsis, contains('ninja'));
    });

    test('mapJikanMangaToMediaItem correctly maps fields', () {
      final json = {
        'mal_id': 202,
        'title': 'One Piece',
        'images': {
          'jpg': {
            'image_url': 'https://example.com/onepiece.jpg',
          }
        },
        'chapters': 1080,
        'synopsis': 'Pirates searching for the ultimate treasure.',
      };

      final item = ApiService.mapJikanMangaToMediaItem(json);

      expect(item.id, equals('jikan_manga_202'));
      expect(item.title, equals('One Piece'));
      expect(item.coverUrl, equals('https://example.com/onepiece.jpg'));
      expect(item.totalCount, equals(1080));
      expect(item.mediaType, equals('manga'));
      expect(item.status, equals('Plan to Watch'));
    });

    test('mapTvMazeToShowItem correctly parses and strips HTML tags from summary', () {
      final show = {
        'id': 303,
        'name': 'Breaking Bad',
        'image': {
          'original': 'https://example.com/bb_orig.jpg',
          'medium': 'https://example.com/bb_med.jpg',
        },
        'summary': '<p>A chemistry teacher turns to <b>crime</b>.</p>',
      };

      final item = ApiService.mapTvMazeToShowItem(show);

      expect(item, isNotNull);
      expect(item!.id, equals('tvmaze_series_303'));
      expect(item.title, equals('Breaking Bad'));
      expect(item.coverUrl, equals('https://example.com/bb_orig.jpg'));
      expect(item.synopsis, equals('A chemistry teacher turns to crime.'));
      expect(item.mediaType, equals('series'));
    });
  });
}
