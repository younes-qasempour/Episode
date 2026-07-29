import '../models/media_item.dart';
import '../services/api_service.dart';

class SearchRepository {
  final ApiService _apiService;

  SearchRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Perform media search across Anime, Manga, and TV Series based on query and category filter.
  /// Category can be 'All', 'Anime', 'Manga', or 'Series'.
  Future<List<MediaItem>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    return _apiService.searchMedia(query, category: category);
  }
}
