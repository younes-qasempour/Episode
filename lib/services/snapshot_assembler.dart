import 'package:uuid/uuid.dart';
import '../models/media_item.dart';
import '../utils/clock.dart';

class SnapshotAssembler {
  static const _uuid = Uuid();
  final Clock clock;

  SnapshotAssembler({Clock? clock}) : clock = clock ?? const SystemClock();

  Map<String, dynamic> buildPushPayload({
    required String? snapshotId,
    required String deviceId,
    required int baseRevision,
    required List<MediaItem> allItems,
    required String platform,
    required String appVersion,
  }) {
    final effectiveSnapshotId = snapshotId ?? _uuid.v4();
    final nowUtc = clock.nowUtc();

    final serializedItems = allItems.map((item) => item.toMap()).toList();

    return {
      'snapshotId': effectiveSnapshotId,
      'deviceId': deviceId,
      'baseRevision': baseRevision,
      'protocolVersion': 1,
      'schemaVersion': 1,
      'clientTimestamp': nowUtc.toIso8601String(),
      'clientInfo': {
        'appVersion': appVersion,
        'platform': platform,
      },
      'payload': {
        'mediaItems': serializedItems,
      },
    };
  }

  List<MediaItem> parsePullPayload(Map<String, dynamic> pullResponsePayload) {
    List rawItems = [];
    if (pullResponsePayload['payload'] is Map &&
        pullResponsePayload['payload']['mediaItems'] is List) {
      rawItems = pullResponsePayload['payload']['mediaItems'] as List;
    } else if (pullResponsePayload['mediaItems'] is List) {
      rawItems = pullResponsePayload['mediaItems'] as List;
    }

    return rawItems
        .whereType<Map>()
        .map((itemMap) => MediaItem.fromMap(Map<String, dynamic>.from(itemMap)))
        .toList();
  }

  void validateSnapshotItems(List<MediaItem> items) {
    final itemIds = <String>{};
    for (final item in items) {
      if (item.id.trim().isEmpty) {
        throw const FormatException(
            'Snapshot contains media item with empty ID');
      }
      if (!itemIds.add(item.id)) {
        throw FormatException('Duplicate item ID in snapshot: ${item.id}');
      }
      final seasonIds = <String>{};
      final seasonNumbers = <int>{};
      for (final season in item.seasons) {
        if (season.id.trim().isNotEmpty && !seasonIds.add(season.id)) {
          throw FormatException(
              'Duplicate season ID in item ${item.id}: ${season.id}');
        }
        if (!seasonNumbers.add(season.seasonNumber)) {
          throw FormatException(
              'Duplicate season number in item ${item.id}: ${season.seasonNumber}');
        }
      }
    }
  }
}
