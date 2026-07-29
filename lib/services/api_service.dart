import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class ApiService {
  static const String jikanBaseUrl = 'https://api.jikan.moe/v4';
  static const String tvmazeBaseUrl = 'https://api.tvmaze.com';
  static const String kitsuBaseUrl = 'https://kitsu.io/api/edge';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response?> _getWithRetry(Uri uri) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.get(uri);
        if (response.statusCode == 429 && attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        return response;
      } catch (_) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

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

    // Start TVMaze concurrently as it uses a separate provider domain
    final Future<List<MediaItem>> seriesTask =
        searchSeries ? _searchSeries(cleanQuery) : Future.value([]);

    if (searchAnime) {
      final animeResults = await _searchAnime(cleanQuery);
      results.addAll(animeResults);
    }

    if (searchManga) {
      if (searchAnime) {
        // Pacing delay between API calls
        await Future.delayed(const Duration(milliseconds: 200));
      }
      final mangaResults = await _searchManga(cleanQuery);
      results.addAll(mangaResults);
    }

    final seriesResults = await seriesTask;
    results.addAll(seriesResults);

    return results;
  }

  /// Search Anime via Jikan API with Kitsu fallback
  Future<List<MediaItem>> _searchAnime(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$jikanBaseUrl/top/anime?limit=10')
          : Uri.parse(
              '$jikanBaseUrl/anime?q=${Uri.encodeComponent(query)}&limit=12',
            );

      final response = await _getWithRetry(uri);
      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        if (items.isNotEmpty) {
          return items.map((item) => mapJikanAnimeToMediaItem(item)).toList();
        }
      }
    } catch (_) {
      // Gracefully fall back on endpoint error
    }
    return _searchKitsuAnime(query);
  }

  /// Search Manga via Jikan API with Kitsu fallback
  Future<List<MediaItem>> _searchManga(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$jikanBaseUrl/top/manga?limit=10')
          : Uri.parse(
              '$jikanBaseUrl/manga?q=${Uri.encodeComponent(query)}&limit=12',
            );

      final response = await _getWithRetry(uri);
      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        if (items.isNotEmpty) {
          return items.map((item) => mapJikanMangaToMediaItem(item)).toList();
        }
      }
    } catch (_) {
      // Gracefully fall back on endpoint error
    }
    return _searchKitsuManga(query);
  }

  /// Search Manga via Kitsu API
  Future<List<MediaItem>> _searchKitsuManga(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$kitsuBaseUrl/manga?page[limit]=12&sort=-userCount')
          : Uri.parse(
              '$kitsuBaseUrl/manga?filter[text]=${Uri.encodeComponent(query)}&page[limit]=12',
            );

      final response = await _getWithRetry(uri);
      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((item) => mapKitsuMangaToMediaItem(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Search Anime via Kitsu API
  Future<List<MediaItem>> _searchKitsuAnime(String query) async {
    try {
      final Uri uri = query.isEmpty
          ? Uri.parse('$kitsuBaseUrl/anime?page[limit]=12&sort=-userCount')
          : Uri.parse(
              '$kitsuBaseUrl/anime?filter[text]=${Uri.encodeComponent(query)}&page[limit]=12',
            );

      final response = await _getWithRetry(uri);
      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((item) => mapKitsuAnimeToMediaItem(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Search TV Series via TVMaze API with season enrichment
  Future<List<MediaItem>> _searchSeries(String query) async {
    try {
      final String searchQuery = query.isEmpty ? 'drama' : query;
      final Uri uri = Uri.parse(
        '$tvmazeBaseUrl/search/shows?q=${Uri.encodeComponent(searchQuery)}',
      );

      final response = await _getWithRetry(uri);
      if (response != null && response.statusCode == 200) {
        final List items = jsonDecode(response.body);
        final List<Future<MediaItem?>> tasks = [];

        for (var item in items.take(8)) {
          final show = item['show'] as Map<String, dynamic>?;
          if (show == null) continue;
          tasks.add(_enrichTvMazeShow(show));
        }

        final enriched = await Future.wait(tasks);
        return enriched.whereType<MediaItem>().toList();
      }
    } catch (_) {
      // Gracefully return empty on endpoint error
    }
    return [];
  }

  Future<MediaItem?> _enrichTvMazeShow(Map<String, dynamic> show) async {
    final int id = show['id'] ?? 0;
    List<MediaSeason> seasons = [];
    int? totalEpisodes;

    if (id > 0) {
      try {
        final Uri seasonUri = Uri.parse('$tvmazeBaseUrl/shows/$id?embed=seasons');
        final response = await _getWithRetry(seasonUri);
        if (response != null && response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List embeddedSeasons = data['_embedded']?['seasons'] ?? [];

          int episodeSum = 0;
          bool hasValidEpisodes = false;

          for (var s in embeddedSeasons) {
            if (s is! Map<String, dynamic>) continue;
            final int number = s['number'] ?? (seasons.length + 1);
            final int? epCount = _validProviderTotal(s['episodeOrder'] ?? s['episodes']);
            if (epCount != null) {
              episodeSum += epCount;
              hasValidEpisodes = true;
            }

            seasons.add(
              MediaSeason(
                id: 'tvmaze_season_${id}_$number',
                seasonNumber: number,
                title: 'Season $number',
                currentProgress: 0,
                totalCount: epCount,
                releaseStatus: releaseStatusFromStorage(
                  s['endDate'] != null ? 'Ended' : show['status'],
                ),
              ),
            );
          }

          if (hasValidEpisodes) {
            totalEpisodes = episodeSum;
          }
        }
      } catch (_) {
        // Fall back to basic show mapping on season fetch error
      }
    }

    return mapTvMazeToShowItem(show, seasons: seasons, totalEpisodes: totalEpisodes);
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
    );
  }

  static MediaItem? mapTvMazeToShowItem(
    Map<String, dynamic>? show, {
    List<MediaSeason> seasons = const [],
    int? totalEpisodes,
  }) {
    if (show == null) return null;
    final int id = show['id'] ?? 0;
    final String title = show['name'] ?? 'Untitled Series';
    final String coverUrl =
        show['image']?['original'] ?? show['image']?['medium'] ?? '';
    final String rawSummary = show['summary'] ?? '';
    final String synopsis = rawSummary.replaceAll(RegExp(r'<[^>]*>'), '');
    final bool hasSeasons = seasons.isNotEmpty;

    return MediaItem(
      id: 'tvmaze_series_$id',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: totalEpisodes,
      mediaType: 'series',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(show['status']),
      progressMode: hasSeasons ? ProgressMode.seasonal : ProgressMode.flat,
      seasons: seasons,
      synopsis: synopsis,
    );
  }

  static int? _validProviderTotal(Object? value) {
    if (value is! num) {
      return null;
    }
    final total = value.toInt();
    return total > 0 ? total : null;
  }

  static MediaItem mapKitsuMangaToMediaItem(Map<String, dynamic> item) {
    final String id = item['id']?.toString() ?? '0';
    final attr = item['attributes'] as Map<String, dynamic>? ?? {};
    final String title = attr['canonicalTitle'] ??
        attr['titles']?['en'] ??
        attr['titles']?['en_jp'] ??
        'Untitled Manga';
    final poster = attr['posterImage'];
    final String coverUrl =
        poster?['large'] ?? poster?['original'] ?? poster?['medium'] ?? '';
    final int? chapters = _validProviderTotal(attr['chapterCount']);
    final String? synopsis = attr['synopsis'];

    return MediaItem(
      id: 'kitsu_manga_$id',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: chapters,
      mediaType: 'manga',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(attr['status']),
      synopsis: synopsis,
    );
  }

  static MediaItem mapKitsuAnimeToMediaItem(Map<String, dynamic> item) {
    final String id = item['id']?.toString() ?? '0';
    final attr = item['attributes'] as Map<String, dynamic>? ?? {};
    final String title = attr['canonicalTitle'] ??
        attr['titles']?['en'] ??
        attr['titles']?['en_jp'] ??
        'Untitled Anime';
    final poster = attr['posterImage'];
    final String coverUrl =
        poster?['large'] ?? poster?['original'] ?? poster?['medium'] ?? '';
    final int? episodes = _validProviderTotal(attr['episodeCount']);
    final String? synopsis = attr['synopsis'];

    return MediaItem(
      id: 'kitsu_anime_$id',
      title: title,
      coverUrl: coverUrl,
      currentProgress: 0,
      totalCount: episodes,
      mediaType: 'anime',
      status: 'Plan to Watch',
      releaseStatus: releaseStatusFromStorage(attr['status']),
      synopsis: synopsis,
    );
  }
}
