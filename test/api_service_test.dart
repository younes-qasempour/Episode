import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/services/api_service.dart';

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

    test(
        'sanitizeCoverUrl handles null, empty, standard, and Kitsu URLs correctly',
        () {
      expect(ApiService.sanitizeCoverUrl(null), equals(''));
      expect(ApiService.sanitizeCoverUrl('   '), equals(''));
      expect(
        ApiService.sanitizeCoverUrl('https://cdn.myanimelist.net/image.jpg'),
        equals('https://cdn.myanimelist.net/image.jpg'),
      );

      const kitsuUrl =
          'https://media.kitsu.app/anime/poster_images/1555/large.jpg';
      final sanitized = ApiService.sanitizeCoverUrl(kitsuUrl);
      expect(sanitized, startsWith('https://images.weserv.nl/?url='));
      expect(sanitized, contains(Uri.encodeComponent(kitsuUrl)));
    });

    test('mapKitsuAnimeToMediaItem applies sanitizeCoverUrl', () {
      final kitsuItem = ApiService.mapKitsuAnimeToMediaItem({
        'id': '1555',
        'attributes': {
          'canonicalTitle': 'Naruto',
          'posterImage': {
            'large':
                'https://media.kitsu.app/anime/poster_images/1555/large.jpg',
          },
          'episodeCount': 220,
          'status': 'finished',
        },
      });

      expect(kitsuItem.id, equals('kitsu_anime_1555'));
      expect(kitsuItem.title, equals('Naruto'));
      expect(kitsuItem.coverUrl, startsWith('https://images.weserv.nl/?url='));
      expect(kitsuItem.totalCount, equals(220));
      expect(kitsuItem.releaseStatus, ReleaseStatus.finished);
    });
  });

  group('ApiService Search Contracts & Error Handling', () {
    test('returns SearchSuccess with items on valid API response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('jikan')) {
          return http.Response(
            '{"data":[{"mal_id":1,"title":"Bleach","episodes":366}]}',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Bleach', category: 'Anime');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(1));
      expect(success.data.first.title, equals('Bleach'));
    });

    test('returns SearchSuccess with empty list when no matches found',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"data":[]}', 200);
      });

      final apiService = ApiService(client: mockClient);
      final result =
          await apiService.searchMedia('NonexistentQuery', category: 'Anime');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data, isEmpty);
    });

    test('returns SearchFailure(network) on SocketException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('No Internet');
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.network));
    });

    test('returns SearchFailure(timeout) on TimeoutException', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Request timed out');
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.timeout));
    });

    test('returns SearchFailure(rateLimited) on HTTP 429', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Rate limit', 429);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.rateLimited));
    });

    test('returns SearchFailure(server) on HTTP 503', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 503);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.server));
    });

    test('returns SearchFailure(invalidResponse) on malformed JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"data": "Not a list"}', 200);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchFailure<List<MediaItem>>>());
      final failure = result as SearchFailure<List<MediaItem>>;
      expect(failure.type, equals(SearchFailureType.invalidResponse));
    });

    test('falls back to Kitsu when Jikan fails and returns SearchSuccess',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('jikan')) {
          return http.Response('Rate limit', 429);
        }
        if (request.url.toString().contains('kitsu')) {
          return http.Response(
            '{"data":[{"id":"10","attributes":{"canonicalTitle":"Kitsu Anime","episodeCount":24}}]}',
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Test', category: 'Anime');

      expect(result, isA<SearchSuccess<List<MediaItem>>>());
      final success = result as SearchSuccess<List<MediaItem>>;
      expect(success.data.length, equals(1));
      expect(success.data.first.title, equals('Kitsu Anime'));
    });
  });
}
