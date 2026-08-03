import 'dart:convert';

import 'media_item.dart';

const int currentLocalLibrarySchemaVersion = 2;

class LocalLibraryDocument {
  final int schemaVersion;
  final DateTime migratedAt;
  final List<MediaItem> mediaItems;

  const LocalLibraryDocument({
    required this.schemaVersion,
    required this.migratedAt,
    required this.mediaItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'migratedAt': migratedAt.toUtc().toIso8601String(),
      'mediaItems': mediaItems.map((item) => item.toMap()).toList(),
    };
  }

  factory LocalLibraryDocument.fromMap(Map<String, dynamic> map) {
    final version = (map['schemaVersion'] as num?)?.toInt() ?? 1;
    final migratedAtStr = map['migratedAt']?.toString();
    final migratedAt = migratedAtStr != null
        ? DateTime.tryParse(migratedAtStr)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    final rawItems = map['mediaItems'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((entry) => MediaItem.fromMap(Map<String, dynamic>.from(entry)))
            .toList()
        : <MediaItem>[];

    return LocalLibraryDocument(
      schemaVersion: version,
      migratedAt: migratedAt,
      mediaItems: items,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LocalLibraryDocument.fromJson(String source) {
    return LocalLibraryDocument.fromMap(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}
