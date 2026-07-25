import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../data/mock_data.dart';

class LocalStorageRepository {
  static const String _storageKey = 'otaku_log_media_items';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Load all media items from local storage.
  /// If storage is empty, initialize with [sampleMediaItems].
  Future<List<MediaItem>> loadMediaItems() async {
    try {
      final prefs = await _getPrefs();
      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List dynamicList = jsonDecode(jsonString);
        final items = dynamicList
            .map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (items.isNotEmpty) {
          return items;
        }
      }
    } catch (_) {
      // Fallback on decode error
    }

    // Initialize with default sample items
    final defaultItems = List<MediaItem>.from(sampleMediaItems);
    await saveAllMediaItems(defaultItems);
    return defaultItems;
  }

  /// Save all media items back to local storage.
  Future<void> saveAllMediaItems(List<MediaItem> items) async {
    final prefs = await _getPrefs();
    final String jsonString = jsonEncode(items.map((i) => i.toMap()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Add a new media item or place it at the top of the library.
  Future<List<MediaItem>> saveMediaItem(MediaItem newItem) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere(
      (item) =>
          item.id == newItem.id ||
          item.title.toLowerCase() == newItem.title.toLowerCase(),
    );

    if (index >= 0) {
      currentItems[index] = newItem;
    } else {
      currentItems.insert(0, newItem);
    }

    await saveAllMediaItems(currentItems);
    return currentItems;
  }

  /// Update an existing media item in local storage.
  Future<List<MediaItem>> updateMediaItem(MediaItem updatedItem) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere((item) => item.id == updatedItem.id);

    if (index >= 0) {
      currentItems[index] = updatedItem;
      await saveAllMediaItems(currentItems);
    }

    return currentItems;
  }

  /// Delete a media item by ID from local storage.
  Future<List<MediaItem>> deleteMediaItem(String id) async {
    final currentItems = await loadMediaItems();
    currentItems.removeWhere((item) => item.id == id);
    await saveAllMediaItems(currentItems);
    return currentItems;
  }

  /// Increment progress for an item by 1 without clamping to a stored total.
  ///
  /// Flat items increment their single progress value. Seasonal items require
  /// an explicit [seasonId], or use the highest-numbered ongoing season when
  /// one is available. Movies and seasonal items without a clear target are
  /// left unchanged. Tracking status is always controlled by the user.
  Future<List<MediaItem>> incrementProgress(
    String id, {
    String? seasonId,
  }) async {
    final currentItems = await loadMediaItems();
    final index = currentItems.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final item = currentItems[index];
      MediaItem updatedItem = item;

      if (item.progressMode == ProgressMode.flat) {
        updatedItem = item.incrementFlatProgress();
      } else {
        final targetId = seasonId ?? item.defaultIncrementSeason?.id;
        if (targetId != null) {
          updatedItem = item.incrementSeason(targetId);
        }
      }

      if (!identical(updatedItem, item)) {
        currentItems[index] = updatedItem;
        await saveAllMediaItems(currentItems);
      }
    }

    return currentItems;
  }
}
