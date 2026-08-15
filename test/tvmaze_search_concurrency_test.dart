import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/services/api_service.dart';

void main() {
  group('BUG-007 & BUG-014: TVMaze Search Concurrency & Empty Query Tests', () {
    test('searchSeries makes exactly 1 HTTP request per search without eager season fanout', () async {
      int requestCount = 0;
      final List<Uri> requestedUris = [];

      final mockClient = MockClient((request) async {
        requestCount++;
        requestedUris.add(request.url);

        if (request.url.path == '/search/shows') {
          final sampleShows = List.generate(8, (i) => {
            'score': 10.0 - i,
            'show': {
              'id': 100 + i,
              'name': 'Show $i',
              'genres': ['Drama'],
              'status': 'Running',
              'rating': {'average': 8.0},
              'image': {
                'medium': 'https://example.com/$i.jpg',
                'original': 'https://example.com/$i.jpg',
              },
              'summary': '<p>Summary of show $i</p>',
            },
          });
          return http.Response(jsonEncode(sampleShows), 200);
        }

        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('Breaking', category: 'Series');

      expect(result, isA<SearchSuccess>());
      final items = (result as SearchSuccess).data;
      expect(items.length, 8);
      expect(items.first.title, 'Show 0');

      // Crucial assertion for BUG-007: Exactly 1 HTTP request was made! No fanout to /shows/{id}?embed=seasons.
      expect(requestCount, 1);
      expect(requestedUris.first.path, '/search/shows');
      expect(requestedUris.first.queryParameters['q'], 'Breaking');
    });

    test('BUG-014: Empty search query for Series queries /shows?page=0 without defaulting to "drama"', () async {
      final List<Uri> requestedUris = [];

      final mockClient = MockClient((request) async {
        requestedUris.add(request.url);

        if (request.url.path == '/shows') {
          final sampleShows = List.generate(5, (i) => {
            'id': 200 + i,
            'name': 'Top Show $i',
            'genres': ['Sci-Fi'],
            'status': 'Ended',
            'rating': {'average': 9.0},
            'image': {
              'medium': 'https://example.com/top$i.jpg',
              'original': 'https://example.com/top$i.jpg',
            },
            'summary': '<p>Top show summary</p>',
          });
          return http.Response(jsonEncode(sampleShows), 200);
        }

        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchMedia('', category: 'Series');

      expect(result, isA<SearchSuccess>());
      final items = (result as SearchSuccess).data;
      expect(items.length, 5);
      expect(items.first.title, 'Top Show 0');

      expect(requestedUris.length, 1);
      expect(requestedUris.first.path, '/shows');
      expect(requestedUris.first.queryParameters['page'], '0');
      expect(requestedUris.first.queryParameters.containsKey('q'), isFalse);
    });
  });
}
