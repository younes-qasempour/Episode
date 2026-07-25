import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';
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
          },
        },
        'episodes': 220,
        'status': 'Currently Airing',
        'synopsis': 'A young ninja seeks recognition.',
      };

      final item = ApiService.mapJikanAnimeToMediaItem(json);

      expect(item.id, equals('jikan_anime_101'));
      expect(item.title, equals('Naruto'));
      expect(item.coverUrl, equals('https://example.com/naruto_large.jpg'));
      expect(item.totalCount, equals(220));
      expect(item.mediaType, equals('anime'));
      expect(item.status, equals('Plan to Watch'));
      expect(item.releaseStatus, ReleaseStatus.ongoing);
      expect(item.synopsis, contains('ninja'));
    });

    test('mapJikanMangaToMediaItem correctly maps fields', () {
      final json = {
        'mal_id': 202,
        'title': 'One Piece',
        'images': {
          'jpg': {'image_url': 'https://example.com/onepiece.jpg'},
        },
        'chapters': 1080,
        'status': 'Finished',
        'synopsis': 'Pirates searching for the ultimate treasure.',
      };

      final item = ApiService.mapJikanMangaToMediaItem(json);

      expect(item.id, equals('jikan_manga_202'));
      expect(item.title, equals('One Piece'));
      expect(item.coverUrl, equals('https://example.com/onepiece.jpg'));
      expect(item.totalCount, equals(1080));
      expect(item.mediaType, equals('manga'));
      expect(item.status, equals('Plan to Watch'));
      expect(item.releaseStatus, ReleaseStatus.finished);
    });

    test(
      'mapTvMazeToShowItem correctly parses and strips HTML tags from summary',
      () {
        final show = {
          'id': 303,
          'name': 'Breaking Bad',
          'image': {
            'original': 'https://example.com/bb_orig.jpg',
            'medium': 'https://example.com/bb_med.jpg',
          },
          'summary': '<p>A chemistry teacher turns to <b>crime</b>.</p>',
          'status': 'Ended',
        };

        final item = ApiService.mapTvMazeToShowItem(show);

        expect(item, isNotNull);
        expect(item!.id, equals('tvmaze_series_303'));
        expect(item.title, equals('Breaking Bad'));
        expect(item.coverUrl, equals('https://example.com/bb_orig.jpg'));
        expect(item.synopsis, equals('A chemistry teacher turns to crime.'));
        expect(item.mediaType, equals('series'));
        expect(item.totalCount, isNull);
        expect(item.releaseStatus, ReleaseStatus.finished);
      },
    );

    test('missing and zero Jikan counts map to unknown', () {
      final anime = ApiService.mapJikanAnimeToMediaItem({
        'mal_id': 404,
        'title': 'Unknown Anime',
        'episodes': 0,
      });
      final manga = ApiService.mapJikanMangaToMediaItem({
        'mal_id': 405,
        'title': 'Unknown Manga',
      });

      expect(anime.totalCount, isNull);
      expect(manga.totalCount, isNull);
    });

    test('provider release status maps defensively', () {
      final hiatusManga = ApiService.mapJikanMangaToMediaItem({
        'mal_id': 406,
        'title': 'Paused Manga',
        'status': 'On Hiatus',
      });
      final unknownAnime = ApiService.mapJikanAnimeToMediaItem({
        'mal_id': 407,
        'title': 'Mystery Anime',
        'status': 'Unexpected Provider Value',
      });
      final runningSeries = ApiService.mapTvMazeToShowItem({
        'id': 408,
        'name': 'Running Series',
        'status': 'Running',
      });

      expect(hiatusManga.releaseStatus, ReleaseStatus.hiatus);
      expect(unknownAnime.releaseStatus, ReleaseStatus.unknown);
      expect(runningSeries?.releaseStatus, ReleaseStatus.ongoing);
      expect(runningSeries?.totalCount, isNull);
    });
  });
}
