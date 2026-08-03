import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class ApiService {
  static const String jikanBaseUrl = 'https://api.jikan.moe/v4';
  static const String tvmazeBaseUrl = 'https://api.tvmaze.com';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Search across Anime, Manga, and TV Series based on query and type filter.
  /// [category] can be 'All', 'Anime', 'Manga', or 'Series'.
  Future<List<MediaItem>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    final String cleanQuery = query.trim();
    final List<MediaItem> results = [];

    final String catLower = category.toLowerCase();
    final bool searchAnime = catLower == 'all' || catLower == 'anime';
    final bool searchManga = catLower == 'all' || catLower == 'manga';
    final bool searchSeries = catLower == 'all' || catLower == 'series';

    final List<Future<List<MediaItem>>> tasks = [];

    if (searchAnime) {
      tasks.add(_searchAnime(cleanQuery));
    }
    if (searchManga) {
      tasks.add(_searchManga(cleanQuery));
    }
    if (searchSeries) {
      tasks.add(_searchSeries(cleanQuery));
    }

    final responses = await Future.wait(tasks);
    for (var list in responses) {
      results.addAll(list);
    }

    return results;
  }

  /// Search Anime via Jikan API
  Future<List<MediaItem>> _searchAnime(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$jikanBaseUrl/top/anime?limit=10')
          : Uri.parse(
              '$jikanBaseUrl/anime?q=${Uri.encodeComponent(query)}&limit=12',
            );

      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((item) => mapJikanAnimeToMediaItem(item)).toList();
      }
    } catch (_) {
      // Gracefully return empty on endpoint error
    }
    return [];
  }

  /// Search Manga via Jikan API
  Future<List<MediaItem>> _searchManga(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$jikanBaseUrl/top/manga?limit=10')
          : Uri.parse(
              '$jikanBaseUrl/manga?q=${Uri.encodeComponent(query)}&limit=12',
            );

      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((item) => mapJikanMangaToMediaItem(item)).toList();
      }
    } catch (_) {
      // Gracefully return empty on endpoint error
    }
    return [];
  }

  /// Search TV Series via TVMaze API
  Future<List<MediaItem>> _searchSeries(String query) async {
    try {
      final String searchQuery = query.isEmpty ? 'drama' : query;
      final Uri uri = Uri.parse(
        '$tvmazeBaseUrl/search/shows?q=${Uri.encodeComponent(searchQuery)}',
      );

      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final List items = jsonDecode(response.body);
        return items
            .map((item) => mapTvMazeToShowItem(item['show']))
            .whereType<MediaItem>()
            .toList();
      }
    } catch (_) {
      // Gracefully return empty on endpoint error
    }
    return [];
  }

  static MediaItem mapJikanAnimeToMediaItem(Map<String, dynamic> json) {
    final int malId = json['mal_id'] ?? 0;
    final String title =
        json['title_english'] ?? json['title'] ?? 'Untitled Anime';
    final images = json['images']?['jpg'];
    final String coverUrl =
        images?['large_image_url'] ?? images?['image_url'] ?? '';
    final int? episodes = _validProviderTotal(json['episodes']);
    final String? synopsis = json['synopsis'];

    return MediaItem(
      id: 'jikan_anime_$malId',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: episodes,
      mediaType: 'anime',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(json['status']),
      synopsis: synopsis,
      externalIds: {'mal': '$malId', 'jikan': '$malId'},
    );
  }

  static MediaItem mapJikanMangaToMediaItem(Map<String, dynamic> json) {
    final int malId = json['mal_id'] ?? 0;
    final String title =
        json['title_english'] ?? json['title'] ?? 'Untitled Manga';
    final images = json['images']?['jpg'];
    final String coverUrl =
        images?['large_image_url'] ?? images?['image_url'] ?? '';
    final int? chapters = _validProviderTotal(json['chapters']);
    final String? synopsis = json['synopsis'];

    return MediaItem(
      id: 'jikan_manga_$malId',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: chapters,
      mediaType: 'manga',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(json['status']),
      synopsis: synopsis,
      externalIds: {'mal': '$malId', 'jikan': '$malId'},
    );
  }

  static MediaItem? mapTvMazeToShowItem(Map<String, dynamic>? show) {
    if (show == null) return null;
    final int id = show['id'] ?? 0;
    final String title = show['name'] ?? 'Untitled Series';
    final String coverUrl =
        show['image']?['original'] ?? show['image']?['medium'] ?? '';
    final String rawSummary = show['summary'] ?? '';
    final String synopsis = rawSummary.replaceAll(RegExp(r'<[^>]*>'), '');

    return MediaItem(
      id: 'tvmaze_series_$id',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: null,
      mediaType: 'series',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(show['status']),
      synopsis: synopsis,
      externalIds: {'tvmaze': '$id'},
    );
  }

  static int? _validProviderTotal(Object? value) {
    if (value is! num) {
      return null;
    }
    final total = value.toInt();
    return total > 0 ? total : null;
  }
}
